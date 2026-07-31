import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import type { ApiErrorEnvelope } from '../interfaces/api-envelope.interface';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

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
      details: null,
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        `Unhandled HTTP ${status}: ${this.sanitizeForLog(exception)}`,
      );
    } else if (exception instanceof HttpException) {
      const exceptionResponse = exception.getResponse();
      if (typeof exceptionResponse === 'string') {
        error.message = exceptionResponse;
      } else {
        const details = (exceptionResponse as { message?: unknown }).message;
        error.details = details ?? null;
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

  private sanitizeForLog(exception: unknown): string {
    const value =
      exception instanceof HttpException
        ? exception.getResponse()
        : exception instanceof Error
          ? exception.message
          : exception;
    const raw = typeof value === 'string' ? value : JSON.stringify(value);

    return raw
      .replace(/mongodb(?:\+srv)?:\/\/[^\s'\"]+/gi, '[REDACTED_MONGODB_URI]')
      .replace(/\b(password|token|secret|pepper)\b\s*[:=]\s*[^,\s}]+/gi, '$1=[REDACTED]');
  }
}
