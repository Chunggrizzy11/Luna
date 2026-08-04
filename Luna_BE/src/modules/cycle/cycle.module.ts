import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BusinessDateModule } from '../../common/date/business-date.module';
import { CycleController } from './cycle.controller';
import {
  CYCLE_SETTINGS_PROVIDER,
  CycleService,
  type CycleSettingsProvider,
} from './cycle.service';
import { Cycle, CycleSchema } from './schemas/cycle.schema';

const defaultCycleSettingsProvider: CycleSettingsProvider = {
  getSettings: () => ({
    defaultCycleLength: 28,
    defaultPeriodLength: 5,
    ovulationEnabled: false,
  }),
};

@Module({
  imports: [
    BusinessDateModule,
    MongooseModule.forFeature([{ name: Cycle.name, schema: CycleSchema }]),
  ],
  controllers: [CycleController],
  providers: [
    CycleService,
    {
      provide: CYCLE_SETTINGS_PROVIDER,
      useValue: defaultCycleSettingsProvider,
    },
  ],
  exports: [CycleService, CYCLE_SETTINGS_PROVIDER],
})
export class CycleModule {}
