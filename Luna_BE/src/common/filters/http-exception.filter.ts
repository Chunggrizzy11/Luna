import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import type { ApiErrorEnvelope } from '../interfaces/api-envelope.interface';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const response = context.getResponse<Response>();
    const request = context.getRequest<Request>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const error: ApiErrorEnvelope = {
      code: HttpStatus[status] ?? 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error',
      details: undefined,
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    if (exception instanceof HttpException) {
      const exceptionResponse = exception.getResponse();
      if (typeof exceptionResponse === 'string') {
        error.message = exceptionResponse;
      } else {
        const details = (exceptionResponse as { message?: unknown }).message;
        error.details = details;
        error.message =
          typeof details === 'string'
            ? details
            : HttpStatus[status]
                .toLowerCase()
                .split('_')
                .map((word) => word[0].toUpperCase() + word.slice(1))
                .join(' ');
      }
    }

    response.status(status).json(error);
  }
}
