import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
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
  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<DeviceDocument>,
    private readonly notificationGateway: NotificationGateway,
    private readonly notificationService: NotificationService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  async trigger(device: AuthenticatedDevice): Promise<void> {
    let recipientId: string | null = null;

    if (device.role === DeviceRole.OWNER) {
      const partner = await this.deviceModel.findOne({
        pairedOwnerDeviceId: device.deviceId,
        role: DeviceRole.PARTNER,
      });
      recipientId = partner ? String(partner._id) : null;
    } else {
      const partnerDoc = await this.deviceModel.findById(device.deviceId);
      recipientId = partnerDoc?.pairedOwnerDeviceId || null;
    }

    if (!recipientId) {
      throw new NotFoundException('Không tìm thấy thiết bị đã ghép đôi.');
    }

    // Save notification to DB
    await this.notificationService.create({
      recipientDeviceId: recipientId,
      type: NotificationType.SOS,
      title: '🆘 Tín hiệu khẩn cấp',
      body: 'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    });

    // Send push notification
    await this.pushNotificationService.sendToDevice(
      recipientId,
      '🆘 Tín hiệu khẩn cấp',
      'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    );

    // Emit realtime socket event
    this.notificationGateway.emitToDevice(recipientId, 'sos-alert', {
      timestamp: new Date().toISOString(),
    });
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
