import {
  CalendarDay,
  CalendarDayStatus,
  CycleCalculationError,
  CycleRecord,
  CycleSettings,
  CycleSummary,
  PeriodRange,
} from './cycle.types';

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const MONTH_PATTERN = /^(\d{4})-(\d{2})$/;
const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_RECENT_CYCLES = 6;

type DateOnly = Date;

export function calculateCycleSummary(
  cycles: readonly CycleRecord[],
  settings: CycleSettings,
  today: string,
): CycleSummary {
  validateSettings(settings);
  const normalizedToday = parseDateOnly(today);
  const normalizedCycles = cycles
    .map(normalizeCycle)
    .sort((left, right) => left.start.getTime() - right.start.getTime());
  const completeCycles = normalizedCycles.filter((cycle) => cycle.end !== null);
  const completeCycleLengths = recentPositiveValues(
    completeCycles,
    (cycle) => cycle.cycleLength,
  );
  const completePeriodLengths = recentPositiveValues(
    completeCycles,
    (cycle) => cycle.periodLength,
  );
  const averageCycleLength =
    completeCycleLengths.length >= 2
      ? roundedMean(completeCycleLengths)
      : settings.defaultCycleLength;
  const averagePeriodLength =
    completePeriodLengths.length > 0
      ? roundedMean(completePeriodLengths)
      : settings.defaultPeriodLength;
  const observedPeriods = normalizedCycles.map((cycle) => ({
    startDate: formatDateOnly(cycle.start),
    endDate: formatDateOnly(cycle.end ?? normalizedToday),
  }));

  const latestCycle = normalizedCycles.at(-1);
  if (!latestCycle) {
    return {
      currentCycleDay: null,
      isPeriodActive: false,
      daysUntilNextPeriod: null,
      averageCycleLength,
      averagePeriodLength,
      predictedPeriodStart: null,
      predictedPeriodEnd: null,
      ovulationDate: null,
      observedPeriods,
    };
  }

  const currentCycleDay = daysBetween(latestCycle.start, normalizedToday) + 1;
  const predictedStart = addDays(latestCycle.start, averageCycleLength);
  const predictedEnd = addDays(predictedStart, averagePeriodLength - 1);

  return {
    currentCycleDay,
    isPeriodActive:
      latestCycle.end === null &&
      currentCycleDay >= 1 &&
      currentCycleDay <= averagePeriodLength,
    daysUntilNextPeriod: daysBetween(normalizedToday, predictedStart),
    averageCycleLength,
    averagePeriodLength,
    predictedPeriodStart: formatDateOnly(predictedStart),
    predictedPeriodEnd: formatDateOnly(predictedEnd),
    ovulationDate: settings.ovulationEnabled
      ? formatDateOnly(addDays(predictedStart, -14))
      : null,
    observedPeriods,
  };
}

export function buildCalendarDays(
  summary: CycleSummary,
  month: string,
): CalendarDay[] {
  validateSummaryDates(summary);
  const monthStart = parseMonth(month);
  const nextMonth = new Date(
    Date.UTC(monthStart.getUTCFullYear(), monthStart.getUTCMonth() + 1, 1, 12),
  );
  const days: CalendarDay[] = [];

  for (let day = monthStart; day < nextMonth; day = addDays(day, 1)) {
    const date = formatDateOnly(day);
    const isObservedPeriod = summary.observedPeriods.some((period) =>
      isInRange(date, period),
    );
    const isPredictedPeriod =
      !isObservedPeriod &&
      summary.predictedPeriodStart !== null &&
      summary.predictedPeriodEnd !== null &&
      isInRange(date, {
        startDate: summary.predictedPeriodStart,
        endDate: summary.predictedPeriodEnd,
      });
    const isOvulation =
      !isObservedPeriod && !isPredictedPeriod && summary.ovulationDate === date;
    const status: CalendarDayStatus = isObservedPeriod
      ? 'observed-period'
      : isPredictedPeriod
        ? 'predicted-period'
        : isOvulation
          ? 'ovulation'
          : 'none';

    days.push({
      date,
      status,
      isObservedPeriod,
      isPredictedPeriod,
      isOvulation,
    });
  }

  return days;
}

interface NormalizedCycle {
  start: DateOnly;
  end: DateOnly | null;
  periodLength: number | null;
  cycleLength: number | null;
}

function normalizeCycle(cycle: CycleRecord): NormalizedCycle {
  const start = parseDateOnly(cycle.startDate);
  const end =
    cycle.endDate === null || cycle.endDate === undefined
      ? null
      : parseDateOnly(cycle.endDate);
  if (end !== null && end < start) {
    throw new CycleCalculationError(
      'INVALID_CYCLE_RANGE',
      'A cycle end date cannot be before its start date.',
    );
  }
  return {
    start,
    end,
    periodLength: positiveIntegerOrNull(cycle.periodLength),
    cycleLength: positiveIntegerOrNull(cycle.cycleLength),
  };
}

function recentPositiveValues<T>(
  records: readonly T[],
  getValue: (record: T) => number | null,
): number[] {
  return records
    .map(getValue)
    .filter((value): value is number => value !== null)
    .slice(-MAX_RECENT_CYCLES);
}

function roundedMean(values: readonly number[]): number {
  return Math.round(
    values.reduce((sum, value) => sum + value, 0) / values.length,
  );
}

function validateSettings(settings: CycleSettings): void {
  if (
    !isPositiveInteger(settings.defaultCycleLength) ||
    !isPositiveInteger(settings.defaultPeriodLength) ||
    typeof settings.ovulationEnabled !== 'boolean'
  ) {
    throw new CycleCalculationError(
      'INVALID_SETTINGS',
      'Cycle settings must contain positive integer defaults and an ovulation flag.',
    );
  }
}

function parseDateOnly(value: string): DateOnly {
  const match = DATE_PATTERN.exec(value);
  if (!match) {
    throw new CycleCalculationError('INVALID_DATE', `Invalid date: ${value}`);
  }
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const result = new Date(Date.UTC(year, month - 1, day, 12));
  if (
    result.getUTCFullYear() !== year ||
    result.getUTCMonth() !== month - 1 ||
    result.getUTCDate() !== day
  ) {
    throw new CycleCalculationError('INVALID_DATE', `Invalid date: ${value}`);
  }
  return result;
}

function parseMonth(value: string): DateOnly {
  const match = MONTH_PATTERN.exec(value);
  if (!match) {
    throw new CycleCalculationError('INVALID_MONTH', `Invalid month: ${value}`);
  }
  const year = Number(match[1]);
  const month = Number(match[2]);
  const result = new Date(Date.UTC(year, month - 1, 1, 12));
  if (result.getUTCFullYear() !== year || result.getUTCMonth() !== month - 1) {
    throw new CycleCalculationError('INVALID_MONTH', `Invalid month: ${value}`);
  }
  return result;
}

function addDays(date: DateOnly, days: number): DateOnly {
  return new Date(date.getTime() + days * DAY_MS);
}

function daysBetween(start: DateOnly, end: DateOnly): number {
  return Math.round((end.getTime() - start.getTime()) / DAY_MS);
}

function formatDateOnly(date: DateOnly): string {
  return date.toISOString().slice(0, 10);
}

function isInRange(date: string, range: PeriodRange): boolean {
  return date >= range.startDate && date <= range.endDate;
}

function validateSummaryDates(summary: CycleSummary): void {
  for (const period of summary.observedPeriods) {
    const start = parseDateOnly(period.startDate);
    const end = parseDateOnly(period.endDate);
    if (end < start) {
      throw new CycleCalculationError(
        'INVALID_CYCLE_RANGE',
        'A period end date cannot be before its start date.',
      );
    }
  }
  if (summary.predictedPeriodStart !== null) {
    parseDateOnly(summary.predictedPeriodStart);
  }
  if (summary.predictedPeriodEnd !== null) {
    parseDateOnly(summary.predictedPeriodEnd);
  }
  if (
    summary.predictedPeriodStart !== null &&
    summary.predictedPeriodEnd !== null &&
    summary.predictedPeriodEnd < summary.predictedPeriodStart
  ) {
    throw new CycleCalculationError(
      'INVALID_CYCLE_RANGE',
      'A predicted period end date cannot be before its start date.',
    );
  }
  if (summary.ovulationDate !== null) {
    parseDateOnly(summary.ovulationDate);
  }
}

function positiveIntegerOrNull(
  value: number | null | undefined,
): number | null {
  return isPositiveInteger(value) ? value : null;
}

function isPositiveInteger(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value > 0;
}
