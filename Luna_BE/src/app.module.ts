import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import appConfig from './config/app.config';
import databaseConfig from './config/database.config';
import { validateEnvironment } from './config/env.validation';
import notificationConfig from './config/notification.config';
import { DatabaseModule } from './database/database.module';
import { DeviceAuthGuard } from './common/guards/device-auth.guard';
import { DeviceModule } from './modules/device/device.module';
import { PairingModule } from './modules/pairing/pairing.module';
import { NotificationModule } from './modules/notification/notification.module';
import { SchedulerModule } from './modules/scheduler/scheduler.module';
import { StatisticsModule } from './modules/statistics/statistics.module';
import { SettingsModule } from './modules/settings/settings.module';
import { UatSeedModule } from './seed/uat-seed.module';
import { CycleModule } from './modules/cycle/cycle.module';
import { CalendarModule } from './modules/calendar/calendar.module';
import { HealthModule } from './modules/health/health.module';
import { MoodModule } from './modules/mood/mood.module';
import { NoteModule } from './modules/note/note.module';
import { SymptomModule } from './modules/symptom/symptom.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig, notificationConfig],
      validate: validateEnvironment,
    }),
    DatabaseModule,
    DeviceModule,
    PairingModule,
    NotificationModule,
    SchedulerModule,
    StatisticsModule,
    SettingsModule,
    UatSeedModule,
    CycleModule,
    CalendarModule,
    HealthModule,
    MoodModule,
    SymptomModule,
    NoteModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useExisting: DeviceAuthGuard,
    },
  ],
})
export class AppModule {}
