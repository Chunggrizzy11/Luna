import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength } from 'class-validator';

export class UpdateNoteDto {
  @ApiProperty({ example: 'Resting helped today.' })
  @IsString()
  @MaxLength(4000)
  note!: string;
}
