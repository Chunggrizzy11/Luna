import { Controller, Post } from '@nestjs/common';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { SosService } from './sos.service';

@Controller('sos')
export class SosController {
  constructor(private readonly sosService: SosService) {}

  @Post('trigger')
  async trigger(@CurrentDevice() device: AuthenticatedDevice): Promise<{ success: boolean }> {
    await this.sosService.trigger(device);
    return { success: true };
  }

  @Post('acknowledge')
  async acknowledge(@CurrentDevice() device: AuthenticatedDevice): Promise<{ success: boolean }> {
    await this.sosService.acknowledge(device);
    return { success: true };
  }
}
