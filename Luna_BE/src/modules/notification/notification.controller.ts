import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { NotificationService, NotificationListResponse } from './notification.service';

@Controller('notifications')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  async list(
    @CurrentDevice() device: AuthenticatedDevice,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ): Promise<NotificationListResponse> {
    return this.notificationService.list(device, page, limit);
  }

  @Patch(':id/read')
  async markAsRead(
    @CurrentDevice() device: AuthenticatedDevice,
    @Param('id') id: string,
  ): Promise<void> {
    await this.notificationService.markAsRead(device, id);
  }

  @Patch('read-all')
  async markAllAsRead(@CurrentDevice() device: AuthenticatedDevice): Promise<void> {
    await this.notificationService.markAllAsRead(device);
  }
}
