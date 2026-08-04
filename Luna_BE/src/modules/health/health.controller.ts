import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiExtraModels,
  ApiOkResponse,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import {
  CareEnvelopeDto,
  DashboardEnvelopeDto,
  JournalEnvelopeDto,
  OwnerDashboardDto,
  PartnerDashboardDto,
} from '../../common/dto/owner-health-api-response.dto';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { CareSuggestionService } from '../scheduler/care-suggestion.service';
import { DashboardService } from './dashboard.service';
import { DashboardQueryDto } from './dto/dashboard-query.dto';
import { JournalQueryDto } from './dto/journal-query.dto';
import { JournalService } from './journal.service';

@ApiTags('health')
@ApiBearerAuth()
@ApiExtraModels(OwnerDashboardDto, PartnerDashboardDto)
@Controller('health')
export class HealthController {
  constructor(
    private readonly dashboardService: DashboardService,
    private readonly careSuggestionService: CareSuggestionService,
    private readonly journalService: JournalService,
  ) {}

  @Get('dashboard')
  @ApiOkResponse({ type: DashboardEnvelopeDto })
  dashboard(
    @CurrentDevice() device: AuthenticatedDevice,
    @Query() query: DashboardQueryDto,
  ) {
    return this.dashboardService.getDashboard(device, query.date);
  }

  @Get('care/today')
  @ApiOkResponse({ type: CareEnvelopeDto })
  careToday(@CurrentDevice() device: AuthenticatedDevice) {
    return this.careSuggestionService.getToday(device);
  }

  @Get('journal')
  @ApiOkResponse({ type: JournalEnvelopeDto })
  journal(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Query() query: JournalQueryDto,
  ) {
    return this.journalService.list(owner, query);
  }
}
