import { Module } from '@nestjs/common';
import {
  BangkokBusinessDate,
  BUSINESS_INSTANT_CLOCK,
  BusinessDateClock,
} from './business-date';

@Module({
  providers: [
    { provide: BUSINESS_INSTANT_CLOCK, useValue: () => new Date() },
    { provide: BusinessDateClock, useClass: BangkokBusinessDate },
  ],
  exports: [BusinessDateClock],
})
export class BusinessDateModule {}
