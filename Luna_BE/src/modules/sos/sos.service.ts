import { Injectable, ForbiddenException, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device, DeviceDocument, DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { NotificationGateway } from '../notification/notification.gateway';
import { NotificationService } from '../notification/notification.service';
import { PushNotificationService } from '../notification/push-notification.service';
import { NotificationType } from '../notification/schemas/notification.schema';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';

@Injectable()
export class SosService {
  private readonly logger = new Logger(SosService.name);

  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<DeviceDocument>,
    private readonly notificationGateway: NotificationGateway,
    private readonly notificationService: NotificationService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  async trigger(device: AuthenticatedDevice): Promise<void> {
    this.logger.log(`=== SOS TRIGGER START === device=${device.deviceId}, role=${device.role}`);
    
    let recipientId: string | null = null;

    if (device.role === DeviceRole.OWNER) {
      const partner = await this.deviceModel.findOne({
        pairedOwnerDeviceId: device.deviceId,
        role: DeviceRole.PARTNER,
      });
      this.logger.log(`Owner trigger: found partner=${partner ? String(partner._id) : 'NONE'}, fcmToken=${partner?.fcmToken ? 'YES' : 'NO'}`);
      recipientId = partner ? String(partner._id) : null;
    } else {
      const partnerDoc = await this.deviceModel.findById(device.deviceId).lean();
      this.logger.log(`Partner trigger: pairedOwnerDeviceId=${(partnerDoc as any)?.pairedOwnerDeviceId ?? 'NONE'}`);
      recipientId = (partnerDoc as any)?.pairedOwnerDeviceId || null;
    }

    if (!recipientId) {
      this.logger.warn(`SOS TRIGGER FAILED: No paired device found for ${device.deviceId}`);
      // List all devices for debugging
      const allDevices = await this.deviceModel.find({}).select('_id role pairedOwnerDeviceId fcmToken').lean();
      this.logger.warn(`All devices in DB: ${JSON.stringify(allDevices.map(d => ({ id: String(d._id), role: d.role, paired: (d as any).pairedOwnerDeviceId, hasFcm: !!d.fcmToken })))}`);
      throw new NotFoundException('Không tìm thấy thiết bị đã ghép đôi.');
    }

    this.logger.log(`SOS: Sending to recipientId=${recipientId}`);

    // Save notification to DB
    const notif = await this.notificationService.create({
      recipientDeviceId: recipientId,
      type: NotificationType.SOS,
      title: '🆘 Tín hiệu khẩn cấp',
      body: 'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    });
    this.logger.log(`SOS: Notification saved to DB, id=${notif.id}`);

    // Send push notification
    await this.pushNotificationService.sendToDevice(
      recipientId,
      '🆘 Tín hiệu khẩn cấp',
      'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    );
    this.logger.log(`SOS: Push notification sent`);

    // Emit realtime socket event
    this.notificationGateway.emitToDevice(recipientId, 'sos-alert', {
      timestamp: new Date().toISOString(),
    });
    this.logger.log(`SOS: Socket event emitted. === SOS TRIGGER END ===`);
  }

  async acknowledge(device: AuthenticatedDevice): Promise<void> {
    let recipientId: string | null = null;

    if (device.role === DeviceRole.PARTNER) {
      const partnerDoc = await this.deviceModel.findById(device.deviceId);
      recipientId = partnerDoc?.pairedOwnerDeviceId || null;
    } else {
      const partner = await this.deviceModel.findOne({
        pairedOwnerDeviceId: device.deviceId,
        role: DeviceRole.PARTNER,
      });
      recipientId = partner ? String(partner._id) : null;
    }

    if (!recipientId) {
      throw new NotFoundException('Không tìm thấy thiết bị đã ghép đôi.');
    }

    // Emit acknowledgment to recipient
    this.notificationGateway.emitToDevice(recipientId, 'sos-acknowledged', {
      timestamp: new Date().toISOString(),
    });
  }
}
