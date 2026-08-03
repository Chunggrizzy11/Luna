import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Matches, Max, Min } from 'class-validator';

const DATE_ONLY_MESSAGE = 'must be a yyyy-MM-dd date';

export class CycleQueryDto {
  @ApiPropertyOptional({ example: '2026-01-01', format: 'date' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: `from ${DATE_ONLY_MESSAGE}` })
  from?: string;

  @ApiPropertyOptional({ example: '2026-03-31', format: 'date' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: `to ${DATE_ONLY_MESSAGE}` })
  to?: string;

  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}

export class PredictionQueryDto {
  @ApiPropertyOptional({ example: '2026-03-12', format: 'date' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: `today ${DATE_ONLY_MESSAGE}` })
  today?: string;
}
