export interface CycleRecord {
  startDate: string;
  endDate?: string | null;
  periodLength?: number | null;
  cycleLength?: number | null;
}

export interface CycleSettings {
  defaultCycleLength: number;
  defaultPeriodLength: number;
  ovulationEnabled: boolean;
}

export interface PeriodRange {
  startDate: string;
  endDate: string;
}

export interface CycleSummary {
  currentCycleDay: number | null;
  isPeriodActive: boolean;
  daysUntilNextPeriod: number | null;
  averageCycleLength: number;
  averagePeriodLength: number;
  predictedPeriodStart: string | null;
  predictedPeriodEnd: string | null;
  ovulationDate: string | null;
  observedPeriods: PeriodRange[];
}

export type CalendarDayStatus =
  'none' | 'observed-period' | 'predicted-period' | 'ovulation';

export interface CalendarDay {
  date: string;
  status: CalendarDayStatus;
  isObservedPeriod: boolean;
  isPredictedPeriod: boolean;
  isOvulation: boolean;
}

export type CycleCalculationErrorCode =
  'INVALID_DATE' | 'INVALID_MONTH' | 'INVALID_SETTINGS' | 'INVALID_CYCLE_RANGE';

export class CycleCalculationError extends Error {
  constructor(
    public readonly code: CycleCalculationErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'CycleCalculationError';
  }
}
