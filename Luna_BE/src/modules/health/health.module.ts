import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BusinessDateModule } from '../../common/date/business-date.module';
import { CycleModule } from '../cycle/cycle.module';
import { Cycle, CycleSchema } from '../cycle/schemas/cycle.schema';
import { Device, DeviceSchema } from '../device/schemas/device.schema';
import { CareSuggestionService } from '../scheduler/care-suggestion.service';
import { HealthController } from './health.controller';
import { DashboardService } from './dashboard.service';
import { DailyLogService } from './daily-log.service';
import { JournalService } from './journal.service';
import { DailyLog, DailyLogSchema } from './schemas/daily-log.schema';

@Module({
  imports: [
    BusinessDateModule,
    CycleModule,
    MongooseModule.forFeature([
      { name: DailyLog.name, schema: DailyLogSchema },
      { name: Cycle.name, schema: CycleSchema },
      { name: Device.name, schema: DeviceSchema },
    ]),
  ],
  controllers: [HealthController],
  providers: [
    DailyLogService,
    DashboardService,
    JournalService,
    CareSuggestionService,
  ],
  exports: [DailyLogService],
})
export class HealthModule {}
