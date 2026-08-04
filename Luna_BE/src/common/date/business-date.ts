import { Inject, Injectable } from '@nestjs/common';

export type InstantClock = () => Date;

export const BUSINESS_INSTANT_CLOCK = 'BUSINESS_INSTANT_CLOCK';

export abstract class BusinessDateClock {
  abstract today(): string;
  abstract formatInstant(instant: Date): string;
}

const BANGKOK_OFFSET_MS = 7 * 60 * 60 * 1000;

@Injectable()
export class BangkokBusinessDate extends BusinessDateClock {
  constructor(
    @Inject(BUSINESS_INSTANT_CLOCK)
    private readonly instantClock: InstantClock,
  ) {
    super();
  }

  today(): string {
    return this.formatInstant(this.instantClock());
  }

  formatInstant(instant: Date): string {
    if (!Number.isFinite(instant.getTime())) {
      throw new RangeError('Business date requires a valid instant.');
    }
    return new Date(instant.getTime() + BANGKOK_OFFSET_MS)
      .toISOString()
      .slice(0, 10);
  }
}
