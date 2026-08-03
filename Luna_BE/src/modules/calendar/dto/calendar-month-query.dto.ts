import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class CalendarMonthQueryDto {
  @ApiProperty({ example: '2026-03', pattern: '^\\d{4}-\\d{2}$' })
  @Matches(/^\d{4}-\d{2}$/)
  month!: string;
}
