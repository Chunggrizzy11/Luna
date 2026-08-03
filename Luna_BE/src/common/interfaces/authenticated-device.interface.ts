import type { Request } from 'express';
import type {
  DeviceRole,
  DeviceStatus,
} from '../../modules/device/schemas/device.schema';

export interface AuthenticatedDevice {
  deviceId: string;
  role: DeviceRole;
  status: DeviceStatus;
  pairId?: string;
}

export interface AuthenticatedRequest extends Request {
  currentDevice?: AuthenticatedDevice;
}
