import { UnauthorizedException } from '@nestjs/common';
import { createHash } from 'crypto';
import { DeviceService } from './device.service';
import {
  DeviceRole,
  DeviceStatus,
  type DeviceDocument,
} from './schemas/device.schema';

describe('DeviceService', () => {
  const pepper = 'unit-test-pepper';
  const devices: DeviceDocument[] = [];
  const deviceModel = {
    create: jest.fn((device: DeviceDocument) => {
      const created = { _id: 'device-1', ...device } as DeviceDocument;
      devices.push(created);
      return Promise.resolve(created);
    }),
    findOne: jest.fn((query: { tokenHash: string; status: DeviceStatus }) => ({
      exec: () =>
        Promise.resolve(
          devices.find(
            (device) =>
              device.tokenHash === query.tokenHash &&
              device.status === query.status,
          ) ?? null,
        ),
    })),
    findByIdAndUpdate: jest.fn(
      (id: string, update: { status: DeviceStatus }) => ({
        exec: () => {
          const device = devices.find((candidate) => candidate._id === id);
          if (device) {
            device.status = update.status;
          }
          return Promise.resolve();
        },
      }),
    ),
  };
  const service = new DeviceService(deviceModel as never, pepper);

  beforeEach(() => {
    devices.length = 0;
    jest.clearAllMocks();
  });

  it('registers a device with a one-time 64-character hex token and hashes it at rest', async () => {
    const result = await service.register({
      role: DeviceRole.OWNER,
      platform: 'ios',
      deviceName: 'Test iPhone',
    });

    expect(result.deviceId).toBe('device-1');
    expect(result.token).toMatch(/^[a-f0-9]{64}$/);
    expect(devices).toHaveLength(1);
    expect(devices[0]).toMatchObject({
      role: DeviceRole.OWNER,
      status: DeviceStatus.ACTIVE,
      platform: 'ios',
      deviceName: 'Test iPhone',
    });
    expect(devices[0]).not.toHaveProperty('token');
    expect(devices[0].tokenHash).toBe(
      createHash('sha256').update(`${result.token}${pepper}`).digest('hex'),
    );
  });

  it('authenticates an active device from its token', async () => {
    const registration = await service.register({
      role: DeviceRole.OWNER,
      platform: 'android',
    });

    await expect(service.authenticate(registration.token)).resolves.toEqual({
      deviceId: 'device-1',
      role: DeviceRole.OWNER,
      status: DeviceStatus.ACTIVE,
    });
  });

  it('rejects a revoked device token', async () => {
    const registration = await service.register({
      role: DeviceRole.OWNER,
      platform: 'web',
    });
    await service.revoke(registration.deviceId);

    await expect(
      service.authenticate(registration.token),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('runs schema validators when updating a device', async () => {
    await service.update('device-1', { platform: 'android' });

    expect(deviceModel.findByIdAndUpdate).toHaveBeenCalledWith(
      'device-1',
      { platform: 'android' },
      { runValidators: true },
    );
  });

  it('persists and authenticates a partner registration with the partner role', async () => {
    const registration = await service.register({
      role: DeviceRole.PARTNER,
      platform: 'android',
    });

    expect(devices[0]).toMatchObject({ role: DeviceRole.PARTNER });
    await expect(service.authenticate(registration.token)).resolves.toEqual({
      deviceId: 'device-1',
      role: DeviceRole.PARTNER,
      status: DeviceStatus.ACTIVE,
    });
  });
});
