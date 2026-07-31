import { HttpException } from '@nestjs/common';
import type { NextFunction, Request, RequestHandler, Response } from 'express';
import type { TLSSocket } from 'node:tls';
import proxyaddr from 'proxy-addr';
import type { NodeEnvironment } from '../../config/env.validation';

export type TrustedProxy = (address: string, index: number) => boolean;

export interface TransportSecurityOptions {
  nodeEnvironment: NodeEnvironment;
  allowInsecureHttp: boolean;
  trustedProxy?: TrustedProxy;
}

export function createTrustedProxyTrust(
  trustedProxyIps: string[],
): TrustedProxy {
  return proxyaddr.compile(trustedProxyIps);
}

function hasDirectTls(request: Request): boolean {
  return (request.socket as TLSSocket).encrypted === true;
}

function hasTrustedProxyTls(
  request: Request,
  trustedProxy: TrustedProxy | undefined,
): boolean {
  const remoteAddress = request.socket.remoteAddress;
  if (!trustedProxy || !remoteAddress || !trustedProxy(remoteAddress, 0)) {
    return false;
  }

  return request.secure === true;
}

function isSecureTransport(
  request: Request,
  trustedProxy: TrustedProxy | undefined,
): boolean {
  return hasDirectTls(request) || hasTrustedProxyTls(request, trustedProxy);
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
      isSecureTransport(request, options.trustedProxy) ||
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
