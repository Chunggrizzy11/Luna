import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { BusinessDateClock } from '../../common/date/business-date';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import {
  CycleEnvelopeDto,
  CycleListEnvelopeDto,
  CycleSummaryEnvelopeDto,
  NullableCycleEnvelopeDto,
} from '../../common/dto/owner-health-api-response.dto';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { CycleQueryDto, PredictionQueryDto } from './dto/cycle-query.dto';
import { EndCycleDto } from './dto/end-cycle.dto';
import { StartCycleDto } from './dto/start-cycle.dto';
import { CycleService } from './cycle.service';

@ApiTags('cycles')
@ApiBearerAuth()
@Controller('cycles')
export class CycleController {
  constructor(
    private readonly cycleService: CycleService,
    private readonly businessDate: BusinessDateClock,
  ) {}

  @Post('start')
  @ApiOperation({ summary: 'Start a menstrual cycle' })
  @ApiCreatedResponse({ type: CycleEnvelopeDto })
  @ApiConflictResponse({ description: 'An active cycle already exists.' })
  @ApiForbiddenResponse({
    description: 'Partner devices cannot access cycles.',
  })
  start(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Body() dto: StartCycleDto,
  ) {
    return this.cycleService.start(owner, dto.date);
  }

  @Post('end')
  @ApiOperation({ summary: 'End the current menstrual cycle' })
  @ApiCreatedResponse({ type: CycleEnvelopeDto })
  @ApiNotFoundResponse({ description: 'No active cycle exists.' })
  @ApiConflictResponse({
    description: 'The end date is before the start date.',
  })
  @ApiForbiddenResponse({
    description: 'Partner devices cannot access cycles.',
  })
  end(@CurrentDevice() owner: AuthenticatedDevice, @Body() dto: EndCycleDto) {
    return this.cycleService.end(owner, dto.date);
  }

  @Get()
  @ApiOperation({ summary: 'List cycle history for the owner' })
  @ApiOkResponse({
    type: CycleListEnvelopeDto,
    description: 'Newest-first, paginated cycle history.',
  })
  @ApiForbiddenResponse({
    description: 'Partner devices cannot access cycles.',
  })
  list(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Query() query: CycleQueryDto,
  ) {
    return this.cycleService.list(owner, query);
  }

  @Get('current')
  @ApiOperation({ summary: 'Get the active cycle, or null when none exists' })
  @ApiOkResponse({
    type: NullableCycleEnvelopeDto,
    description: 'Returns nullable data when no active cycle exists.',
  })
  @ApiForbiddenResponse({
    description: 'Partner devices cannot access cycles.',
  })
  current(@CurrentDevice() owner: AuthenticatedDevice) {
    return this.cycleService.findCurrent(owner);
  }

  @Get('prediction')
  @ApiOperation({ summary: 'Calculate cycle predictions for a date' })
  @ApiOkResponse({ type: CycleSummaryEnvelopeDto })
  @ApiForbiddenResponse({
    description: 'Partner devices cannot access cycles.',
  })
  prediction(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Query() query: PredictionQueryDto,
  ) {
    const today = query.today ?? this.businessDate.today();
    return this.cycleService.prediction(owner, today);
  }
}
