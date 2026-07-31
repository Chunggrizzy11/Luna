import { registerAs } from '@nestjs/config';
import type { Environment } from './env.validation';

export default registerAs('app', (): Pick<
  Environment,
  'NODE_ENV' | 'PORT' | 'ALLOW_INSECURE_HTTP'
> & { corsOrigins: string[] } => ({
  NODE_ENV: process.env.NODE_ENV as Environment['NODE_ENV'],
  PORT: Number(process.env.PORT),
  ALLOW_INSECURE_HTTP: process.env.ALLOW_INSECURE_HTTP === 'true',
  corsOrigins: (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
}));
