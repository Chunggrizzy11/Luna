import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { Mood } from '../../health/schemas/daily-log.schema';

export class UpdateMoodDto {
  @ApiProperty({ enum: Mood, example: Mood.HAPPY })
  @IsEnum(Mood)
  mood!: Mood;
}
