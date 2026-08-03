import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, type TestingModule } from '@nestjs/testing';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { ApiResponseInterceptor } from '../src/common/interceptors/api-response.interceptor';

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

function asArray(value: unknown): unknown[] {
  if (!Array.isArray(value))
    throw new Error('Expected an array response value.');
  return value;
}

function expectEnvelope(value: unknown): Record<string, unknown> {
  const envelope = asObject(value);
  expect(Object.keys(envelope).sort()).toEqual(['data', 'timestamp']);
  expect(typeof envelope.timestamp).toBe('string');
  expect(new Date(String(envelope.timestamp)).toISOString()).toBe(
    envelope.timestamp,
  );
  return envelope;
}

function token(responseBody: unknown): string {
  const data = asObject(expectEnvelope(responseBody).data);
  if (typeof data.token !== 'string') throw new Error('Expected device token.');
  return data.token;
}

describe('Cycle and journal flow (e2e)', () => {
  let app: INestApplication<App>;
  let mongo: MongoMemoryReplSet;
  let savedEnvironment: SavedEnvironment;

  function authorized(ownerToken: string): Record<string, string> {
    return { Authorization: `Bearer ${ownerToken}` };
  }

  async function registerOwner(): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role: 'owner', platform: 'ios' })
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
      MONGODB_URI: mongo.getUri('luna_cycle_journal_flow_e2e'),
      DEVICE_TOKEN_PEPPER: 'cycle-journal-flow-e2e-pepper',
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

  it('persists an owner cycle and daily journal through dashboard and calendar projections', async () => {
    const ownerToken = await registerOwner();
    const server = app.getHttpServer();
    const date = '2026-08-03';

    const start = await request(server)
      .post('/api/v1/cycles/start')
      .set(authorized(ownerToken))
      .send({ date })
      .expect(201);
    expect(expectEnvelope(start.body).data).toEqual({
      startDate: date,
      endDate: null,
      periodLength: null,
      cycleLength: null,
      source: 'manual',
    });

    const mood = await request(server)
      .put(`/api/v1/moods/${date}`)
      .set(authorized(ownerToken))
      .send({ mood: 'happy' })
      .expect(200);
    expect(expectEnvelope(mood.body).data).toEqual({ date, mood: 'happy' });

    const symptoms = await request(server)
      .put(`/api/v1/symptoms/${date}`)
      .set(authorized(ownerToken))
      .send({ symptoms: ['cramps'], discomfortLevel: 3 })
      .expect(200);
    expect(expectEnvelope(symptoms.body).data).toEqual({
      date,
      symptoms: ['cramps'],
      discomfortLevel: 3,
    });

    const note = await request(server)
      .put(`/api/v1/notes/${date}`)
      .set(authorized(ownerToken))
      .send({ note: 'Flow checkpoint note.' })
      .expect(200);
    expect(expectEnvelope(note.body).data).toEqual({
      date,
      note: 'Flow checkpoint note.',
    });

    const dashboard = await request(server)
      .get(`/api/v1/health/dashboard?date=${date}`)
      .set(authorized(ownerToken))
      .expect(200);
    const dashboardData = asObject(expectEnvelope(dashboard.body).data);
    expect(dashboardData.date).toBe(date);
    expect(dashboardData.relationship).toBe('owner');
    expect(asObject(dashboardData.cycle)).toMatchObject({
      currentCycleDay: 1,
      isPeriodActive: true,
    });
    expect(asObject(dashboardData.dailyLog)).toEqual({
      mood: 'happy',
      symptoms: ['cramps'],
      discomfortLevel: 3,
      note: 'Flow checkpoint note.',
    });

    const calendar = await request(server)
      .get('/api/v1/calendar?month=2026-08')
      .set(authorized(ownerToken))
      .expect(200);
    const calendarData = asObject(expectEnvelope(calendar.body).data);
    expect(calendarData.month).toBe('2026-08');
    const observedDay = asArray(calendarData.days).find(
      (item) => asObject(item).date === date,
    );
    expect(asObject(observedDay)).toEqual({
      date,
      status: 'observed-period',
      isObservedPeriod: true,
      isPredictedPeriod: false,
      isOvulation: false,
    });

    const ended = await request(server)
      .post('/api/v1/cycles/end')
      .set(authorized(ownerToken))
      .send({ date: '2026-08-05' })
      .expect(201);
    expect(expectEnvelope(ended.body).data).toEqual({
      startDate: date,
      endDate: '2026-08-05',
      periodLength: 3,
      cycleLength: null,
      source: 'manual',
    });

    const journal = await request(server)
      .get(`/api/v1/health/journal?from=${date}&to=${date}`)
      .set(authorized(ownerToken))
      .expect(200);
    expect(expectEnvelope(journal.body).data).toEqual({
      page: 1,
      limit: 20,
      items: [
        {
          date,
          mood: 'happy',
          symptoms: ['cramps'],
          discomfortLevel: 3,
          note: 'Flow checkpoint note.',
        },
      ],
    });
  });
});
