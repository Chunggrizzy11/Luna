import { validateEnvironment } from './env.validation';

const validUat = {
  NODE_ENV: 'uat',
  DEVICE_TOKEN_PEPPER: 'unit-test-device-token-pepper',
};

describe('validateEnvironment', () => {
  it('rejects a deployable environment without DEVICE_TOKEN_PEPPER', () => {
    expect(() => validateEnvironment({ NODE_ENV: 'uat' })).toThrow(
      'DEVICE_TOKEN_PEPPER is required',
    );
  });

  it('rejects non-numeric PORT values', () => {
    expect(() =>
      validateEnvironment({ ...validUat, PORT: 'not-a-port' }),
    ).toThrow('PORT must be an integer between 1 and 65535');
  });

  it('rejects insecure HTTP in production', () => {
    expect(() =>
      validateEnvironment({
        ...validUat,
        NODE_ENV: 'production',
        ALLOW_INSECURE_HTTP: 'true',
      }),
    ).toThrow('ALLOW_INSECURE_HTTP cannot be true in production');
  });

  it('rejects production without an explicit MONGODB_URI', () => {
    expect(() =>
      validateEnvironment({
        NODE_ENV: 'production',
        DEVICE_TOKEN_PEPPER: 'unit-test-device-token-pepper',
      }),
    ).toThrow('MONGODB_URI is required in production');
  });

  it('rejects production proxy trust with an empty trusted proxy allowlist', () => {
    expect(() =>
      validateEnvironment({
        NODE_ENV: 'production',
        DEVICE_TOKEN_PEPPER: 'unit-test-device-token-pepper',
        MONGODB_URI: 'mongodb://db.internal/luna',
        TRUST_PROXY: 'true',
        TRUSTED_PROXY_IPS: ' , ',
      }),
    ).toThrow('TRUSTED_PROXY_IPS is required when TRUST_PROXY is true');
  });

  it('rejects invalid trusted proxy IP entries', () => {
    expect(() =>
      validateEnvironment({
        NODE_ENV: 'production',
        DEVICE_TOKEN_PEPPER: 'unit-test-device-token-pepper',
        MONGODB_URI: 'mongodb://db.internal/luna',
        TRUST_PROXY: 'true',
        TRUSTED_PROXY_IPS: 'not-an-ip',
      }),
    ).toThrow('TRUSTED_PROXY_IPS must contain valid IP addresses or CIDRs');
  });

  it('parses explicit trusted proxy IP and CIDR entries', () => {
    expect(
      validateEnvironment({
        NODE_ENV: 'production',
        DEVICE_TOKEN_PEPPER: 'unit-test-device-token-pepper',
        MONGODB_URI: 'mongodb://db.internal/luna',
        TRUST_PROXY: 'true',
        TRUSTED_PROXY_IPS: '127.0.0.1,10.0.0.0/8',
      }).TRUSTED_PROXY_IPS,
    ).toEqual(['127.0.0.1', '10.0.0.0/8']);
  });

  it('applies the UAT MongoDB default', () => {
    expect(validateEnvironment(validUat).MONGODB_URI).toBe(
      'mongodb://127.0.0.1:27017/luna_uat',
    );
  });
});
