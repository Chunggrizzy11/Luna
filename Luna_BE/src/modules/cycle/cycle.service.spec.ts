import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import type { Model } from 'mongoose';
import { DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import {
  CYCLE_SETTINGS_PROVIDER,
  CycleService,
  type CycleSettingsProvider,
} from './cycle.service';
import { Cycle } from './schemas/cycle.schema';

const owner = {
  deviceId: 'owner-device',
  role: DeviceRole.OWNER,
  status: DeviceStatus.ACTIVE,
};
const partner = { ...owner, role: DeviceRole.PARTNER };

function query<T>(value: T) {
  const chain = {
    sort: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    lean: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue(value),
  };
  return chain;
}

describe('CycleService', () => {
  let model: jest.Mocked<
    Pick<Model<Cycle>, 'create' | 'find' | 'findOne' | 'findOneAndUpdate'>
  >;
  let settings: jest.Mocked<CycleSettingsProvider>;
  let service: CycleService;

  beforeEach(() => {
    model = {
      create: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      findOneAndUpdate: jest.fn(),
    };
    settings = {
      getSettings: jest.fn().mockReturnValue({
        defaultCycleLength: 28,
        defaultPeriodLength: 5,
        ovulationEnabled: false,
      }),
    };
    service = new CycleService(model as unknown as Model<Cycle>, settings);
  });

  it('starts a manual active cycle with an explicit null end date', async () => {
    model.findOne.mockReturnValueOnce(query(null) as never);
    model.findOne.mockReturnValueOnce(query(null) as never);
    model.create.mockResolvedValue({
      _id: 'cycle-1',
      ownerDeviceId: owner.deviceId,
      startDate: '2026-03-01',
      endDate: null,
      source: 'manual',
    } as never);

    await expect(service.start(owner, '2026-03-01')).resolves.toMatchObject({
      startDate: '2026-03-01',
      endDate: null,
      source: 'manual',
    });
    expect(model.create).toHaveBeenCalledWith({
      ownerDeviceId: owner.deviceId,
      startDate: '2026-03-01',
      endDate: null,
      source: 'manual',
    });
  });

  it('rejects a second active cycle for the same owner', async () => {
    model.findOne.mockReturnValueOnce(
      query({ ownerDeviceId: owner.deviceId, endDate: null }) as never,
    );

    await expect(service.start(owner, '2026-03-01')).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('translates an active-cycle duplicate key race to a conflict', async () => {
    model.findOne.mockReturnValueOnce(query(null) as never);
    model.findOne.mockReturnValueOnce(query(null) as never);
    model.create.mockRejectedValue({ code: 11000 });

    await expect(service.start(owner, '2026-03-01')).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('derives the immediately preceding ended cycle length from start dates', async () => {
    const previous = { _id: 'previous', startDate: '2026-02-01' };
    model.findOne.mockReturnValueOnce(query(null) as never);
    model.findOne.mockReturnValueOnce(query(previous) as never);
    model.findOneAndUpdate.mockReturnValueOnce(query(previous) as never);
    model.create.mockResolvedValue({
      _id: 'new',
      ownerDeviceId: owner.deviceId,
      startDate: '2026-03-01',
      endDate: null,
      source: 'manual',
    } as never);

    await service.start(owner, '2026-03-01');

    expect(model.findOneAndUpdate).toHaveBeenCalledWith(
      { _id: 'previous', ownerDeviceId: owner.deviceId },
      { cycleLength: 28 },
    );
  });

  it('ends an active cycle and calculates same-day periods as one day', async () => {
    const active = { _id: 'cycle-1', startDate: '2026-03-01' };
    model.findOne.mockReturnValueOnce(query(active) as never);
    model.findOneAndUpdate.mockReturnValueOnce(
      query({ ...active, endDate: '2026-03-01', periodLength: 1 }) as never,
    );

    await expect(service.end(owner, '2026-03-01')).resolves.toMatchObject({
      endDate: '2026-03-01',
      periodLength: 1,
    });
  });

  it('rejects ending a cycle before its start date', async () => {
    model.findOne.mockReturnValueOnce(
      query({ _id: 'cycle-1', startDate: '2026-03-02' }) as never,
    );

    await expect(service.end(owner, '2026-03-01')).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('rejects ending when the owner has no active cycle', async () => {
    model.findOne.mockReturnValueOnce(query(null) as never);

    await expect(service.end(owner, '2026-03-01')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('scopes current and history queries to the authenticated owner', async () => {
    model.findOne.mockReturnValueOnce(query(null) as never);
    model.find.mockReturnValueOnce(query([]) as never);

    await expect(service.findCurrent(owner)).resolves.toBeNull();
    await service.list(owner, {});

    expect(model.findOne).toHaveBeenCalledWith({
      ownerDeviceId: owner.deviceId,
      endDate: null,
    });
    expect(model.find).toHaveBeenCalledWith({ ownerDeviceId: owner.deviceId });
  });

  it('rejects partner calls across cycle reads, mutations, and prediction', async () => {
    await expect(service.start(partner, '2026-03-01')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(service.end(partner, '2026-03-01')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(service.findCurrent(partner)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(service.list(partner, {})).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await expect(
      service.prediction(partner, '2026-03-01'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('applies inclusive date ranges in stable newest-first order', async () => {
    model.find.mockReturnValueOnce(query([]) as never);

    await service.list(owner, { from: '2026-02-01', to: '2026-03-01' });

    expect(model.find).toHaveBeenCalledWith({
      ownerDeviceId: owner.deviceId,
      startDate: { $gte: '2026-02-01', $lte: '2026-03-01' },
    });
  });

  it('rejects an inverted date range', async () => {
    await expect(
      service.list(owner, { from: '2026-03-01', to: '2026-02-01' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('predicts from lean owner records using the injected default settings provider', async () => {
    model.find.mockReturnValueOnce(
      query([{ startDate: '2026-03-01', endDate: null }]) as never,
    );

    await expect(
      service.prediction(owner, '2026-03-12'),
    ).resolves.toMatchObject({
      predictedPeriodStart: '2026-03-29',
      ovulationDate: null,
    });
    expect(settings.getSettings.mock.calls).toEqual([[owner.deviceId]]);
  });

  it('exports a replaceable settings provider token', () => {
    expect(CYCLE_SETTINGS_PROVIDER).toBe('CYCLE_SETTINGS_PROVIDER');
  });
});
