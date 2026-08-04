import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import {
  Notification,
  NotificationDocument,
  NotificationType,
} from './schemas/notification.schema';

const DEFAULT_PAGE_LIMIT = 20;

export interface CreateNotificationInput {
  recipientDeviceId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface NotificationListResponse {
  items: NotificationResponse[];
  page: number;
  limit: number;
  unreadCount: number;
}

export interface NotificationResponse {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
  read: boolean;
  createdAt: string;
}

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<NotificationDocument>,
  ) {}

  async create(input: CreateNotificationInput): Promise<NotificationResponse> {
    const notification = await this.notificationModel.create({
      recipientDeviceId: input.recipientDeviceId,
      type: input.type,
      title: input.title,
      body: input.body,
      data: input.data,
    });
    return this.toResponse(notification);
  }

  async list(
    device: AuthenticatedDevice,
    page = 1,
    limit = DEFAULT_PAGE_LIMIT,
  ): Promise<NotificationListResponse> {
    const [items, unreadCount] = await Promise.all([
      this.notificationModel
        .find({ recipientDeviceId: device.deviceId })
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean()
        .exec(),
      this.notificationModel.countDocuments({
        recipientDeviceId: device.deviceId,
        read: false,
      }),
    ]);

    return {
      items: items.map((n) => this.toResponse(n)),
      page,
      limit,
      unreadCount,
    };
  }

  async markAsRead(
    device: AuthenticatedDevice,
    notificationId: string,
  ): Promise<void> {
    await this.notificationModel.findOneAndUpdate(
      { _id: notificationId, recipientDeviceId: device.deviceId },
      { read: true },
    );
  }

  async markAllAsRead(device: AuthenticatedDevice): Promise<void> {
    await this.notificationModel.updateMany(
      { recipientDeviceId: device.deviceId, read: false },
      { read: true },
    );
  }

  async getUnreadCount(device: AuthenticatedDevice): Promise<number> {
    return this.notificationModel.countDocuments({
      recipientDeviceId: device.deviceId,
      read: false,
    });
  }

  private toResponse(n: Notification | any): NotificationResponse {
    return {
      id: String(n._id),
      type: n.type,
      title: n.title,
      body: n.body,
      data: n.data,
      read: n.read,
      createdAt: (n.createdAt ?? new Date()).toISOString(),
    };
  }
}
