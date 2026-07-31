import type { Request, Response } from 'express';
import { createTransportSecurityMiddleware } from './transport-security.middleware';

describe('createTransportSecurityMiddleware', () => {
  const createRequest = (options?: {
    encrypted?: boolean;
    forwardedProtocol?: string;
  }) =>
    ({
      socket: options?.encrypted ? { encrypted: true } : {},
      headers: options?.forwardedProtocol
        ? { 'x-forwarded-proto': options.forwardedProtocol }
        : {},
    }) as Request;

  const createResponse = () => ({}) as Response;

  it('rejects production plaintext and ignores spoofed forwarded headers without proxy trust', () => {
    const next = jest.fn();
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustProxy: false,
    });

    middleware(
      createRequest({ forwardedProtocol: 'https' }),
      createResponse(),
      next,
    );

    expect(next).toHaveBeenCalledTimes(1);
    expect(next.mock.calls[0][0].getStatus()).toBe(426);
  });

  it('permits production direct TLS', () => {
    const next = jest.fn();
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustProxy: false,
    });

    middleware(createRequest({ encrypted: true }), createResponse(), next);

    expect(next).toHaveBeenCalledWith();
  });

  it('rejects production plaintext even when an invalid insecure flag bypasses validation', () => {
    const next = jest.fn();
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: true,
      trustProxy: false,
    });

    middleware(createRequest(), createResponse(), next);

    expect(next.mock.calls[0][0].getStatus()).toBe(426);
  });

  it('permits forwarded HTTPS only when reverse-proxy trust is enabled', () => {
    const next = jest.fn();
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustProxy: true,
    });

    middleware(
      createRequest({ forwardedProtocol: 'https' }),
      createResponse(),
      next,
    );

    expect(next).toHaveBeenCalledWith();
  });

  it('permits insecure UAT only when ALLOW_INSECURE_HTTP is true', () => {
    const next = jest.fn();
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'uat',
      allowInsecureHttp: true,
      trustProxy: false,
    });

    middleware(createRequest(), createResponse(), next);

    expect(next).toHaveBeenCalledWith();
  });

  it('rejects insecure UAT when ALLOW_INSECURE_HTTP is false', () => {
    const next = jest.fn();
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'uat',
      allowInsecureHttp: false,
      trustProxy: false,
    });

    middleware(createRequest(), createResponse(), next);

    expect(next.mock.calls[0][0].getStatus()).toBe(426);
  });
});
