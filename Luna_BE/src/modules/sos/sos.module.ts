import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SosController } from './sos.controller';
import { SosService } from './sos.service';
import { Device, DeviceSchema } from '../device/schemas/device.schema';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Device.name, schema: DeviceSchema }]),
    NotificationModule,
  ],
  controllers: [SosController],
  providers: [SosService],
})
export class SosModule {}
