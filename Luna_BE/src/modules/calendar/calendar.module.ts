import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BusinessDateModule } from '../../common/date/business-date.module';
import { DeviceModule } from '../device/device.module';
import { CycleModule } from '../cycle/cycle.module';
import { Cycle, CycleSchema } from '../cycle/schemas/cycle.schema';
import { CalendarController } from './calendar.controller';
import { CalendarService } from './calendar.service';

@Module({
  imports: [
    BusinessDateModule,
    CycleModule,
    DeviceModule,
    MongooseModule.forFeature([{ name: Cycle.name, schema: CycleSchema }]),
  ],
  controllers: [CalendarController],
  providers: [CalendarService],
})
export class CalendarModule {}
