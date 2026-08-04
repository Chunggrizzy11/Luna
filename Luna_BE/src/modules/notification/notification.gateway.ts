import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { DeviceService } from '../device/device.service';
import { DeviceRole } from '../device/schemas/device.schema';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/sync',
})
export class NotificationGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(NotificationGateway.name);
  private readonly connectedDevices = new Map<string, string>(); // deviceId -> socketId

  constructor(private readonly deviceService: DeviceService) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = client.handshake.auth?.token as string;
      if (!token) {
        client.disconnect();
        return;
      }

      const device = await this.deviceService.authenticate(token);
      this.connectedDevices.set(device.deviceId, client.id);
      client.data.deviceId = device.deviceId;
      client.data.role = device.role;

      this.logger.log(`Device ${device.deviceId} connected (${device.role})`);
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket): void {
    const deviceId = client.data.deviceId;
    if (deviceId) {
      this.connectedDevices.delete(deviceId);
      this.logger.log(`Device ${deviceId} disconnected`);
    }
  }

  @SubscribeMessage('join-pair')
  handleJoinPair(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { pairId: string },
  ): void {
    client.join(`pair:${data.pairId}`);
    this.logger.log(`Socket ${client.id} joined pair ${data.pairId}`);
  }

  @SubscribeMessage('leave-pair')
  handleLeavePair(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { pairId: string },
  ): void {
    client.leave(`pair:${data.pairId}`);
    this.logger.log(`Socket ${client.id} left pair ${data.pairId}`);
  }

  // Emit to all devices in a pair
  emitToPair(pairId: string, event: string, data: any): void {
    this.server.to(`pair:${pairId}`).emit(event, data);
  }

  // Emit to a specific device
  emitToDevice(deviceId: string, event: string, data: any): void {
    const socketId = this.connectedDevices.get(deviceId);
    if (socketId) {
      this.server.to(socketId).emit(event, data);
    }
  }

  // Notify all devices in a pair about a cycle update
  notifyCycleUpdate(pairId: string, cycleData: any): void {
    this.emitToPair(pairId, 'cycle-update', cycleData);
  }

  // Notify all devices in a pair about a daily log update
  notifyDailyLogUpdate(pairId: string, logData: any): void {
    this.emitToPair(pairId, 'daily-log-update', logData);
  }

  // Notify partner about a new notification
  notifyNewNotification(deviceId: string, notification: any): void {
    this.emitToDevice(deviceId, 'new-notification', notification);
  }

  // Broadcast offline sync data when device reconnects
  handleOfflineSync(client: Socket, data: { pendingSync: any[] }): void {
    const deviceId = client.data.deviceId;
    if (deviceId) {
      // Process pending sync data
      this.logger.log(
        `Processing ${data.pendingSync.length} pending sync items for device ${deviceId}`,
      );
    }
  }
}
