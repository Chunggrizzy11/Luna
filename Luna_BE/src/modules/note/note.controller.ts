import { Body, Controller, Delete, Get, Param, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import { NoteEnvelopeDto } from '../../common/dto/owner-health-api-response.dto';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { UpdateNoteDto } from './dto/update-note.dto';
import { NoteService } from './note.service';

@ApiTags('notes')
@ApiBearerAuth()
@Controller('notes')
export class NoteController {
  constructor(private readonly noteService: NoteService) {}

  @Get(':date')
  @ApiOkResponse({ type: NoteEnvelopeDto })
  get(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
  ) {
    return this.noteService.get(owner, date);
  }

  @Put(':date')
  @ApiOkResponse({ type: NoteEnvelopeDto })
  update(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
    @Body() dto: UpdateNoteDto,
  ) {
    return this.noteService.update(owner, date, dto.note);
  }

  @Delete(':date')
  @ApiOkResponse({ type: NoteEnvelopeDto })
  remove(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
  ) {
    return this.noteService.remove(owner, date);
  }
}
