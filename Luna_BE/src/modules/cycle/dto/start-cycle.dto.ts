import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class StartCycleDto {
  @ApiProperty({ example: '2026-03-01', format: 'date' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'date must be a yyyy-MM-dd date',
  })
  date!: string;
}
