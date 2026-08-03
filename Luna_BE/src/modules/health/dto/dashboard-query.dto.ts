import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class DashboardQueryDto {
  @ApiProperty({ example: '2026-03-12', format: 'date' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date!: string;
}
