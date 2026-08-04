import { Controller, Get, Query } from '@nestjs/common';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { StatisticsService } from './statistics.service';

@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('cycles')
  async getCycleStatistics(
    @CurrentDevice() device: AuthenticatedDevice,
  ) {
    return this.statisticsService.getCycleStatistics(device);
  }

  @Get('mood')
  async getMoodStatistics(
    @CurrentDevice() device: AuthenticatedDevice,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.statisticsService.getMoodStatistics(device, from, to);
  }
}
