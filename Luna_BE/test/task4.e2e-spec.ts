import { INestApplication, ValidationPipe } from '@nestjs/common';
import { getModelToken } from '@nestjs/mongoose';
import { Test, type TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import type { Model } from 'mongoose';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { ApiResponseInterceptor } from '../src/common/interceptors/api-response.interceptor';
import { Cycle } from '../src/modules/cycle/schemas/cycle.schema';
import { Device } from '../src/modules/device/schemas/device.schema';
import { DailyLog } from '../src/modules/health/schemas/daily-log.schema';

const environmentKeys = [
  'NODE_ENV',
  'PORT',
  'MONGODB_URI',
  'DEVICE_TOKEN_PEPPER',
  'ALLOW_INSECURE_HTTP',
  'TRUST_PROXY',
  'TRUSTED_PROXY_IPS',
  'CORS_ORIGINS',
] as const;

type EnvironmentKey = (typeof environmentKeys)[number];
type SavedEnvironment = Record<EnvironmentKey, string | undefined>;

function asObject(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null) {
    throw new Error('Expected an object response body.');
  }
  return value as Record<string, unknown>;
}

function data(response: unknown): Record<string, unknown> {
  return asObject(asObject(response).data);
}

describe('Task 4 health query endpoints (e2e)', () => {
  let app: INestApplication<App>;
  let mongo: MongoMemoryServer;
  let savedEnvironment: SavedEnvironment;
  let cycleModel: Model<Cycle>;
  let dailyLogModel: Model<DailyLog>;
  let deviceModel: Model<Device>;

  async function register(
    role: 'owner' | 'partner',
    pairId?: string,
  ): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role, platform: role === 'owner' ? 'ios' : 'android', pairId })
      .expect(201);
    const token = data(response.body).token;
    if (typeof token !== 'string') throw new Error('Expected device token.');
    return token;
  }

  async function deviceId(token: string): Promise<string> {
    const response = await request(app.getHttpServer())
      .get('/api/v1/devices/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const id = data(response.body).deviceId;
    if (typeof id !== 'string') throw new Error('Expected device id.');
    return id;
  }

  beforeAll(async () => {
    savedEnvironment = Object.fromEntries(
      environmentKeys.map((key) => [key, process.env[key]]),
    ) as SavedEnvironment;
    mongo = await MongoMemoryServer.create();
    Object.assign(process.env, {
      NODE_ENV: 'test',
      PORT: '3000',
      MONGODB_URI: mongo.getUri('luna_task4_e2e'),
      DEVICE_TOKEN_PEPPER: 'task4-e2e-pepper',
      ALLOW_INSECURE_HTTP: 'true',
      TRUST_PROXY: 'false',
      TRUSTED_PROXY_IPS: '',
      CORS_ORIGINS: 'http://localhost:3000',
    });
    const module: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalInterceptors(new ApiResponseInterceptor());
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
    cycleModel = app.get<Model<Cycle>>(getModelToken(Cycle.name));
    dailyLogModel = app.get<Model<DailyLog>>(getModelToken(DailyLog.name));
    deviceModel = app.get<Model<Device>>(getModelToken(Device.name));
  });

  afterAll(async () => {
    await app?.close();
    await mongo?.stop();
    for (const key of environmentKeys) {
      const value = savedEnvironment[key];
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });

  it('applies authentication and strict query validation through global envelopes', async () => {
    const unauthenticated = await request(app.getHttpServer())
      .get('/api/v1/health/journal')
      .expect(401);
    expect(asObject(unauthenticated.body)).toMatchObject({
      code: 'UNAUTHORIZED',
    });

    const owner = await register('owner');
    const server = app.getHttpServer();
    for (const path of [
      '/api/v1/calendar?month=2026-13',
      '/api/v1/health/dashboard',
      '/api/v1/health/journal?page=0',
    ]) {
      const response = await request(server)
        .get(path)
        .set('Authorization', `Bearer ${owner}`)
        .expect(400);
      expect(asObject(response.body)).toMatchObject({ code: 'BAD_REQUEST' });
      expect(typeof asObject(response.body).timestamp).toBe('string');
    }
  });

  it('returns owner calendar and journal data in exact success envelopes while denying partners', async () => {
    const owner = await register('owner');
    const partner = await register('partner');
    const ownerId = await deviceId(owner);
    await cycleModel.create({
      ownerDeviceId: ownerId,
      startDate: '2026-03-01',
      endDate: '2026-03-05',
      periodLength: 5,
      cycleLength: 28,
      source: 'manual',
    });
    await dailyLogModel.create({
      ownerDeviceId: ownerId,
      date: '2026-03-03',
      mood: 'happy',
      symptoms: ['cramps'],
      discomfortLevel: 3,
      note: 'Owner-only note',
    });

    const calendar = await request(app.getHttpServer())
      .get('/api/v1/calendar?month=2026-03')
      .set('Authorization', `Bearer ${owner}`)
      .expect(200);
    expect(data(calendar.body)).toMatchObject({ month: '2026-03' });
    expect(
      (data(calendar.body).days as Array<Record<string, unknown>>).find(
        (day) => day.date === '2026-03-03',
      ),
    ).toMatchObject({ status: 'observed-period' });
    expect(typeof asObject(calendar.body).timestamp).toBe('string');

    const journal = await request(app.getHttpServer())
      .get(
        '/api/v1/health/journal?from=2026-03-03&to=2026-03-03&page=1&limit=1',
      )
      .set('Authorization', `Bearer ${owner}`)
      .expect(200);
    expect(data(journal.body)).toEqual({
      items: [
        {
          date: '2026-03-03',
          mood: 'happy',
          symptoms: ['cramps'],
          discomfortLevel: 3,
          note: 'Owner-only note',
        },
      ],
      page: 1,
      limit: 1,
    });
    await request(app.getHttpServer())
      .get('/api/v1/calendar?month=2026-03')
      .set('Authorization', `Bearer ${partner}`)
      .expect(403);
    await request(app.getHttpServer())
      .get('/api/v1/health/journal')
      .set('Authorization', `Bearer ${partner}`)
      .expect(403);
  });

  it('keeps guessed registration pair ids unpaired and only exposes an explicitly server-bound owner summary', async () => {
    const owner = await register('owner', 'guessed-pair-id');
    const partner = await register('partner', 'guessed-pair-id');
    const [ownerId, partnerId] = await Promise.all([
      deviceId(owner),
      deviceId(partner),
    ]);
    await cycleModel.create({
      ownerDeviceId: ownerId,
      startDate: '2026-03-01',
      endDate: null,
      source: 'manual',
    });
    await dailyLogModel.create({
      ownerDeviceId: ownerId,
      date: '2026-03-12',
      mood: 'sad',
      symptoms: ['cramps'],
      discomfortLevel: 5,
      note: 'Never expose this note',
    });

    const spoofed = await request(app.getHttpServer())
      .get('/api/v1/health/dashboard?date=2026-03-12')
      .set('Authorization', `Bearer ${partner}`)
      .expect(200);
    expect(data(spoofed.body)).toEqual({
      date: '2026-03-12',
      relationship: 'unpaired',
      cycle: null,
      discomfortLevel: null,
    });

    const ownerDevice = await deviceModel.findById(ownerId).lean().exec();
    if (!ownerDevice?.pairId) throw new Error('Expected server pair id.');
    await deviceModel
      .findByIdAndUpdate(
        partnerId,
        {
          pairId: ownerDevice.pairId,
          pairedOwnerDeviceId: ownerId,
        },
        { runValidators: true },
      )
      .exec();

    const paired = await request(app.getHttpServer())
      .get('/api/v1/health/dashboard?date=2026-03-12')
      .set('Authorization', `Bearer ${partner}`)
      .expect(200);
    expect(data(paired.body)).toEqual({
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
  });
});
