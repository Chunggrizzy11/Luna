import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { NotificationController } from './notification.controller';
import { NotificationService } from './notification.service';
import { PushNotificationService } from './push-notification.service';
import { NotificationGateway } from './notification.gateway';
import { Notification, NotificationSchema } from './schemas/notification.schema';
import { DeviceModule } from '../device/device.module';
import { Device, DeviceSchema } from '../device/schemas/device.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: Device.name, schema: DeviceSchema },
    ]),
    DeviceModule,
  ],
  controllers: [NotificationController],
  providers: [NotificationService, PushNotificationService, NotificationGateway],
  exports: [NotificationService, PushNotificationService, NotificationGateway],
})
export class NotificationModule {}
