import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { DeviceRole } from '../schemas/device.schema';

export class RegisterDeviceDto {
  @IsEnum(DeviceRole)
  role!: DeviceRole;

  @IsString()
  @MaxLength(32)
  platform!: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  pairId?: string;
}
