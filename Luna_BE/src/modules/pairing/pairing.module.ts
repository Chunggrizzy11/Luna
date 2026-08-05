import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PairingController } from './pairing.controller';
import { PairingService } from './pairing.service';
import { PairingCode, PairingCodeSchema } from './schemas/pairing-code.schema';
import { Device, DeviceSchema } from '../device/schemas/device.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PairingCode.name, schema: PairingCodeSchema },
      { name: Device.name, schema: DeviceSchema },
    ]),
  ],
  controllers: [PairingController],
  providers: [PairingService],
  exports: [PairingService],
})
export class PairingModule {}