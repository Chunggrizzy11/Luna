import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DailyLogService } from './daily-log.service';
import { DailyLog, DailyLogSchema } from './schemas/daily-log.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: DailyLog.name, schema: DailyLogSchema },
    ]),
  ],
  providers: [DailyLogService],
  exports: [DailyLogService],
})
export class HealthModule {}
