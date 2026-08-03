import type { Request, Response } from 'express';
import { HttpException } from '@nestjs/common';
import {
  createTransportSecurityMiddleware,
  createTrustedProxyTrust,
} from './transport-security.middleware';

describe('createTransportSecurityMiddleware', () => {
  const errorStatus = (error: unknown): number => {
    if (!(error instanceof HttpException)) {
      throw new Error('Expected an HTTP exception');
    }

    return error.getStatus();
  };

  const createRequest = (options?: {
    encrypted?: boolean;
    forwardedProtocol?: string;
    remoteAddress?: string;
    secure?: boolean;
  }) =>
    ({
      socket: {
        ...(options?.encrypted ? { encrypted: true } : {}),
        ...(options?.remoteAddress
          ? { remoteAddress: options.remoteAddress }
          : {}),
      },
      headers: options?.forwardedProtocol
        ? { 'x-forwarded-proto': options.forwardedProtocol }
        : {},
      secure: options?.secure,
    }) as Request;

  const createResponse = () => ({}) as Response;

  it('rejects production plaintext and ignores spoofed forwarded headers without proxy trust', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustedProxy: undefined,
    });

    middleware(
      createRequest({ forwardedProtocol: 'https' }),
      createResponse(),
      next,
    );

    expect(errorStatus(receivedError)).toBe(426);
  });

  it('permits production direct TLS', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustedProxy: undefined,
    });

    middleware(createRequest({ encrypted: true }), createResponse(), next);

    expect(receivedError).toBeUndefined();
  });

  it('rejects production plaintext even when an invalid insecure flag bypasses validation', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: true,
      trustedProxy: undefined,
    });

    middleware(createRequest(), createResponse(), next);

    expect(errorStatus(receivedError)).toBe(426);
  });

  it('rejects forwarded HTTPS from an untrusted remote address', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustedProxy: createTrustedProxyTrust(['127.0.0.1']),
    });

    middleware(
      createRequest({
        forwardedProtocol: 'https',
        remoteAddress: '203.0.113.10',
        secure: true,
      }),
      createResponse(),
      next,
    );

    expect(errorStatus(receivedError)).toBe(426);
  });

  it('permits forwarded HTTPS from a trusted remote address', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'production',
      allowInsecureHttp: false,
      trustedProxy: createTrustedProxyTrust(['127.0.0.1']),
    });

    middleware(
      createRequest({
        forwardedProtocol: 'https',
        remoteAddress: '127.0.0.1',
        secure: true,
      }),
      createResponse(),
      next,
    );

    expect(receivedError).toBeUndefined();
  });

  it('permits insecure UAT only when ALLOW_INSECURE_HTTP is true', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'uat',
      allowInsecureHttp: true,
      trustedProxy: undefined,
    });

    middleware(createRequest(), createResponse(), next);

    expect(receivedError).toBeUndefined();
  });

  it('rejects insecure UAT when ALLOW_INSECURE_HTTP is false', () => {
    let receivedError: unknown;
    const next = (error?: unknown): void => {
      receivedError = error;
    };
    const middleware = createTransportSecurityMiddleware({
      nodeEnvironment: 'uat',
      allowInsecureHttp: false,
      trustedProxy: undefined,
    });

    middleware(createRequest(), createResponse(), next);

    expect(errorStatus(receivedError)).toBe(426);
  });
});
