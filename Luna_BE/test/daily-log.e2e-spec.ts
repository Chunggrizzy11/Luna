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
import {
  DailyLog,
  type DailyLogDocument,
} from '../src/modules/health/schemas/daily-log.schema';

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

describe('daily health log endpoints', () => {
  let app: INestApplication<App>;
  let mongo: MongoMemoryServer;
  let savedEnvironment: SavedEnvironment;
  let dailyLogModel: Model<DailyLogDocument>;

  async function registerDevice(role: 'owner' | 'partner'): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role, platform: role === 'owner' ? 'ios' : 'android' })
      .expect(201);
    return token(response.body as unknown);
  }

  function authorized(token: string) {
    return `Bearer ${token}`;
  }

  beforeAll(async () => {
    savedEnvironment = Object.fromEntries(
      environmentKeys.map((key) => [key, process.env[key]]),
    ) as SavedEnvironment;
    mongo = await MongoMemoryServer.create();
    Object.assign(process.env, {
      NODE_ENV: 'test',
      PORT: '3000',
      MONGODB_URI: mongo.getUri('luna_daily_log_e2e'),
      DEVICE_TOKEN_PEPPER: 'daily-log-e2e-pepper',
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

    dailyLogModel = app.get<Model<DailyLogDocument>>(
      getModelToken(DailyLog.name),
    );
    await dailyLogModel.syncIndexes();
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

  it('returns null and empty projections in the global envelope when no log exists', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();

    const [mood, symptoms, note] = await Promise.all([
      request(server)
        .get('/api/v1/moods/2026-08-03')
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get('/api/v1/symptoms/2026-08-03')
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get('/api/v1/notes/2026-08-03')
        .set('Authorization', authorized(ownerToken))
        .expect(200),
    ]);

    expect(asObject(mood.body).data).toEqual({
      date: '2026-08-03',
      mood: null,
    });
    expect(asObject(symptoms.body).data).toEqual({
      date: '2026-08-03',
      symptoms: [],
      discomfortLevel: null,
    });
    expect(asObject(note.body).data).toEqual({
      date: '2026-08-03',
      note: null,
    });
    expect(typeof asObject(mood.body).timestamp).toBe('string');
  });

  it('preserves symptom and note fields when a mood update races with them', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    const date = '2026-08-04';
    await request(server)
      .put(`/api/v1/symptoms/${date}`)
      .set('Authorization', authorized(ownerToken))
      .send({ symptoms: ['cramps', 'back_pain'], discomfortLevel: 4 })
      .expect(200);
    await request(server)
      .put(`/api/v1/notes/${date}`)
      .set('Authorization', authorized(ownerToken))
      .send({ note: 'Keep this note.' })
      .expect(200);

    const updates = await Promise.all([
      request(server)
        .put(`/api/v1/moods/${date}`)
        .set('Authorization', authorized(ownerToken))
        .send({ mood: 'happy' }),
      request(server)
        .put(`/api/v1/symptoms/${date}`)
        .set('Authorization', authorized(ownerToken))
        .send({ symptoms: ['dizziness'], discomfortLevel: 5 }),
    ]);
    expect(updates.map((response) => response.status)).toEqual([200, 200]);

    const [mood, symptoms, note] = await Promise.all([
      request(server)
        .get(`/api/v1/moods/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get(`/api/v1/symptoms/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get(`/api/v1/notes/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
    ]);

    expect(asObject(mood.body).data).toEqual({ date, mood: 'happy' });
    expect(asObject(symptoms.body).data).toEqual({
      date,
      symptoms: ['dizziness'],
      discomfortLevel: 5,
    });
    expect(asObject(note.body).data).toEqual({ date, note: 'Keep this note.' });
  });

  it('deletes only a note and keeps the neighboring mood and symptom fields', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    const date = '2026-08-05';
    await request(server)
      .put(`/api/v1/moods/${date}`)
      .set('Authorization', authorized(ownerToken))
      .send({ mood: 'anxious' })
      .expect(200);
    await request(server)
      .put(`/api/v1/symptoms/${date}`)
      .set('Authorization', authorized(ownerToken))
      .send({ symptoms: ['insomnia'], discomfortLevel: 2 })
      .expect(200);
    await request(server)
      .put(`/api/v1/notes/${date}`)
      .set('Authorization', authorized(ownerToken))
      .send({ note: 'Delete only this text.' })
      .expect(200);

    const deleted = await request(server)
      .delete(`/api/v1/notes/${date}`)
      .set('Authorization', authorized(ownerToken))
      .expect(200);
    expect(asObject(deleted.body).data).toEqual({ date, note: null });

    const [mood, symptoms, note] = await Promise.all([
      request(server)
        .get(`/api/v1/moods/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get(`/api/v1/symptoms/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get(`/api/v1/notes/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
    ]);
    expect(asObject(mood.body).data).toEqual({ date, mood: 'anxious' });
    expect(asObject(symptoms.body).data).toEqual({
      date,
      symptoms: ['insomnia'],
      discomfortLevel: 2,
    });
    expect(asObject(note.body).data).toEqual({ date, note: null });
  });

  it('merges concurrent first writes into one daily log', async () => {
    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    const date = '2026-08-06';
    const responses = await Promise.all([
      request(server)
        .put(`/api/v1/moods/${date}`)
        .set('Authorization', authorized(ownerToken))
        .send({ mood: 'sleepy' }),
      request(server)
        .put(`/api/v1/notes/${date}`)
        .set('Authorization', authorized(ownerToken))
        .send({ note: 'A concurrent first note.' }),
    ]);
    expect(responses.map((response) => response.status)).toEqual([200, 200]);

    const [mood, note] = await Promise.all([
      request(server)
        .get(`/api/v1/moods/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
      request(server)
        .get(`/api/v1/notes/${date}`)
        .set('Authorization', authorized(ownerToken))
        .expect(200),
    ]);
    expect(asObject(mood.body).data).toEqual({ date, mood: 'sleepy' });
    expect(asObject(note.body).data).toEqual({
      date,
      note: 'A concurrent first note.',
    });
  });

  it('denies partners and validates dates, enums, and discomfort bounds', async () => {
    const partnerToken = await registerDevice('partner');
    await request(app.getHttpServer())
      .get('/api/v1/moods/2026-08-03')
      .set('Authorization', authorized(partnerToken))
      .expect(403);

    const ownerToken = await registerDevice('owner');
    const server = app.getHttpServer();
    for (const response of [
      await request(server)
        .put('/api/v1/moods/2026-02-30')
        .set('Authorization', authorized(ownerToken))
        .send({ mood: 'happy' })
        .expect(400),
      await request(server)
        .put('/api/v1/moods/2026-08-03')
        .set('Authorization', authorized(ownerToken))
        .send({ mood: 'calm' })
        .expect(400),
      await request(server)
        .put('/api/v1/symptoms/2026-08-03')
        .set('Authorization', authorized(ownerToken))
        .send({ symptoms: ['cramps'], discomfortLevel: 6 })
        .expect(400),
    ]) {
      expect(asObject(response.body).code).toBe('BAD_REQUEST');
    }
  });

  it('enforces one document per owner and date at the Mongo index boundary', async () => {
    const ownerToken = await registerDevice('owner');
    const device = await request(app.getHttpServer())
      .get('/api/v1/devices/me')
      .set('Authorization', authorized(ownerToken))
      .expect(200);
    const ownerDeviceId = String(asObject(asObject(device.body).data).deviceId);

    await dailyLogModel.create({ ownerDeviceId, date: '2026-08-07' });
    await expect(
      dailyLogModel.create({ ownerDeviceId, date: '2026-08-07' }),
    ).rejects.toMatchObject({ code: 11000 });
  });
});
