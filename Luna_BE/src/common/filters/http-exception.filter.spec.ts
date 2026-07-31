import {
  BadRequestException,
  HttpStatus,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import type { ArgumentsHost } from '@nestjs/common';
import { HttpExceptionFilter } from './http-exception.filter';

describe('HttpExceptionFilter', () => {
  let loggerError: jest.SpyInstance;

  beforeEach(() => {
    loggerError = jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });

  afterEach(() => {
    loggerError.mockRestore();
  });

  const createHost = (path: string) => {
    const status = jest.fn();
    const json = jest.fn();
    status.mockReturnValue({ json });

    return {
      host: {
        switchToHttp: () => ({
          getRequest: () => ({ url: path }),
          getResponse: () => ({ status, json }),
        }),
      } as ArgumentsHost,
      status,
      json,
    };
  };

  it('serializes HttpException details in the standard error envelope', () => {
    const { host, status, json } = createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();

    filter.catch(
      new BadRequestException({ message: ['role must be valid'] }),
      host,
    );

    expect(status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'BAD_REQUEST',
        message: 'Bad Request',
        details: ['role must be valid'],
        path: '/api/v1/devices',
        timestamp: expect.any(String),
      }),
    );
  });

  it('does not expose unexpected error details', () => {
    const { host, status, json } = createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();

    filter.catch(new Error('database password leaked'), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Internal server error',
        details: null,
        path: '/api/v1/devices',
        timestamp: expect.any(String),
      }),
    );

    const serialized = JSON.stringify(json.mock.calls[0][0]);
    expect(JSON.parse(serialized)).toEqual(
      expect.objectContaining({ details: null }),
    );
  });

  it('does not expose 5xx HttpException details through JSON responses', () => {
    const { host, status, json } = createHost('/api/v1/devices');
    const filter = new HttpExceptionFilter();
    const internalDetails =
      'Error: mongodb://luna_app:password@db.internal/luna_uat';

    filter.catch(
      new InternalServerErrorException({ message: internalDetails }),
      host,
    );

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    const serialized = JSON.stringify(json.mock.calls[0][0]);
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
});
