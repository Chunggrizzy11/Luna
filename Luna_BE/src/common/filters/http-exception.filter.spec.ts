import {
  BadRequestException,
  HttpException,
  HttpStatus,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import type { ArgumentsHost } from '@nestjs/common';
import { HttpExceptionFilter } from './http-exception.filter';

describe('HttpExceptionFilter', () => {
  let loggerError: jest.SpyInstance;
  let loggedErrors: string[];

  beforeEach(() => {
    loggedErrors = [];
    loggerError = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation((message: unknown) => {
        loggedErrors.push(String(message));
      });
  });

  afterEach(() => {
    loggerError.mockRestore();
  });

  const createHost = (path: string) => {
    let responseBody: unknown;
    let responseStatus: number | undefined;
    const json = (body: unknown): void => {
      responseBody = body;
    };
    const status = (statusCode: number): { json: typeof json } => {
      responseStatus = statusCode;
      return { json };
    };

    return {
      host: {
        switchToHttp: () => ({
          getRequest: () => ({ url: path }),
          getResponse: () => ({ status, json }),
        }),
      } as ArgumentsHost,
      getResponseBody: () => responseBody,
      getResponseStatus: () => responseStatus,
    };
  };

  it('serializes HttpException details in the standard error envelope', () => {
    const { host, getResponseBody, getResponseStatus } =
      createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();

    filter.catch(
      new BadRequestException({ message: ['role must be valid'] }),
      host,
    );

    expect(getResponseStatus()).toBe(HttpStatus.BAD_REQUEST);
    expect(getResponseBody()).toEqual(
      expect.objectContaining({
        code: 'BAD_REQUEST',
        message: 'Bad Request',
        details: ['role must be valid'],
        path: '/api/v1/devices',
      }),
    );
    expect(
      typeof (getResponseBody() as { timestamp?: unknown }).timestamp,
    ).toBe('string');
  });

  it('does not expose unexpected error details', () => {
    const { host, getResponseBody, getResponseStatus } =
      createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();

    filter.catch(new Error('database password leaked'), host);

    expect(getResponseStatus()).toBe(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(getResponseBody()).toEqual(
      expect.objectContaining({
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Internal server error',
        details: null,
        path: '/api/v1/devices',
      }),
    );
    expect(
      typeof (getResponseBody() as { timestamp?: unknown }).timestamp,
    ).toBe('string');

    const serialized = JSON.stringify(getResponseBody());
    expect(JSON.parse(serialized)).toEqual(
      expect.objectContaining({ details: null }),
    );
  });

  it('does not expose 5xx HttpException details through JSON responses', () => {
    const { host, getResponseBody, getResponseStatus } =
      createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();
    const internalDetails =
      'Error: mongodb://luna_app:password@db.internal/luna_uat';

    filter.catch(
      new InternalServerErrorException({ message: internalDetails }),
      host,
    );

    expect(getResponseStatus()).toBe(HttpStatus.INTERNAL_SERVER_ERROR);
    const serialized = JSON.stringify(getResponseBody());
    expect(serialized).toContain('"details":null');
    expect(serialized).not.toContain(internalDetails);
    expect(serialized).toContain('Internal server error');
    expect(loggerError).toHaveBeenCalledWith(
      expect.stringContaining('[REDACTED_MONGODB_URI]'),
    );
    expect(loggerError).not.toHaveBeenCalledWith(
      expect.stringContaining(internalDetails),
    );
  });

  it('serializes a non-enum HTTP status without throwing', () => {
    const { host, getResponseBody, getResponseStatus } =
      createHost('/api/v1/devices/me');
    const filter = new HttpExceptionFilter();

    expect(() =>
      filter.catch(
        new HttpException({ message: ['Client closed request'] }, 499),
        host,
      ),
    ).not.toThrow();

    expect(getResponseStatus()).toBe(499);
    expect(getResponseBody()).toEqual(
      expect.objectContaining({
        code: 'HTTP_499',
        message: 'HTTP 499',
        details: ['Client closed request'],
        path: '/api/v1/devices/me',
      }),
    );
  });

  it('recursively redacts structured secrets from 5xx logs', () => {
    const { host } = createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();
    const secrets = [
      'token-value',
      'password-value',
      'secret-value',
      'authorization-value',
      'fcm-value',
    ];

    filter.catch(
      new InternalServerErrorException({
        message: 'push provider failed',
        token: secrets[0],
        nested: {
          password: secrets[1],
          items: [
            { clientSecret: secrets[2] },
            { Authorization: secrets[3] },
            { fcmToken: secrets[4] },
          ],
        },
      }),
      host,
    );

    const log = loggedErrors[0] ?? '';
    expect(log).toContain('[REDACTED]');
    for (const secret of secrets) {
      expect(log).not.toContain(secret);
    }
  });

  it('redacts quoted JSON secrets carried in an error message', () => {
    const { host } = createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();

    filter.catch(
      new Error(
        '{"token":"json-token-secret","items":[{"fcmToken":"json-fcm-secret"}]}',
      ),
      host,
    );

    const log = loggedErrors[0] ?? '';
    expect(log).not.toContain('json-token-secret');
    expect(log).not.toContain('json-fcm-secret');
    expect(log).toContain('[REDACTED]');
  });
});
