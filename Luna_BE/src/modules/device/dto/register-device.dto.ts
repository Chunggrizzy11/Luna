import { IsOptional, IsString, MaxLength } from 'class-validator';

export class RegisterDeviceDto {
  @IsString()
  @MaxLength(32)
  platform!: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}
