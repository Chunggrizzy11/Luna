import { ApiProperty } from '@nestjs/swagger';
import { ArrayUnique, IsArray, IsEnum, IsInt, Max, Min } from 'class-validator';
import { Symptom } from '../../health/schemas/daily-log.schema';

export class UpdateSymptomsDto {
  @ApiProperty({ enum: Symptom, isArray: true, example: [Symptom.CRAMPS] })
  @IsArray()
  @ArrayUnique()
  @IsEnum(Symptom, { each: true })
  symptoms!: Symptom[];

  @ApiProperty({ minimum: 0, maximum: 5, example: 3 })
  @IsInt()
  @Min(0)
  @Max(5)
  discomfortLevel!: number;
}
