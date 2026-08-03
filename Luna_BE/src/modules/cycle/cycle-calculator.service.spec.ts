import {
  buildCalendarDays,
  calculateCycleSummary,
} from './cycle-calculator.service';
import { CycleCalculationError, CycleSettings } from './cycle.types';

const settings: CycleSettings = {
  defaultCycleLength: 28,
  defaultPeriodLength: 5,
  ovulationEnabled: true,
};

describe('cycle calculator', () => {
  describe('calculateCycleSummary', () => {
    it.each([
      {
        name: 'returns null cycle-specific values with no history',
        cycles: [],
        today: '2026-03-12',
        expected: {
          currentCycleDay: null,
          predictedPeriodStart: null,
          predictedPeriodEnd: null,
          daysUntilNextPeriod: null,
          ovulationDate: null,
          averageCycleLength: 28,
          averagePeriodLength: 5,
        },
      },
      {
        name: 'uses defaults and counts the start date as cycle day one for an active cycle',
        cycles: [{ startDate: '2026-03-01' }],
        today: '2026-03-12',
        expected: {
          currentCycleDay: 12,
          predictedPeriodStart: '2026-03-29',
          predictedPeriodEnd: '2026-04-02',
          daysUntilNextPeriod: 17,
          ovulationDate: '2026-03-15',
          averageCycleLength: 28,
          averagePeriodLength: 5,
        },
      },
      {
        name: 'averages only the six most recent valid complete cycle lengths',
        cycles: [
          {
            startDate: '2025-01-01',
            endDate: '2025-01-05',
            periodLength: 5,
            cycleLength: 1,
          },
          {
            startDate: '2025-02-01',
            endDate: '2025-02-05',
            periodLength: 5,
            cycleLength: 2,
          },
          {
            startDate: '2025-03-01',
            endDate: '2025-03-06',
            periodLength: 6,
            cycleLength: 3,
          },
          {
            startDate: '2025-04-01',
            endDate: '2025-04-06',
            periodLength: 6,
            cycleLength: 4,
          },
          {
            startDate: '2025-05-01',
            endDate: '2025-05-07',
            periodLength: 7,
            cycleLength: 5,
          },
          {
            startDate: '2025-06-01',
            endDate: '2025-06-07',
            periodLength: 7,
            cycleLength: 6,
          },
          {
            startDate: '2025-07-01',
            endDate: '2025-07-08',
            periodLength: 8,
            cycleLength: 100,
          },
          {
            startDate: '2025-08-01',
            endDate: '2025-08-09',
            periodLength: 9,
            cycleLength: 0,
          },
          { startDate: '2026-01-15' },
        ],
        today: '2026-01-20',
        expected: {
          currentCycleDay: 6,
          predictedPeriodStart: '2026-02-04',
          predictedPeriodEnd: '2026-02-10',
          daysUntilNextPeriod: 15,
          ovulationDate: '2026-01-21',
          averageCycleLength: 20,
          averagePeriodLength: 7,
        },
      },
      {
        name: 'handles leap day with UTC date-only arithmetic',
        cycles: [{ startDate: '2024-02-28' }],
        today: '2024-02-29',
        expected: {
          currentCycleDay: 2,
          predictedPeriodStart: '2024-03-27',
          predictedPeriodEnd: '2024-03-31',
          daysUntilNextPeriod: 27,
          ovulationDate: '2024-03-13',
          averageCycleLength: 28,
          averagePeriodLength: 5,
        },
      },
    ])('$name', ({ cycles, today, expected }) => {
      expect(calculateCycleSummary(cycles, settings, today)).toMatchObject(
        expected,
      );
    });

    it('does not expose ovulation when the setting is disabled', () => {
      const summary = calculateCycleSummary(
        [{ startDate: '2026-03-01' }],
        { ...settings, ovulationEnabled: false },
        '2026-03-12',
      );

      expect(summary.ovulationDate).toBeNull();
    });

    it('keeps an unended latest cycle active after its estimated period length', () => {
      const summary = calculateCycleSummary(
        [{ startDate: '2026-03-01' }],
        settings,
        '2026-03-12',
      );

      expect(summary).toMatchObject({
        currentCycleDay: 12,
        isPeriodActive: true,
        observedPeriods: [{ startDate: '2026-03-01', endDate: '2026-03-12' }],
      });
    });

    it('treats future-only records as no started history and returns a calendar-safe summary', () => {
      const summary = calculateCycleSummary(
        [{ startDate: '2026-04-01' }],
        settings,
        '2026-03-12',
      );

      expect(summary).toMatchObject({
        currentCycleDay: null,
        predictedPeriodStart: null,
        observedPeriods: [],
      });
      expect(() => buildCalendarDays(summary, '2026-03')).not.toThrow();
    });

    it('uses the latest already-started record when later records are in the future', () => {
      const summary = calculateCycleSummary(
        [{ startDate: '2026-03-01' }, { startDate: '2026-04-01' }],
        settings,
        '2026-03-12',
      );

      expect(summary).toMatchObject({
        currentCycleDay: 12,
        predictedPeriodStart: '2026-03-29',
        observedPeriods: [{ startDate: '2026-03-01', endDate: '2026-03-12' }],
      });
    });

    it.each([
      ['2026-2-03', '2026-03-03'],
      ['2026-02-30', '2026-03-03'],
    ])('rejects a malformed date input: %s', (startDate, today) => {
      expect(() =>
        calculateCycleSummary([{ startDate }], settings, today),
      ).toThrow(CycleCalculationError);
    });

    it('rejects invalid settings deterministically', () => {
      expect(() =>
        calculateCycleSummary(
          [],
          { ...settings, defaultCycleLength: 0 },
          '2026-03-03',
        ),
      ).toThrow(CycleCalculationError);
    });

    it.each([
      [{ ...settings, defaultCycleLength: Number.MAX_SAFE_INTEGER }],
      [{ ...settings, defaultPeriodLength: 29 }],
    ])(
      'rejects unsafe or inconsistent settings with a domain error',
      (invalidSettings) => {
        expect(() =>
          calculateCycleSummary([], invalidSettings, '2026-03-03'),
        ).toThrow(CycleCalculationError);
      },
    );

    it('ignores unsafe persisted average candidates instead of leaking native date errors', () => {
      const summary = calculateCycleSummary(
        [
          {
            startDate: '2026-01-01',
            endDate: '2026-01-05',
            periodLength: Number.MAX_SAFE_INTEGER,
            cycleLength: Number.MAX_SAFE_INTEGER,
          },
          { startDate: '2026-03-01' },
        ],
        settings,
        '2026-03-03',
      );

      expect(summary).toMatchObject({
        averageCycleLength: 28,
        averagePeriodLength: 5,
        predictedPeriodStart: '2026-03-29',
      });
    });

    it('throws a typed error instead of a native date error when a prediction exceeds the date range', () => {
      expect(() =>
        calculateCycleSummary(
          [{ startDate: '9999-12-31' }],
          { ...settings, defaultCycleLength: 1, defaultPeriodLength: 1 },
          '9999-12-31',
        ),
      ).toThrow(CycleCalculationError);
    });
  });

  describe('buildCalendarDays', () => {
    const summary = calculateCycleSummary(
      [
        {
          startDate: '2026-01-29',
          endDate: '2026-02-03',
          periodLength: 6,
          cycleLength: 28,
        },
        { startDate: '2026-02-26' },
      ],
      { ...settings, defaultPeriodLength: 4 },
      '2026-02-27',
    );

    it('clips cross-month observed periods and marks the requested month only', () => {
      const days = buildCalendarDays(summary, '2026-02');

      expect(days).toHaveLength(28);
      expect(days.find((day) => day.date === '2026-02-01')).toMatchObject({
        status: 'observed-period',
        isObservedPeriod: true,
      });
      expect(days.find((day) => day.date === '2026-02-04')).toMatchObject({
        status: 'none',
      });
    });

    it('gives observed periods precedence over ovulation', () => {
      const overlappingSummary = calculateCycleSummary(
        [{ startDate: '2026-03-01' }],
        { ...settings, defaultCycleLength: 14, defaultPeriodLength: 2 },
        '2026-03-02',
      );
      const days = buildCalendarDays(overlappingSummary, '2026-03');

      expect(days.find((day) => day.date === '2026-03-01')).toMatchObject({
        status: 'observed-period',
        isOvulation: false,
      });
    });

    it('gives predicted periods precedence over ovulation', () => {
      const overlappingSummary = {
        ...summary,
        observedPeriods: [],
        predictedPeriodStart: '2026-03-15',
        predictedPeriodEnd: '2026-03-16',
        ovulationDate: '2026-03-15',
      };
      const days = buildCalendarDays(overlappingSummary, '2026-03');

      expect(days.find((day) => day.date === '2026-03-15')).toMatchObject({
        status: 'predicted-period',
        isPredictedPeriod: true,
        isOvulation: false,
      });
    });

    it('clips a predicted period to the requested month', () => {
      const crossMonthSummary = {
        ...summary,
        observedPeriods: [],
        predictedPeriodStart: '2026-02-27',
        predictedPeriodEnd: '2026-03-03',
        ovulationDate: null,
      };
      const days = buildCalendarDays(crossMonthSummary, '2026-03');

      expect(days).toHaveLength(31);
      expect(days.find((day) => day.date === '2026-03-01')).toMatchObject({
        status: 'predicted-period',
      });
      expect(days.find((day) => day.date === '2026-03-04')).toMatchObject({
        status: 'none',
      });
    });

    it('does not let an observed period lose precedence to prediction', () => {
      const overlappingSummary = {
        ...summary,
        observedPeriods: [{ startDate: '2026-03-15', endDate: '2026-03-15' }],
        predictedPeriodStart: '2026-03-15',
        predictedPeriodEnd: '2026-03-16',
        ovulationDate: null,
      };
      const days = buildCalendarDays(overlappingSummary, '2026-03');

      expect(days.find((day) => day.date === '2026-03-15')).toMatchObject({
        status: 'observed-period',
        isPredictedPeriod: false,
      });
    });

    it('rejects a non-strict month', () => {
      expect(() => buildCalendarDays(summary, '2026-2')).toThrow(
        CycleCalculationError,
      );
    });
  });
});
