import type { BusinessDateClock } from '../../common/date/business-date';
import { DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { CycleController } from './cycle.controller';
import type { CycleService } from './cycle.service';

const owner = {
  deviceId: 'owner-device',
  role: DeviceRole.OWNER,
  status: DeviceStatus.ACTIVE,
};

describe('CycleController', () => {
  it('uses the injected Bangkok business date for prediction defaults', async () => {
    const prediction = jest
      .fn()
      .mockResolvedValue({ predictedPeriodStart: null });
    const cycleService = {
      prediction,
    } as unknown as CycleService;
    const businessDate = {
      today: jest.fn().mockReturnValue('2026-08-04'),
    } as unknown as BusinessDateClock;
    const controller = new CycleController(cycleService, businessDate);

    await controller.prediction(owner, {});

    expect(prediction).toHaveBeenCalledWith(owner, '2026-08-04');
  });

  it('keeps an explicit prediction date independent of the clock', async () => {
    const prediction = jest
      .fn()
      .mockResolvedValue({ predictedPeriodStart: null });
    const cycleService = {
      prediction,
    } as unknown as CycleService;
    const today = jest.fn().mockReturnValue('2026-08-04');
    const businessDate = {
      today,
    } as unknown as BusinessDateClock;
    const controller = new CycleController(cycleService, businessDate);

    await controller.prediction(owner, { today: '2026-07-01' });

    expect(prediction).toHaveBeenCalledWith(owner, '2026-07-01');
    expect(today).not.toHaveBeenCalled();
  });
});
