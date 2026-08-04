import { Controller, Get, Post, Body, Delete } from '@nestjs/common';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get('device')
  async getDeviceInfo(
    @CurrentDevice() device: AuthenticatedDevice,
  ) {
    return this.settingsService.getDeviceInfo(device);
  }

  @Get('export')
  async exportData(
    @CurrentDevice() device: AuthenticatedDevice,
  ) {
    return this.settingsService.exportUserData(device);
  }

  @Post('import')
  async importData(
    @CurrentDevice() device: AuthenticatedDevice,
    @Body() data: any,
  ) {
    return this.settingsService.importUserData(device, data);
  }
}
