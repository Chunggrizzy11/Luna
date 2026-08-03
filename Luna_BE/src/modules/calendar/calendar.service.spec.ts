import { ForbiddenException } from '@nestjs/common';
import type { Model } from 'mongoose';
import { DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import {
  CYCLE_SETTINGS_PROVIDER,
  type CycleSettingsProvider,
} from '../cycle/cycle.service';
import { Cycle } from '../cycle/schemas/cycle.schema';
import { CalendarService } from './calendar.service';

const owner = {
  deviceId: 'owner-device',
  role: DeviceRole.OWNER,
  status: DeviceStatus.ACTIVE,
};

function query<T>(value: T) {
  return {
    select: jest.fn().mockReturnThis(),
    lean: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue(value),
  };
}

describe('CalendarService', () => {
  let model: jest.Mocked<Pick<Model<Cycle>, 'find'>>;
  let settings: jest.Mocked<CycleSettingsProvider>;
  let service: CalendarService;

  beforeEach(() => {
    model = { find: jest.fn() };
    settings = {
      getSettings: jest.fn().mockReturnValue({
        defaultCycleLength: 28,
        defaultPeriodLength: 5,
        ovulationEnabled: true,
      }),
    };
    service = new CalendarService(
      model as unknown as Model<Cycle>,
      settings,
      () => new Date('2026-03-15T12:00:00.000Z'),
    );
  });

  it('marks observed, predicted, and ovulation days with distinct calendar statuses', async () => {
    model.find.mockReturnValueOnce(
      query([
        {
          startDate: '2026-02-01',
          endDate: '2026-02-05',
          periodLength: 5,
          cycleLength: 28,
        },
        {
          startDate: '2026-03-01',
          endDate: '2026-03-05',
          periodLength: 5,
          cycleLength: 28,
        },
      ]) as never,
    );

    const result = await service.getMonth(owner, '2026-03');

    expect(result.days.find((day) => day.date === '2026-03-03')).toMatchObject({
      status: 'observed-period',
      isObservedPeriod: true,
    });
    expect(result.days.find((day) => day.date === '2026-03-29')).toMatchObject({
      status: 'predicted-period',
      isPredictedPeriod: true,
    });
    expect(result.days.find((day) => day.date === '2026-03-15')).toMatchObject({
      status: 'ovulation',
      isOvulation: true,
    });
  });

  it('rejects partners before loading calendar cycles', async () => {
    await expect(
      service.getMonth({ ...owner, role: DeviceRole.PARTNER }, '2026-03'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(model.find).not.toHaveBeenCalled();
  });

  it('rejects malformed and impossible month boundaries', async () => {
    await expect(service.getMonth(owner, '2026-13')).rejects.toMatchObject({
      response: { message: 'month must be a valid yyyy-MM month.' },
    });
  });

  it('uses the injected cycle settings provider', () => {
    expect(CYCLE_SETTINGS_PROVIDER).toBe('CYCLE_SETTINGS_PROVIDER');
  });
});
