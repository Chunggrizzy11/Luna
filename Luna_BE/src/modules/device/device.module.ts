import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DeviceController } from './device.controller';
import { DEVICE_TOKEN_PEPPER, DeviceService } from './device.service';
import { Device, DeviceSchema } from './schemas/device.schema';
import { DeviceAuthGuard } from '../../common/guards/device-auth.guard';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Device.name, schema: DeviceSchema }]),
  ],
  controllers: [DeviceController],
  providers: [
    DeviceService,
    DeviceAuthGuard,
    {
      provide: DEVICE_TOKEN_PEPPER,
      inject: [ConfigService],
      useFactory: (configService: ConfigService) =>
        configService.getOrThrow<string>('DEVICE_TOKEN_PEPPER'),
    },
  ],
  exports: [DeviceService, DeviceAuthGuard, MongooseModule],
})
export class DeviceModule {}
