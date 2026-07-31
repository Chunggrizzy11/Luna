import { BadRequestException, HttpStatus } from '@nestjs/common';
import type { ArgumentsHost } from '@nestjs/common';
import { HttpExceptionFilter } from './http-exception.filter';

describe('HttpExceptionFilter', () => {
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
        details: undefined,
        path: '/api/v1/devices',
        timestamp: expect.any(String),
      }),
    );
  });
});
