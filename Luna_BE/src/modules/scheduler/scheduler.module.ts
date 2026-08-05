import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from '@nestjs/schedule';
import { DeviceModule } from '../device/device.module';
import { CycleModule } from '../cycle/cycle.module';
import { NotificationModule } from '../notification/notification.module';
import { HealthModule } from '../health/health.module';
import { NotificationSchedulerService } from './notification-scheduler.service';
import { CareSuggestionService } from './care-suggestion.service';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    DeviceModule,
    CycleModule,
    NotificationModule,
    HealthModule,
  ],
  providers: [NotificationSchedulerService],
  exports: [],
})
export class SchedulerModule {}
