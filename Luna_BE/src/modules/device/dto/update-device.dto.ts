import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export class UpdateDeviceDto {
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsString()
  @Matches(/\S/)
  @MaxLength(32)
  platform?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}
