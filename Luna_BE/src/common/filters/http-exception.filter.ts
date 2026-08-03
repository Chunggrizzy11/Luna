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
  private readonly sensitiveKeyPattern =
    /token|password|secret|authorization|fcm|pepper|pairing.?code|note/i;

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const response = context.getResponse<Response>();
    const request = context.getRequest<Request>();
    const status: number =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const statusName =
      typeof HttpStatus[status] === 'string' ? HttpStatus[status] : undefined;
    const fallbackMessage = statusName
      ? statusName
          .toLowerCase()
          .split('_')
          .map((word) => word[0].toUpperCase() + word.slice(1))
          .join(' ')
      : `HTTP ${status}`;
    const error: ApiErrorEnvelope = {
      code: statusName ?? `HTTP_${status}`,
      message: 'Internal server error',
      details: null,
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    if (status >= 500) {
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
        error.message = typeof details === 'string' ? details : fallbackMessage;
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
    const parsed = this.tryParseJson(value);
    const redacted = this.redactStructured(parsed, new WeakSet<object>());
    const raw =
      typeof redacted === 'string' ? redacted : this.stringifyForLog(redacted);

    return raw
      .replace(/mongodb(?:\+srv)?:\/\/[^\s'"]+/gi, '[REDACTED_MONGODB_URI]')
      .replace(
        /\b(password|token|secret|authorization|fcm(?:token)?|pepper|pairing.?code|note)\b\s*[:=]\s*[^,\s}\]]+/gi,
        '$1=[REDACTED]',
      );
  }

  private tryParseJson(value: unknown): unknown {
    if (typeof value !== 'string') return value;

    try {
      return JSON.parse(value) as unknown;
    } catch {
      return value;
    }
  }

  private redactStructured(value: unknown, seen: WeakSet<object>): unknown {
    if (typeof value === 'string') {
      const parsed = this.tryParseJson(value);
      return parsed === value ? value : this.redactStructured(parsed, seen);
    }
    if (value === null || typeof value !== 'object') return value;
    if (seen.has(value)) return '[CIRCULAR]';
    seen.add(value);

    if (Array.isArray(value)) {
      return value.map((item) => this.redactStructured(item, seen));
    }

    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [
        key,
        this.sensitiveKeyPattern.test(key)
          ? '[REDACTED]'
          : this.redactStructured(item, seen),
      ]),
    );
  }

  private stringifyForLog(value: unknown): string {
    try {
      return JSON.stringify(value);
    } catch {
      return '[UNSERIALIZABLE_ERROR]';
    }
  }
}
