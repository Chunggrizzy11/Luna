import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import { CalendarEnvelopeDto } from '../../common/dto/owner-health-api-response.dto';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { CalendarMonthQueryDto } from './dto/calendar-month-query.dto';
import { CalendarService } from './calendar.service';

@ApiTags('calendar')
@ApiBearerAuth()
@Controller('calendar')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Get()
  @ApiOkResponse({ type: CalendarEnvelopeDto })
  getMonth(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Query() query: CalendarMonthQueryDto,
  ) {
    return this.calendarService.getMonth(owner, query.month);
  }
}
