import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentDevice } from '../../common/decorators/current-device.decorator';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { UpdateSymptomsDto } from './dto/update-symptoms.dto';
import { SymptomService } from './symptom.service';

@ApiTags('symptoms')
@ApiBearerAuth()
@Controller('symptoms')
export class SymptomController {
  constructor(private readonly symptomService: SymptomService) {}

  @Get(':date')
  get(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
  ) {
    return this.symptomService.get(owner, date);
  }

  @Put(':date')
  update(
    @CurrentDevice() owner: AuthenticatedDevice,
    @Param('date') date: string,
    @Body() dto: UpdateSymptomsDto,
  ) {
    return this.symptomService.update(
      owner,
      date,
      dto.symptoms,
      dto.discomfortLevel,
    );
  }
}
