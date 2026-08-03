import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class EndCycleDto {
  @ApiProperty({ example: '2026-03-05', format: 'date' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'date must be a yyyy-MM-dd date',
  })
  date!: string;
}
