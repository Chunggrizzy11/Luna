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
    // TEMPORARY FOR TESTING: Bỏ check role
    // if (device.role !== DeviceRole.OWNER) {
    //   throw new ForbiddenException('Only the owner can trigger SOS.');
    // }

    // TEMPORARY FOR TESTING: Tìm bất kỳ thiết bị nào khác làm Partner
    const partner = await this.deviceModel.findOne({
      _id: { $ne: device.deviceId },
    });

    if (!partner) {
      throw new NotFoundException('Không tìm thấy thiết bị nào khác trong DB để test.');
    }

    const partnerId = String(partner._id);

    // Save notification to DB
    await this.notificationService.create({
      recipientDeviceId: partnerId,
      type: NotificationType.SOS,
      title: '🆘 Tín hiệu khẩn cấp',
      body: 'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    });

    // Send push notification
    await this.pushNotificationService.sendToDevice(
      partnerId,
      '🆘 Tín hiệu khẩn cấp',
      'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    );

    // Emit realtime socket event
    this.notificationGateway.emitToDevice(partnerId, 'sos-alert', {
      timestamp: new Date().toISOString(),
    });
  }

  async acknowledge(device: AuthenticatedDevice): Promise<void> {
    // TEMPORARY FOR TESTING: Bỏ check role
    // if (device.role !== DeviceRole.PARTNER) {
    //   throw new ForbiddenException('Only the partner can acknowledge SOS.');
    // }

    // TEMPORARY FOR TESTING: Tìm bất kỳ thiết bị nào khác làm Owner
    const owner = await this.deviceModel.findOne({
      _id: { $ne: device.deviceId },
    });

    if (!owner) {
      throw new NotFoundException('Không tìm thấy Owner.');
    }

    // Emit acknowledgment to owner
    this.notificationGateway.emitToDevice(String(owner._id), 'sos-acknowledged', {
      timestamp: new Date().toISOString(),
    });
  }
}
