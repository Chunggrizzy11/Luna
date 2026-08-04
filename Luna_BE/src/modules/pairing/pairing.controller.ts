import {
  Body,
  Controller,
  Delete,
  Get,
  Post,
} from '@nestjs/common';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { JoinPairingDto } from './dto/join-pairing.dto';
import { PairingService, GenerateCodeResponse, PairingStatusResponse } from './pairing.service';

@Controller('pairing')
export class PairingController {
  constructor(private readonly pairingService: PairingService) {}

  @Post('code')
  async generateCode(
    @CurrentDevice() device: AuthenticatedDevice,
  ): Promise<GenerateCodeResponse> {
    return this.pairingService.generateCode(device);
  }

  @Post('join')
  async join(
    @CurrentDevice() device: AuthenticatedDevice,
    @Body() dto: JoinPairingDto,
  ): Promise<{ paired: boolean; ownerDeviceId: string }> {
    return this.pairingService.join(device, dto.code);
  }

  @Delete('unpair')
  async unpair(
    @CurrentDevice() device: AuthenticatedDevice,
  ): Promise<{ unpaired: boolean }> {
    return this.pairingService.unpair(device);
  }

  @Get('status')
  async getStatus(
    @CurrentDevice() device: AuthenticatedDevice,
  ): Promise<PairingStatusResponse> {
    return this.pairingService.getStatus(device);
  }
}