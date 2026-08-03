import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { getModelToken } from '@nestjs/mongoose';
import { Test, type TestingModule } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import type { Model } from 'mongoose';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { ApiResponseInterceptor } from '../src/common/interceptors/api-response.interceptor';
import { createTransportSecurityMiddleware } from '../src/common/middleware/transport-security.middleware';
import type { NodeEnvironment } from '../src/config/env.validation';
import {
  Device,
  type DeviceDocument,
} from '../src/modules/device/schemas/device.schema';
import { cleanupFoundationE2e } from './foundation-e2e-cleanup';

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

const rootUsername = 'foundation-root';
const rootPassword = 'foundation-root-password';
const appPassword = 'app-password=only-test';
const compassPassword = 'compass-password=only-test';

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

function authenticatedMongoUri(
  mongoUri: string,
  username: string,
  password: string,
  database: string,
): string {
  const uri = new URL(mongoUri);
  uri.username = username;
  uri.password = password;
  uri.pathname = `/${database}`;
  uri.searchParams.set('authSource', 'admin');
  return uri.toString();
}

async function authenticateMongoUser(mongoUri: string): Promise<void> {
  const connection = await mongoose.createConnection(mongoUri).asPromise();
  await connection.close();
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
  let adminUri: string;
  let appUri: string;
  let userBootstrapArgs: string[];

  beforeAll(async () => {
    savedEnvironment = Object.fromEntries(
      environmentKeys.map((key) => [key, process.env[key]]),
    ) as SavedEnvironment;
    mongo = await MongoMemoryServer.create({
      auth: {
        enable: true,
        customRootName: rootUsername,
        customRootPwd: rootPassword,
      },
    });
    adminUri = authenticatedMongoUri(
      mongo.getUri('admin'),
      rootUsername,
      rootPassword,
      'admin',
    );
    adminUri = `${adminUri}&directConnection=true`;
    appUri = authenticatedMongoUri(
      mongo.getUri('luna_uat'),
      'luna_app',
      appPassword,
      'luna_uat',
    );
    const scriptPath = resolve(__dirname, '../scripts/create-uat-user.js');
    userBootstrapArgs = [
      scriptPath,
      `--mongo-admin-uri=${adminUri}`,
      `--app-password=${appPassword}`,
      `--compass-password=${compassPassword}`,
    ];
    const initialBootstrap = spawnSync(process.execPath, userBootstrapArgs, {
      encoding: 'utf8',
    });
    expect(initialBootstrap.status).toBe(0);
    Object.assign(process.env, {
      NODE_ENV: 'test',
      PORT: '3000',
      MONGODB_URI: appUri,
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
    await cleanupFoundationE2e({
      closeApp: () => app?.close(),
      stopMongo: () => mongo?.stop(),
      restoreEnvironment: () => {
        for (const key of environmentKeys) {
          const value = savedEnvironment[key];
          if (value === undefined) {
            delete process.env[key];
          } else {
            process.env[key] = value;
          }
        }
      },
    });
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

  it('returns nullable global envelopes for authenticated device commands', async () => {
    const registration = await request(app.getHttpServer())
      .post('/api/v1/devices/register')
      .send({ role: 'owner', platform: 'ios' })
      .expect(201);
    const registrationBody = asObject(registration.body as unknown);
    const registrationData = asObject(registrationBody.data);
    const token = registrationToken(registration.body as unknown);
    const deviceId = String(registrationData.deviceId);

    const patchResponse = await request(app.getHttpServer())
      .patch('/api/v1/devices/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ platform: 'android' })
      .expect(200);
    const patchBody = asObject(patchResponse.body as unknown);
    expect(patchBody.data).toBeNull();
    expect(typeof patchBody.timestamp).toBe('string');
    expect(Object.keys(patchBody).sort()).toEqual(['data', 'timestamp']);

    const pushResponse = await request(app.getHttpServer())
      .post('/api/v1/devices/push-token')
      .set('Authorization', `Bearer ${token}`)
      .send({ fcmToken: 'foundation-fcm-token' })
      .expect(201);
    const pushBody = asObject(pushResponse.body as unknown);
    expect(pushBody.data).toBeNull();
    expect(typeof pushBody.timestamp).toBe('string');
    expect(Object.keys(pushBody).sort()).toEqual(['data', 'timestamp']);
    const deviceModel = app.get<Model<DeviceDocument>>(
      getModelToken(Device.name),
    );
    await expect(deviceModel.findById(deviceId).lean().exec()).resolves.toEqual(
      expect.objectContaining({
        platform: 'android',
        fcmToken: 'foundation-fcm-token',
      }),
    );

    const deleteResponse = await request(app.getHttpServer())
      .delete('/api/v1/devices/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const deleteBody = asObject(deleteResponse.body as unknown);
    expect(deleteBody.data).toBeNull();
    expect(typeof deleteBody.timestamp).toBe('string');
    expect(Object.keys(deleteBody).sort()).toEqual(['data', 'timestamp']);
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
    const secondRun = spawnSync(process.execPath, userBootstrapArgs, {
      encoding: 'utf8',
    });

    expect(secondRun.status).toBe(0);
    expect(`${secondRun.stdout}${secondRun.stderr}`).not.toContain(appPassword);
    expect(`${secondRun.stdout}${secondRun.stderr}`).not.toContain(
      compassPassword,
    );
    await expect(authenticateMongoUser(appUri)).resolves.toBeUndefined();
    await expect(getUserRoles(adminUri, 'luna_app')).resolves.toEqual([
      { role: 'readWrite', db: 'luna_uat' },
    ]);
    await expect(getUserRoles(adminUri, 'luna_compass')).resolves.toEqual([
      { role: 'read', db: 'luna_uat' },
    ]);
  });
});
