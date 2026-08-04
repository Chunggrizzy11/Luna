import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UatSeedService } from './uat-seed.service';
import { Device, DeviceSchema } from '../modules/device/schemas/device.schema';
import { PairingCode, PairingCodeSchema } from '../modules/pairing/schemas/pairing-code.schema';
import { Cycle, CycleSchema } from '../modules/cycle/schemas/cycle.schema';
import { DailyLog, DailyLogSchema } from '../modules/health/schemas/daily-log.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Device.name, schema: DeviceSchema },
      { name: PairingCode.name, schema: PairingCodeSchema },
      { name: Cycle.name, schema: CycleSchema },
      { name: DailyLog.name, schema: DailyLogSchema },
    ]),
  ],
  providers: [UatSeedService],
  exports: [UatSeedService],
})
export class UatSeedModule {}