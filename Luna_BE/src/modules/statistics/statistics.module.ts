import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { StatisticsController } from './statistics.controller';
import { StatisticsService } from './statistics.service';
import { Cycle, CycleSchema } from '../cycle/schemas/cycle.schema';
import { DailyLog, DailyLogSchema } from '../health/schemas/daily-log.schema';
import { Device, DeviceSchema } from '../device/schemas/device.schema';
import { DeviceModule } from '../device/device.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Cycle.name, schema: CycleSchema },
      { name: DailyLog.name, schema: DailyLogSchema },
      { name: Device.name, schema: DeviceSchema },
    ]),
    DeviceModule,
  ],
  controllers: [StatisticsController],
  providers: [StatisticsService],
  exports: [StatisticsService],
})
export class StatisticsModule {}
