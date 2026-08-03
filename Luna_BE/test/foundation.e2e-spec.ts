import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test, type TestingModule } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { ApiResponseInterceptor } from '../src/common/interceptors/api-response.interceptor';
import { createTransportSecurityMiddleware } from '../src/common/middleware/transport-security.middleware';
import type { NodeEnvironment } from '../src/config/env.validation';

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

interface MongoUser {
  user: string;
  roles: Array<{ role: string; db: string }>;
}

function asObject(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null) {
    throw new Error('Expected a JSON object');
  }

  return value as Record<string, unknown>;
}

function registrationToken(responseBody: unknown): string {
  const body = asObject(responseBody);
  const data = asObject(body.data);
  if (typeof data.token !== 'string') {
    throw new Error('Expected a registration token');
  }

  return data.token;
}

async function getUserRoles(
  mongoUri: string,
  username: string,
): Promise<Array<{ role: string; db: string }>> {
  const connection = await mongoose.createConnection(mongoUri).asPromise();
  try {
    const database = connection.db;
    if (!database) {
      throw new Error('Expected a MongoDB database connection');
    }
    const result = (await database.command({
      usersInfo: username,
    })) as { users: MongoUser[] };
    return result.users[0]?.roles ?? [];
  } finally {
    await connection.close();
  }
}

describe('Luna platform foundation (e2e)', () => {
  let app: INestApplication<App>;
  let mongo: MongoMemoryServer;
  let savedEnvironment: SavedEnvironment;

  beforeAll(async () => {
    savedEnvironment = Object.fromEntries(
      environmentKeys.map((key) => [key, process.env[key]]),
    ) as SavedEnvironment;
    mongo = await MongoMemoryServer.create();
    Object.assign(process.env, {
      NODE_ENV: 'test',
      PORT: '3000',
      MONGODB_URI: mongo.getUri('luna_foundation_e2e'),
      DEVICE_TOKEN_PEPPER: 'foundation-e2e-test-pepper',
      ALLOW_INSECURE_HTTP: 'true',
      TRUST_PROXY: 'false',
      TRUSTED_PROXY_IPS: '',
      CORS_ORIGINS: 'http://localhost:3000',
    });

    const module: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication();
    const config = app.get(ConfigService);
    app.setGlobalPrefix('api/v1');
    app.use(
      createTransportSecurityMiddleware({
        nodeEnvironment: config.getOrThrow<NodeEnvironment>('app.NODE_ENV'),
        allowInsecureHttp: config.getOrThrow<boolean>(
          'app.ALLOW_INSECURE_HTTP',
        ),
      }),
    );
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalInterceptors(new ApiResponseInterceptor());
    app.useGlobalFilters(new HttpExceptionFilter());

    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('Luna API')
        .setDescription('Luna REST API documentation')
        .setVersion('1.0')
        .addBearerAuth()
        .build(),
    );
    SwaggerModule.setup('docs', app, document);
    expect(document.paths).toHaveProperty('/api/v1/devices/register');
    expect(document.paths).toHaveProperty('/api/v1/devices/me');

    await app.init();
  });

  afterAll(async () => {
    await app?.close();
    await mongo?.stop();
    for (const key of environmentKeys) {
      const value = savedEnvironment[key];
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  });

  it('registers an owner through the global success envelope', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role: 'owner', platform: 'ios' })
      .expect(201);

    const responseBody = asObject(response.body as unknown);
    const data = asObject(responseBody.data);
    expect(typeof data.deviceId).toBe('string');
    expect(data.token).toMatch(/^[a-f0-9]{64}$/);
    expect(typeof responseBody.timestamp).toBe('string');
  });

  it('returns the authenticated device through the global success envelope', async () => {
    const registration = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role: 'partner', platform: 'android' })
      .expect(201);
    const token = registrationToken(registration.body as unknown);

    const response = await request(app.getHttpServer())
      .get('/api/v1/devices/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const responseBody = asObject(response.body as unknown);
    const data = asObject(responseBody.data);
    expect(typeof data.deviceId).toBe('string');
    expect(data.role).toBe('partner');
    expect(data.status).toBe('active');
    expect(typeof responseBody.timestamp).toBe('string');
    expect(data).not.toHaveProperty('token');
  });

  it('returns the global error envelope for an invalid bearer token', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/devices/me')
      .set('Authorization', 'Bearer invalid-token')
      .expect(401);

    const responseBody = asObject(response.body as unknown);
    expect(responseBody.code).toBe('UNAUTHORIZED');
    expect(responseBody.message).toBe('Unauthorized');
    expect(responseBody.details).toBe('Unauthorized');
    expect(responseBody.path).toBe('/api/v1/devices/me');
    expect(typeof responseBody.timestamp).toBe('string');
  });

  it('creates rerunnable least-privilege UAT database users without logging passwords', async () => {
    const appPassword = 'app-password-only-test';
    const compassPassword = 'compass-password-only-test';
    const scriptPath = resolve(__dirname, '../scripts/create-uat-user.js');
    const environment = {
      ...process.env,
      MONGO_ADMIN_URI: mongo.getUri('admin'),
      MONGO_APP_PASSWORD: appPassword,
      MONGO_COMPASS_PASSWORD: compassPassword,
    };

    const firstRun = spawnSync(process.execPath, [scriptPath], {
      encoding: 'utf8',
      env: environment,
    });
    const secondRun = spawnSync(process.execPath, [scriptPath], {
      encoding: 'utf8',
      env: environment,
    });

    expect(firstRun.status).toBe(0);
    expect(secondRun.status).toBe(0);
    expect(`${firstRun.stdout}${firstRun.stderr}`).not.toContain(appPassword);
    expect(`${firstRun.stdout}${firstRun.stderr}`).not.toContain(
      compassPassword,
    );
    await expect(
      getUserRoles(mongo.getUri('admin'), 'luna_app'),
    ).resolves.toEqual([{ role: 'readWrite', db: 'luna_uat' }]);
    await expect(
      getUserRoles(mongo.getUri('admin'), 'luna_compass'),
    ).resolves.toEqual([{ role: 'read', db: 'luna_uat' }]);
  });
});
