import { IsString, MaxLength } from 'class-validator';

export class PushTokenDto {
  @IsString()
  @MaxLength(4096)
  fcmToken!: string;
}
