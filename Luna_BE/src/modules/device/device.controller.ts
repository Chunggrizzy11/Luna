import { Body, Controller, Delete, Get, Patch, Post } from '@nestjs/common';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import { Public } from '../../common/decorators/public.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { PushTokenDto } from './dto/push-token.dto';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';
import { DeviceService } from './device.service';

@Controller('devices')
export class DeviceController {
  constructor(private readonly deviceService: DeviceService) {}

  @Public()
  @Post('register')
  register(@Body() dto: RegisterDeviceDto) {
    return this.deviceService.register(dto);
  }

  @Get('me')
  getMe(@CurrentDevice() device: AuthenticatedDevice): AuthenticatedDevice {
    return device;
  }

  @Patch('me')
  async updateMe(
    @CurrentDevice() device: AuthenticatedDevice,
    @Body() dto: UpdateDeviceDto,
  ): Promise<void> {
    await this.deviceService.update(device.deviceId, dto);
  }

  @Post('push-token')
  async updatePushToken(
    @CurrentDevice() device: AuthenticatedDevice,
    @Body() dto: PushTokenDto,
  ): Promise<void> {
    await this.deviceService.updatePushToken(device.deviceId, dto);
  }

  @Delete('me')
  async revokeMe(@CurrentDevice() device: AuthenticatedDevice): Promise<void> {
    await this.deviceService.revoke(device.deviceId);
  }
}
