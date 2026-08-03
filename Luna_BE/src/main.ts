import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import compression from 'compression';
import type { Express } from 'express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ApiResponseInterceptor } from './common/interceptors/api-response.interceptor';
import {
  createTransportSecurityMiddleware,
  createTrustedProxyTrust,
} from './common/middleware/transport-security.middleware';
import type { NodeEnvironment } from './config/env.validation';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  const corsOrigins = configService.getOrThrow<string[]>('app.corsOrigins');
  const trustProxy = configService.getOrThrow<boolean>('app.TRUST_PROXY');
  const trustedProxyIps = configService.getOrThrow<string[]>(
    'app.trustedProxyIps',
  );
  const trustedProxy = trustProxy
    ? createTrustedProxyTrust(trustedProxyIps)
    : undefined;
  const expressApp = app.getHttpAdapter().getInstance() as Express;

  app.setGlobalPrefix('api/v1');
  expressApp.set('trust proxy', trustedProxy ?? false);
  app.use(helmet());
  app.use(compression());
  app.use(
    createTransportSecurityMiddleware({
      nodeEnvironment:
        configService.getOrThrow<NodeEnvironment>('app.NODE_ENV'),
      allowInsecureHttp: configService.getOrThrow<boolean>(
        'app.ALLOW_INSECURE_HTTP',
      ),
      trustedProxy,
    }),
  );
  app.enableCors({
    credentials: true,
    origin: (
      origin: string | undefined,
      callback: (error: Error | null, allow?: boolean) => void,
    ) => {
      if (!origin || corsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('Origin is not allowed by CORS'));
    },
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalInterceptors(new ApiResponseInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  const swaggerDocument = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle('Luna API')
      .setDescription('Luna REST API documentation')
      .setVersion('1.0')
      .addBearerAuth()
      .build(),
  );
  SwaggerModule.setup('docs', app, swaggerDocument);

  await app.listen(configService.getOrThrow<number>('app.PORT'));
}
void bootstrap();
