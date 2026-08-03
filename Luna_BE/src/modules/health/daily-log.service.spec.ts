import { ForbiddenException } from '@nestjs/common';
import type { Model } from 'mongoose';
import { DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { DailyLogService } from './daily-log.service';
import { DailyLog, Mood, Symptom } from './schemas/daily-log.schema';

const owner = {
  deviceId: 'owner-device',
  role: DeviceRole.OWNER,
  status: DeviceStatus.ACTIVE,
};

function query<T>(value: T) {
  return {
    lean: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue(value),
  };
}

describe('DailyLogService', () => {
  let model: jest.Mocked<Pick<Model<DailyLog>, 'findOne' | 'findOneAndUpdate'>>;
  let service: DailyLogService;

  beforeEach(() => {
    model = { findOne: jest.fn(), findOneAndUpdate: jest.fn() };
    service = new DailyLogService(model as unknown as Model<DailyLog>);
  });

  it('updates only the supplied mood field so concurrent symptom and note values survive', async () => {
    const stored = {
      ownerDeviceId: owner.deviceId,
      date: '2026-08-03',
      mood: Mood.HAPPY,
      symptoms: [Symptom.CRAMPS],
      discomfortLevel: 4,
      note: 'Keep this note',
    };
    model.findOneAndUpdate.mockReturnValueOnce(query(stored) as never);

    await expect(
      service.upsertFields(owner, '2026-08-03', { mood: Mood.HAPPY }),
    ).resolves.toMatchObject(stored);
    expect(model.findOneAndUpdate).toHaveBeenCalledWith(
      { ownerDeviceId: owner.deviceId, date: '2026-08-03' },
      {
        $set: { mood: Mood.HAPPY },
        $setOnInsert: { ownerDeviceId: owner.deviceId, date: '2026-08-03' },
      },
      expect.objectContaining({
        returnDocument: 'after',
        runValidators: true,
        upsert: true,
      }),
    );
  });

  it('unsets only note without replacing mood or symptoms', async () => {
    const stored = {
      ownerDeviceId: owner.deviceId,
      date: '2026-08-03',
      mood: Mood.SAD,
      symptoms: [Symptom.HEADACHE],
      discomfortLevel: 2,
    };
    model.findOneAndUpdate.mockReturnValueOnce(query(stored) as never);

    await expect(
      service.unsetFields(owner, '2026-08-03', ['note']),
    ).resolves.toMatchObject(stored);
    expect(model.findOneAndUpdate).toHaveBeenCalledWith(
      { ownerDeviceId: owner.deviceId, date: '2026-08-03' },
      { $unset: { note: 1 } },
      expect.objectContaining({ returnDocument: 'after', runValidators: true }),
    );
  });

  it('retries a first-write duplicate race as a field-only update', async () => {
    const stored = {
      ownerDeviceId: owner.deviceId,
      date: '2026-08-03',
      mood: Mood.HAPPY,
      note: 'Written by the concurrent request',
    };
    model.findOneAndUpdate.mockReturnValueOnce({
      lean: jest.fn().mockReturnThis(),
      exec: jest.fn().mockRejectedValue({ code: 11000 }),
    } as never);
    model.findOneAndUpdate.mockReturnValueOnce(query(stored) as never);

    await expect(
      service.upsertFields(owner, '2026-08-03', { mood: Mood.HAPPY }),
    ).resolves.toMatchObject(stored);
    expect(model.findOneAndUpdate).toHaveBeenLastCalledWith(
      { ownerDeviceId: owner.deviceId, date: '2026-08-03' },
      { $set: { mood: Mood.HAPPY } },
      { returnDocument: 'after', runValidators: true },
    );
  });

  it('returns null when an owner has no log for the requested date', async () => {
    model.findOne.mockReturnValueOnce(query(null) as never);

    await expect(service.findByDate(owner, '2026-08-03')).resolves.toBeNull();
    expect(model.findOne).toHaveBeenCalledWith({
      ownerDeviceId: owner.deviceId,
      date: '2026-08-03',
    });
  });

  it('denies partner access before reading or writing a log', async () => {
    await expect(
      service.findByDate({ ...owner, role: DeviceRole.PARTNER }, '2026-08-03'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(model.findOne).not.toHaveBeenCalled();
  });
});
