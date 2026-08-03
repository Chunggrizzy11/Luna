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
import { CycleModule } from './modules/cycle/cycle.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig, notificationConfig],
      validate: validateEnvironment,
    }),
    DatabaseModule,
    DeviceModule,
    CycleModule,
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
