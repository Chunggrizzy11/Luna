import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import { MoodEnvelopeDto } from '../../common/dto/owner-health-api-response.dto';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { UpdateMoodDto } from './dto/update-mood.dto';
import { MoodService } from './mood.service';

@ApiTags('moods')
@ApiBearerAuth()
@Controller('moods')
export class MoodController {
  constructor(private readonly moodService: MoodService) {}

  @Get(':date')
  @ApiOkResponse({ type: MoodEnvelopeDto })
  get(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
  ) {
    return this.moodService.get(owner, date);
  }

  @Put(':date')
  @ApiOkResponse({ type: MoodEnvelopeDto })
  update(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
    @Body() dto: UpdateMoodDto,
  ) {
    return this.moodService.update(owner, date, dto.mood);
  }
}
