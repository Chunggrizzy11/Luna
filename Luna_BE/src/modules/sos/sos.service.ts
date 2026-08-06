import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device, DeviceDocument, DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { NotificationGateway } from '../notification/notification.gateway';
import { NotificationService } from '../notification/notification.service';
import { NotificationType } from '../notification/schemas/notification.schema';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';

@Injectable()
export class SosService {
  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<DeviceDocument>,
    private readonly notificationGateway: NotificationGateway,
    private readonly notificationService: NotificationService,
  ) {}

  async trigger(device: AuthenticatedDevice): Promise<void> {
    if (device.role !== DeviceRole.OWNER) {
      throw new ForbiddenException('Only the owner can trigger SOS.');
    }

    // Find partner device
    const partner = await this.deviceModel.findOne({
      pairedOwnerDeviceId: device.deviceId,
      role: DeviceRole.PARTNER,
      status: DeviceStatus.ACTIVE,
    });

    if (!partner) {
      throw new NotFoundException('Partner device not found.');
    }

    const partnerId = String(partner._id);

    // Save notification to DB
    await this.notificationService.create({
      recipientDeviceId: partnerId,
      type: NotificationType.SOS,
      title: '🆘 Tín hiệu khẩn cấp',
      body: 'Bạn gái đang cần bạn! Hãy liên hệ ngay.',
    });

    // Emit realtime socket event
    this.notificationGateway.emitToDevice(partnerId, 'sos-alert', {
      timestamp: new Date().toISOString(),
    });
  }

  async acknowledge(device: AuthenticatedDevice): Promise<void> {
    if (device.role !== DeviceRole.PARTNER) {
      throw new ForbiddenException('Only the partner can acknowledge SOS.');
    }

    // Find owner device
    const partner = await this.deviceModel.findById(device.deviceId);
    if (!partner || !partner.pairedOwnerDeviceId) {
      throw new NotFoundException('Not paired with an owner.');
    }

    // Emit acknowledgment to owner
    this.notificationGateway.emitToDevice(partner.pairedOwnerDeviceId, 'sos-acknowledged', {
      timestamp: new Date().toISOString(),
    });
  }
}
