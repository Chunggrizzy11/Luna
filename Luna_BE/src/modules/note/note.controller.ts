import { Body, Controller, Delete, Get, Param, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { UpdateNoteDto } from './dto/update-note.dto';
import { NoteService } from './note.service';

@ApiTags('notes')
@ApiBearerAuth()
@Controller('notes')
export class NoteController {
  constructor(private readonly noteService: NoteService) {}

  @Get(':date')
  get(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
  ) {
    return this.noteService.get(owner, date);
  }

  @Put(':date')
  update(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
    @Body() dto: UpdateNoteDto,
  ) {
    return this.noteService.update(owner, date, dto.note);
  }

  @Delete(':date')
  remove(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
  ) {
    return this.noteService.remove(owner, date);
  }
}
