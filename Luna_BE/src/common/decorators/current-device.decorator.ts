import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type {
  AuthenticatedDevice,
  AuthenticatedRequest,
} from '../interfaces/authenticated-device.interface';

export const CurrentDevice = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthenticatedDevice => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.currentDevice as AuthenticatedDevice;
  },
);
