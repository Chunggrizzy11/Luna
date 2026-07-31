export type NodeEnvironment = 'development' | 'test' | 'uat' | 'production';

export interface Environment {
  NODE_ENV: NodeEnvironment;
  PORT: number;
  MONGODB_URI: string;
  DEVICE_TOKEN_PEPPER: string;
  ALLOW_INSECURE_HTTP: boolean;
  TRUST_PROXY: boolean;
  CORS_ORIGINS: string;
  FCM_SERVICE_ACCOUNT_JSON?: string;
}

const defaultMongoUri = 'mongodb://127.0.0.1:27017/luna_uat';
const validNodeEnvironments: ReadonlySet<string> = new Set([
  'development',
  'test',
  'uat',
  'production',
]);

function parseBoolean(value: unknown, name: string, defaultValue: boolean): boolean {
  if (value === undefined || value === '') {
    return defaultValue;
  }

  if (value === 'true' || value === true) {
    return true;
  }

  if (value === 'false' || value === false) {
    return false;
  }

  throw new Error(`${name} must be true or false`);
}

export function validateEnvironment(config: Record<string, unknown>): Environment {
  const nodeEnvironment = (config.NODE_ENV ?? 'development') as string;

  if (!validNodeEnvironments.has(nodeEnvironment)) {
    throw new Error('NODE_ENV must be development, test, uat, or production');
  }

  const portValue = config.PORT ?? 3000;
  const port = typeof portValue === 'number' ? portValue : Number(portValue);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535');
  }

  const allowInsecureHttp = parseBoolean(
    config.ALLOW_INSECURE_HTTP,
    'ALLOW_INSECURE_HTTP',
    false,
  );
  if (nodeEnvironment === 'production' && allowInsecureHttp) {
    throw new Error('ALLOW_INSECURE_HTTP cannot be true in production');
  }
  const trustProxy = parseBoolean(config.TRUST_PROXY, 'TRUST_PROXY', false);

  const pepper = config.DEVICE_TOKEN_PEPPER;
  const deviceTokenPepper =
    typeof pepper === 'string' && pepper.trim().length > 0
      ? pepper
      : nodeEnvironment === 'test'
        ? 'test-device-token-pepper'
        : undefined;
  if (!deviceTokenPepper) {
    throw new Error('DEVICE_TOKEN_PEPPER is required');
  }

  const configuredMongoUri = config.MONGODB_URI;
  if (
    nodeEnvironment === 'production' &&
    (typeof configuredMongoUri !== 'string' || configuredMongoUri.trim().length === 0)
  ) {
    throw new Error('MONGODB_URI is required in production');
  }
  const mongoUri = configuredMongoUri ?? defaultMongoUri;
  if (typeof mongoUri !== 'string' || mongoUri.trim().length === 0) {
    throw new Error('MONGODB_URI must be a non-empty string');
  }

  const corsOrigins = config.CORS_ORIGINS ?? 'http://localhost:3000,http://localhost:5173';
  if (typeof corsOrigins !== 'string') {
    throw new Error('CORS_ORIGINS must be a comma-separated string');
  }

  const fcmServiceAccountJson = config.FCM_SERVICE_ACCOUNT_JSON;
  if (
    fcmServiceAccountJson !== undefined &&
    typeof fcmServiceAccountJson !== 'string'
  ) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON must be a string');
  }

  return {
    NODE_ENV: nodeEnvironment as NodeEnvironment,
    PORT: port,
    MONGODB_URI: mongoUri,
    DEVICE_TOKEN_PEPPER: deviceTokenPepper,
    ALLOW_INSECURE_HTTP: allowInsecureHttp,
    TRUST_PROXY: trustProxy,
    CORS_ORIGINS: corsOrigins,
    ...(fcmServiceAccountJson ? { FCM_SERVICE_ACCOUNT_JSON: fcmServiceAccountJson } : {}),
  };
}
