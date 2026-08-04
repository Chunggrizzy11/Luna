import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device } from '../device/schemas/device.schema';

export const FIREBASE_ADMIN = 'FIREBASE_ADMIN';

export interface PushMessage {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class PushNotificationService {
  private readonly logger = new Logger(PushNotificationService.name);
  private readonly isConfigured: boolean;

  constructor(
    @InjectModel(Device.name)
    private readonly deviceModel: Model<Device>,
    private readonly configService: ConfigService,
  ) {
    this.isConfigured = this.configService.get<boolean>(
      'notification.isFcmConfigured',
      false,
    );
  }

  async sendToDevice(
    deviceId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.isConfigured) {
      this.logger.warn('FCM not configured, skipping push notification.');
      return;
    }

    const device = await this.deviceModel
      .findById(deviceId)
      .select('fcmToken')
      .lean()
      .exec();

    if (!device?.fcmToken) {
      this.logger.warn(`No FCM token for device ${deviceId}`);
      return;
    }

    await this.send({
      token: device.fcmToken,
      title,
      body,
      data,
    });
  }

  async sendToMultipleDevices(
    deviceIds: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.isConfigured) {
      this.logger.warn('FCM not configured, skipping push notification.');
      return;
    }

    const devices = await this.deviceModel
      .find({ _id: { $in: deviceIds } })
      .select('fcmToken')
      .lean()
      .exec();

    const tokens = devices
      .filter((d) => d.fcmToken)
      .map((d) => d.fcmToken as string);

    if (tokens.length === 0) return;

    // Firebase Admin SDK would be used here
    // For now, log the intended push
    this.logger.log(
      `Push notification would be sent to ${tokens.length} devices: ${title}`,
    );
  }

  async send(message: PushMessage): Promise<void> {
    if (!this.isConfigured) {
      this.logger.warn('FCM not configured, skipping push notification.');
      return;
    }

    // Firebase Admin SDK integration point
    // Example with firebase-admin:
    // await getMessaging().send({
    //   token: message.token,
    //   notification: { title: message.title, body: message.body },
    //   data: message.data,
    // });

    this.logger.log(
      `Push notification sent to ${message.token.substring(0, 8)}...: ${message.title}`,
    );
  }
}
