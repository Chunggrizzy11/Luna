import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device } from '../device/schemas/device.schema';
import { initializeApp, cert, type App } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';
import * as fs from 'fs';
import * as path from 'path';

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
  private isConfigured = false;
  private messaging: Messaging | null = null;

  constructor(
    @InjectModel(Device.name)
    private readonly deviceModel: Model<Device>,
    private readonly configService: ConfigService,
  ) {
    this.initFirebaseAdmin();
  }

  private initFirebaseAdmin() {
    try {
      // Check multiple possible locations for the secret file
      const possiblePaths = [
        path.resolve(process.cwd(), 'firebase-service-account.json'),
        '/etc/secrets/firebase-service-account.json', // Render Secret Files default path
        path.resolve(__dirname, '../../../../firebase-service-account.json'),
      ];

      let serviceAccountPath = null;
      for (const p of possiblePaths) {
        if (fs.existsSync(p)) {
          serviceAccountPath = p;
          break;
        }
      }

      if (serviceAccountPath) {
        const app: App = initializeApp({
          credential: cert(serviceAccountPath),
        });
        this.messaging = getMessaging(app);
        this.isConfigured = true;
        this.logger.log(`Firebase Admin initialized successfully from ${serviceAccountPath}`);
      } else {
        this.logger.warn(
          'firebase-service-account.json not found. Push notifications will be mocked.',
        );
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin', error);
    }
  }

  async sendToDevice(
    deviceId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
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
    const devices = await this.deviceModel
      .find({ _id: { $in: deviceIds } })
      .select('fcmToken')
      .lean()
      .exec();

    const tokens = devices
      .filter((d) => d.fcmToken)
      .map((d) => d.fcmToken as string);

    if (tokens.length === 0) return;

    if (!this.isConfigured || !this.messaging) {
      this.logger.log(
        `[MOCK] Push notification would be sent to ${tokens.length} devices: ${title}`,
      );
      return;
    }

    try {
      const message = {
        notification: { title, body },
        data,
        tokens,
      };
      const response = await this.messaging.sendEachForMulticast(message);
      this.logger.log(
        `Multicast push sent. Success: ${response.successCount}, Failure: ${response.failureCount}`,
      );
    } catch (error) {
      this.logger.error('Failed to send multicast push notification', error);
    }
  }

  async send(message: PushMessage): Promise<void> {
    if (!this.isConfigured || !this.messaging) {
      this.logger.log(
        `[MOCK] Push notification sent to ${message.token.substring(0, 8)}...: ${message.title}`,
      );
      return;
    }

    try {
      await this.messaging.send({
        token: message.token,
        notification: { title: message.title, body: message.body },
        data: message.data,
      });
      this.logger.log(
        `Push notification sent to ${message.token.substring(0, 8)}...: ${message.title}`,
      );
    } catch (error) {
      this.logger.error('Failed to send push notification', error);
    }
  }
}

