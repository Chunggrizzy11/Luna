import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CycleModule } from '../cycle/cycle.module';
import { Cycle, CycleSchema } from '../cycle/schemas/cycle.schema';
import { CalendarController } from './calendar.controller';
import { CALENDAR_NOW, CalendarService } from './calendar.service';

@Module({
  imports: [
    CycleModule,
    MongooseModule.forFeature([{ name: Cycle.name, schema: CycleSchema }]),
  ],
  controllers: [CalendarController],
  providers: [
    CalendarService,
    { provide: CALENDAR_NOW, useValue: () => new Date() },
  ],
})
export class CalendarModule {}
