import { validateEnvironment } from './env.validation';

const validUat = {
  NODE_ENV: 'uat',
  DEVICE_TOKEN_PEPPER: 'unit-test-device-token-pepper',
};

describe('validateEnvironment', () => {
  it('rejects a deployable environment without DEVICE_TOKEN_PEPPER', () => {
    expect(() =>
      validateEnvironment({ NODE_ENV: 'uat' }),
    ).toThrow('DEVICE_TOKEN_PEPPER is required');
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

  it('applies the UAT MongoDB default', () => {
    expect(validateEnvironment(validUat).MONGODB_URI).toBe(
      'mongodb://127.0.0.1:27017/luna_uat',
    );
  });
});
