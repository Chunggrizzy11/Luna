import type { Model } from 'mongoose';
import {
  DeviceRole,
  DeviceStatus,
  type Device,
} from '../device/schemas/device.schema';
import { type CycleSettingsProvider } from '../cycle/cycle.service';
import { Cycle } from '../cycle/schemas/cycle.schema';
import { DailyLog } from './schemas/daily-log.schema';
import { DashboardService } from './dashboard.service';

const owner = {
  deviceId: 'owner-device',
  role: DeviceRole.OWNER,
  status: DeviceStatus.ACTIVE,
  pairId: 'pair-1',
};

function query<T>(value: T) {
  return {
    select: jest.fn().mockReturnThis(),
    lean: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue(value),
  };
}

describe('DashboardService', () => {
  let cycles: jest.Mocked<Pick<Model<Cycle>, 'find'>>;
  let logs: jest.Mocked<Pick<Model<DailyLog>, 'findOne'>>;
  let devices: jest.Mocked<Pick<Model<Device>, 'findOne'>>;
  let settings: jest.Mocked<CycleSettingsProvider>;
  let service: DashboardService;

  beforeEach(() => {
    cycles = { find: jest.fn() };
    logs = { findOne: jest.fn() };
    devices = { findOne: jest.fn() };
    settings = {
      getSettings: jest.fn().mockReturnValue({
        defaultCycleLength: 28,
        defaultPeriodLength: 5,
        ovulationEnabled: true,
      }),
    };
    service = new DashboardService(
      cycles as unknown as Model<Cycle>,
      logs as unknown as Model<DailyLog>,
      devices as unknown as Model<Device>,
      settings,
    );
  });

  it('returns the active owner cycle and full owner daily log', async () => {
    cycles.find.mockReturnValueOnce(
      query([{ startDate: '2026-03-01', endDate: null }]) as never,
    );
    logs.findOne.mockReturnValueOnce(
      query({
        date: '2026-03-12',
        mood: 'anxious',
        symptoms: ['cramps'],
        discomfortLevel: 4,
        note: 'Private journal note',
      }) as never,
    );

    await expect(service.getDashboard(owner, '2026-03-12')).resolves.toEqual({
      date: '2026-03-12',
      relationship: 'owner',
      cycle: {
        currentCycleDay: 12,
        isPeriodActive: true,
        daysUntilNextPeriod: 17,
        averageCycleLength: 28,
        averagePeriodLength: 5,
        predictedPeriodStart: '2026-03-29',
        predictedPeriodEnd: '2026-04-02',
        ovulationDate: '2026-03-15',
        observedPeriods: [{ startDate: '2026-03-01', endDate: '2026-03-12' }],
      },
      dailyLog: {
        mood: 'anxious',
        symptoms: ['cramps'],
        discomfortLevel: 4,
        note: 'Private journal note',
      },
    });
  });

  it('returns nullable dashboard values when the owner has no cycle or log', async () => {
    cycles.find.mockReturnValueOnce(query([]) as never);
    logs.findOne.mockReturnValueOnce(query(null) as never);

    await expect(service.getDashboard(owner, '2026-03-12')).resolves.toEqual({
      date: '2026-03-12',
      relationship: 'owner',
      cycle: {
        currentCycleDay: null,
        isPeriodActive: false,
        daysUntilNextPeriod: null,
        averageCycleLength: 28,
        averagePeriodLength: 5,
        predictedPeriodStart: null,
        predictedPeriodEnd: null,
        ovulationDate: null,
        observedPeriods: [],
      },
      dailyLog: {
        mood: null,
        symptoms: [],
        discomfortLevel: null,
        note: null,
      },
    });
  });

  it('finds a paired owner by exact pair id and filters partner private log fields', async () => {
    devices.findOne.mockReturnValueOnce(
      query({
        _id: 'paired-owner',
        role: DeviceRole.OWNER,
        pairId: 'pair-1',
      }) as never,
    );
    cycles.find.mockReturnValueOnce(
      query([{ startDate: '2026-03-01', endDate: null }]) as never,
    );
    logs.findOne.mockReturnValueOnce(
      query({
        mood: 'sad',
        symptoms: ['cramps'],
        discomfortLevel: 5,
        note: 'Never expose this',
      }) as never,
    );

    const result = await service.getDashboard(
      { ...owner, deviceId: 'partner-device', role: DeviceRole.PARTNER },
      '2026-03-12',
    );

    expect(result).toEqual({
      date: '2026-03-12',
      relationship: 'paired',
      cycle: {
        currentCycleDay: 12,
        isPeriodActive: true,
        daysUntilNextPeriod: 17,
        predictedPeriodStart: '2026-03-29',
        predictedPeriodEnd: '2026-04-02',
      },
      discomfortLevel: 5,
    });
    expect(devices.findOne).toHaveBeenCalledWith({
      pairId: 'pair-1',
      role: DeviceRole.OWNER,
      status: DeviceStatus.ACTIVE,
    });
  });

  it('does not infer an owner for an unpaired partner', async () => {
    await expect(
      service.getDashboard(
        {
          ...owner,
          deviceId: 'partner-device',
          role: DeviceRole.PARTNER,
          pairId: undefined,
        },
        '2026-03-12',
      ),
    ).resolves.toEqual({
      date: '2026-03-12',
      relationship: 'unpaired',
      cycle: null,
      discomfortLevel: null,
    });
    expect(devices.findOne).not.toHaveBeenCalled();
    expect(cycles.find).not.toHaveBeenCalled();
    expect(logs.findOne).not.toHaveBeenCalled();
  });
});
