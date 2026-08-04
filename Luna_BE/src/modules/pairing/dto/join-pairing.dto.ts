import { IsString, Length, Matches } from 'class-validator';

export class JoinPairingDto {
  @IsString()
  @Length(8, 8, { message: 'Pairing code must be 8 characters.' })
  @Matches(/^[A-Z0-9]+$/, { message: 'Pairing code must be uppercase alphanumeric.' })
  code!: string;
}