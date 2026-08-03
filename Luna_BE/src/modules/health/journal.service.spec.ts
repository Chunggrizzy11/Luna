import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import type { Model } from 'mongoose';
import { DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { JournalService } from './journal.service';
import { DailyLog } from './schemas/daily-log.schema';

const owner = {
  deviceId: 'owner-device',
  role: DeviceRole.OWNER,
  status: DeviceStatus.ACTIVE,
};

function query<T>(value: T) {
  return {
    select: jest.fn().mockReturnThis(),
    sort: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    lean: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue(value),
  };
}

describe('JournalService', () => {
  let model: jest.Mocked<Pick<Model<DailyLog>, 'find'>>;
  let service: JournalService;

  beforeEach(() => {
    model = { find: jest.fn() };
    service = new JournalService(model as unknown as Model<DailyLog>);
  });

  it('returns an owner-only newest-first page with the requested inclusive dates', async () => {
    model.find.mockReturnValueOnce(
      query([
        { date: '2026-03-03', mood: 'happy', note: 'newest' },
        { date: '2026-03-02', discomfortLevel: 2 },
      ]) as never,
    );

    await expect(
      service.list(owner, {
        from: '2026-03-01',
        to: '2026-03-03',
        page: 2,
        limit: 2,
      }),
    ).resolves.toEqual({
      items: [
        { date: '2026-03-03', mood: 'happy', note: 'newest' },
        { date: '2026-03-02', discomfortLevel: 2 },
      ],
      page: 2,
      limit: 2,
    });
    expect(model.find).toHaveBeenCalledWith({
      ownerDeviceId: owner.deviceId,
      date: { $gte: '2026-03-01', $lte: '2026-03-03' },
    });
  });

  it('rejects partner journal access before querying', async () => {
    await expect(
      service.list({ ...owner, role: DeviceRole.PARTNER }, {}),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(model.find).not.toHaveBeenCalled();
  });

  it('rejects inverted dates and invalid pagination limits', async () => {
    await expect(
      service.list(owner, { from: '2026-03-03', to: '2026-03-01' }),
    ).rejects.toBeInstanceOf(ConflictException);
    await expect(service.list(owner, { page: 0 })).rejects.toBeInstanceOf(
      BadRequestException,
    );
    await expect(service.list(owner, { limit: 101 })).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
