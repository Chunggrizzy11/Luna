import { HttpException } from '@nestjs/common';
import type { NextFunction, Request, RequestHandler, Response } from 'express';
import type { TLSSocket } from 'node:tls';
import type { NodeEnvironment } from '../../config/env.validation';

export interface TransportSecurityOptions {
  nodeEnvironment: NodeEnvironment;
  allowInsecureHttp: boolean;
  trustProxy: boolean;
}

function hasDirectTls(request: Request): boolean {
  return (request.socket as TLSSocket).encrypted === true;
}

function hasTrustedForwardedTls(
  request: Request,
  trustProxy: boolean,
): boolean {
  if (!trustProxy) {
    return false;
  }

  const header = request.headers['x-forwarded-proto'];
  const forwardedProtocol = Array.isArray(header) ? header[0] : header;

  return forwardedProtocol?.split(',')[0].trim().toLowerCase() === 'https';
}

function isSecureTransport(
  request: Request,
  trustProxy: boolean,
): boolean {
  return hasDirectTls(request) || hasTrustedForwardedTls(request, trustProxy);
}

export function createTransportSecurityMiddleware(
  options: TransportSecurityOptions,
): RequestHandler {
  return (
    request: Request,
    _response: Response,
    next: NextFunction,
  ): void => {
    if (
      isSecureTransport(request, options.trustProxy) ||
      (options.nodeEnvironment !== 'production' && options.allowInsecureHttp)
    ) {
      next();
      return;
    }

    next(
      new HttpException(
        'HTTPS is required for this environment',
        426,
      ),
    );
  };
}
