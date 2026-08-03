import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { CalendarMonthQueryDto } from './dto/calendar-month-query.dto';
import { CalendarService } from './calendar.service';

@ApiTags('calendar')
@ApiBearerAuth()
@Controller('calendar')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Get()
  getMonth(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Query() query: CalendarMonthQueryDto,
  ) {
    return this.calendarService.getMonth(owner, query.month);
  }
}
