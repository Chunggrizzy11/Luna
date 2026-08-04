import { INestApplication, Logger, ValidationPipe } from '@nestjs/common';
import { getModelToken } from '@nestjs/mongoose';
import { Test, type TestingModule } from '@nestjs/testing';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import type { Model } from 'mongoose';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { ApiResponseInterceptor } from '../src/common/interceptors/api-response.interceptor';
import {
  Cycle,
  type CycleDocument,
} from '../src/modules/cycle/schemas/cycle.schema';

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

function token(responseBody: unknown): string {
  const data = asObject(asObject(responseBody).data);
  if (typeof data.token !== 'string') throw new Error('Expected device token.');
  return data.token;
}

describe('Cycle endpoints (e2e)', () => {
  let app: INestApplication<App>;
  let mongo: MongoMemoryReplSet;
  let savedEnvironment: SavedEnvironment;
  let cycleModel: Model<CycleDocument>;

  async function registerDevice(role: 'owner' | 'partner'): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role, platform: role === 'owner' ? 'ios' : 'android' })
      .expect(201);
    return token(response.body as unknown);
  }

  beforeAll(async () => {
    savedEnvironment = Object.fromEntries(
      environmentKeys.map((key) => [key, process.env[key]]),
    ) as SavedEnvironment;
    mongo = await MongoMemoryReplSet.create({ replSet: { count: 1 } });
    Object.assign(process.env, {
      NODE_ENV: 'test',
      PORT: '3000',
      MONGODB_URI: mongo.getUri('luna_cycle_e2e'),
      DEVICE_TOKEN_PEPPER: 'cycle-e2e-pepper',
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

    cycleModel = app.get<Model<CycleDocument>>(getModelToken(Cycle.name));
    await cycleModel.syncIndexes();
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

  it('returns a nullable global envelope when an owner has no current cycle', async () => {
    const ownerToken = await registerDevice('owner');
    const response = await request(app.getHttpServer())
      .get('/api/v1/cycles/current')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    expect(asObject(response.body as unknown)).toMatchObject({ data: null });
    expect(typeof asObject(response.body as unknown).timestamp).toBe('string');
  });

  it('denies a partner every cycle endpoint', async () => {
    const partnerToken = await registerDevice('partner');
    for (const path of [
      '/api/v1/cycles',
      '/api/v1/cycles/current',
      '/api/v1/cycles/prediction?today=2026-03-01',
    ]) {
      const response = await request(app.getHttpServer())
        .get(path)
        .set('Authorization', `Bearer ${partnerToken}`)
        .expect(403);
      expect(asObject(response.body as unknown).code).toBe('FORBIDDEN');
    }
    await request(app.getHttpServer())
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${partnerToken}`)
      .send({ date: '2026-03-01' })
      .expect(403);
    await request(app.getHttpServer())
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${partnerToken}`)
      .send({ date: '2026-03-01' })
      .expect(403);
  });

  it('runs an owner lifecycle with envelopes and derives the preceding cycle length', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    const start = await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-02-01' })
      .expect(201);
    expect(asObject(start.body as unknown).data).toMatchObject({
      startDate: '2026-02-01',
      endDate: null,
      source: 'manual',
    });

    const sameDayEnd = await request(server)
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-02-01' })
      .expect(201);
    expect(asObject(sameDayEnd.body as unknown).data).toMatchObject({
      endDate: '2026-02-01',
      periodLength: 1,
    });

    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-03-01' })
      .expect(201);

    const history = await request(server)
      .get('/api/v1/cycles?from=2026-02-01&to=2026-03-01')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const data = asObject(asObject(history.body as unknown).data);
    expect(data).toMatchObject({ page: 1, limit: 20 });
    expect(data.items).toEqual([
      expect.objectContaining({ startDate: '2026-03-01', endDate: null }),
      expect.objectContaining({
        startDate: '2026-02-01',
        cycleLength: 28,
        periodLength: 1,
      }),
    ]);

    const prediction = await request(server)
      .get('/api/v1/cycles/prediction?today=2026-03-12')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(asObject(prediction.body as unknown).data).toMatchObject({
      averageCycleLength: 28,
      averagePeriodLength: 1,
      ovulationDate: null,
      predictedPeriodStart: '2026-03-29',
    });
  });

  it('uses the replaceable default settings provider when no history is started', async () => {
    const ownerToken = await registerDevice('owner');
    const response = await request(app.getHttpServer())
      .get('/api/v1/cycles/prediction?today=2026-03-12')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);

    expect(asObject(response.body as unknown).data).toMatchObject({
      averageCycleLength: 28,
      averagePeriodLength: 5,
      ovulationDate: null,
      predictedPeriodStart: null,
    });
  });

  it('keeps owner histories isolated', async () => {
    const firstOwnerToken = await registerDevice('owner');
    const secondOwnerToken = await registerDevice('owner');
    await request(app.getHttpServer())
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${firstOwnerToken}`)
      .send({ date: '2026-03-01' })
      .expect(201);
    const response = await request(app.getHttpServer())
      .get('/api/v1/cycles')
      .set('Authorization', `Bearer ${secondOwnerToken}`)
      .expect(200);
    expect(asObject(asObject(response.body as unknown).data).items).toEqual([]);
  });

  it('enforces the active-cycle unique partial index', async () => {
    const ownerToken = await registerDevice('owner');
    const current = await request(app.getHttpServer())
      .get('/api/v1/devices/me')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const deviceId = String(
      asObject(asObject(current.body as unknown).data).deviceId,
    );
    await cycleModel.create({
      ownerDeviceId: deviceId,
      startDate: '2026-04-01',
      endDate: null,
      source: 'manual',
    });
    await expect(
      cycleModel.create({
        ownerDeviceId: deviceId,
        startDate: '2026-05-01',
        endDate: null,
        source: 'manual',
      }),
    ).rejects.toMatchObject({ code: 11000 });
  });

  it('preserves the predecessor length of the concurrent winning start only', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-01-01' })
      .expect(201);
    await request(server)
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-01-01' })
      .expect(201);

    const candidateDates = ['2026-02-01', '2026-03-01'];
    const responses = await Promise.all(
      candidateDates.map((date) =>
        request(server)
          .post('/api/v1/cycles/start')
          .set('Authorization', `Bearer ${ownerToken}`)
          .send({ date }),
      ),
    );
    expect(responses.map((response) => response.status).sort()).toEqual([
      201, 409,
    ]);
    const winningDate = candidateDates.find(
      (_, index) => responses[index].status === 201,
    );
    expect(winningDate).toBeDefined();

    const history = await request(server)
      .get('/api/v1/cycles')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const items = asObject(asObject(history.body as unknown).data)
      .items as Array<Record<string, unknown>>;
    const predecessor = items.find((cycle) => cycle.startDate === '2026-01-01');
    const expectedLength = winningDate === '2026-02-01' ? 31 : 59;
    expect(predecessor).toMatchObject({ cycleLength: expectedLength });
  });

  it('rejects a backdated start against the latest completed lifecycle', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-04-01' })
      .expect(201);
    await request(server)
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-04-05' })
      .expect(201);

    const response = await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-03-01' })
      .expect(409);

    expect(asObject(response.body as unknown).message).toBe(
      'A new cycle must start after the latest cycle dates.',
    );
    const current = await request(server)
      .get('/api/v1/cycles/current')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(asObject(current.body as unknown).data).toBeNull();
  });

  it('starts a new series after a hiatus beyond 365 days', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2025-01-01' })
      .expect(201);
    await request(server)
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2025-01-05' })
      .expect(201);

    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-02-01' })
      .expect(201);

    const history = await request(server)
      .get('/api/v1/cycles')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const items = asObject(asObject(history.body as unknown).data)
      .items as Array<Record<string, unknown>>;
    expect(items).toEqual([
      expect.objectContaining({ startDate: '2026-02-01', endDate: null }),
      expect.objectContaining({
        startDate: '2025-01-01',
        cycleLength: null,
      }),
    ]);
  });

  it('recovers an active cycle older than 90 days and permits the next lifecycle', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-01-01' })
      .expect(201);

    const recovered = await request(server)
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-04-15' })
      .expect(201);
    expect(asObject(recovered.body as unknown).data).toMatchObject({
      startDate: '2026-01-01',
      endDate: '2026-04-15',
      periodLength: null,
    });

    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-04-16' })
      .expect(201);
    const history = await request(server)
      .get('/api/v1/cycles')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const items = asObject(asObject(history.body as unknown).data)
      .items as Array<Record<string, unknown>>;
    expect(items[1]).toMatchObject({
      startDate: '2026-01-01',
      periodLength: null,
      cycleLength: 105,
    });
  });

  it('leaves no active reservation when predecessor update and legacy cleanup both fail', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    await request(server)
      .post('/api/v1/cycles/start')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-01-01' })
      .expect(201);
    await request(server)
      .post('/api/v1/cycles/end')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ date: '2026-01-01' })
      .expect(201);

    const updateFailure = new Error('predecessor write failed');
    const deleteFailure = new Error('legacy cleanup failed');
    const updateSpy = jest
      .spyOn(cycleModel, 'findOneAndUpdate')
      .mockReturnValueOnce({
        exec: jest.fn().mockRejectedValue(updateFailure),
      } as never);
    const deleteSpy = jest.spyOn(cycleModel, 'deleteOne').mockReturnValueOnce({
      exec: jest.fn().mockRejectedValue(deleteFailure),
    } as never);
    const loggerSpy = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation(() => undefined);
    try {
      await request(server)
        .post('/api/v1/cycles/start')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ date: '2026-02-01' })
        .expect(500);
      expect(loggerSpy).toHaveBeenCalledWith(
        'Unhandled HTTP 500: predecessor write failed',
      );
    } finally {
      updateSpy.mockRestore();
      deleteSpy.mockRestore();
      loggerSpy.mockRestore();
    }

    const current = await request(server)
      .get('/api/v1/cycles/current')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(asObject(current.body as unknown).data).toBeNull();

    const history = await request(server)
      .get('/api/v1/cycles')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const items = asObject(asObject(history.body as unknown).data)
      .items as Array<Record<string, unknown>>;
    expect(items).toEqual([
      expect.objectContaining({
        startDate: '2026-01-01',
        cycleLength: null,
      }),
    ]);
  });
});
