import { INestApplication, Module, ValidationPipe } from '@nestjs/common';
import { getModelToken } from '@nestjs/mongoose';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types';
import { DeviceAuthGuard } from '../../common/guards/device-auth.guard';
import { DeviceController } from './device.controller';
import { DEVICE_TOKEN_PEPPER, DeviceService } from './device.service';
import { Device, DeviceStatus } from './schemas/device.schema';

const pepper = 'e2e-test-pepper';
const devices: Array<Record<string, unknown>> = [];
const deviceModel = {
  create: jest.fn((data: Record<string, unknown>) => {
    const id = `device-${devices.length + 1}`;
    const device = { _id: id, id, ...data };
    devices.push(device);
    return Promise.resolve(device);
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
  findByIdAndUpdate: jest.fn((id: string, update: Record<string, unknown>) => ({
    exec: () => {
      const device = devices.find((candidate) => candidate._id === id);
      if (device) {
        Object.assign(device, update);
      }
      return Promise.resolve();
    },
  })),
};

@Module({
  controllers: [DeviceController],
  providers: [
    DeviceService,
    DeviceAuthGuard,
    { provide: getModelToken(Device.name), useValue: deviceModel },
    { provide: DEVICE_TOKEN_PEPPER, useValue: pepper },
  ],
})
class DeviceE2eTestModule {}

describe('Device authentication (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    devices.length = 0;
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      imports: [DeviceE2eTestModule],
    }).compile();

    app = module.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
    );
    app.useGlobalGuards(app.get(DeviceAuthGuard));
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('allows public registration, authenticates the current device, and rejects it after revocation', async () => {
    const registration = await request(app.getHttpServer())
      .post('/devices/register')
      .send({ platform: 'ios', deviceName: 'Test iPhone' })
      .expect(201);

    const registrationBody = registration.body as unknown as {
      deviceId: string;
      token: string;
    };
    expect(registrationBody.deviceId).toBe('device-1');
    expect(registrationBody.token).toMatch(/^[a-f0-9]{64}$/);
    expect(devices[0]).toHaveProperty('tokenHash');
    expect(devices[0]).not.toHaveProperty('token');

    await request(app.getHttpServer())
      .get('/devices/me')
      .set('Authorization', `Bearer ${registrationBody.token}`)
      .expect(200)
      .expect({ deviceId: 'device-1', role: 'owner', status: 'active' });

    await request(app.getHttpServer())
      .delete('/devices/me')
      .set('Authorization', `Bearer ${registrationBody.token}`)
      .expect(200);

    await request(app.getHttpServer())
      .get('/devices/me')
      .set('Authorization', `Bearer ${registrationBody.token}`)
      .expect(401);
  });

  it('protects non-public device routes without a bearer token', async () => {
    await request(app.getHttpServer()).get('/devices/me').expect(401);
    await request(app.getHttpServer()).patch('/devices/me').expect(401);
    await request(app.getHttpServer()).post('/devices/push-token').expect(401);
  });

  it('rejects a null platform and persists a valid authenticated platform update', async () => {
    const registration = await request(app.getHttpServer())
      .post('/devices/register')
      .send({ platform: 'ios' })
      .expect(201);
    const registrationBody = registration.body as unknown as { token: string };

    await request(app.getHttpServer())
      .patch('/devices/me')
      .set('Authorization', `Bearer ${registrationBody.token}`)
      .send({ platform: null })
      .expect(400);

    await request(app.getHttpServer())
      .patch('/devices/me')
      .set('Authorization', `Bearer ${registrationBody.token}`)
      .send({ platform: 'android' })
      .expect(200);

    expect(devices[0]).toMatchObject({ platform: 'android' });
  });
});
