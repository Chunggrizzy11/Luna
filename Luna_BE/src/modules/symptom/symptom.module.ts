import { Module } from '@nestjs/common';
import { HealthModule } from '../health/health.module';
import { SymptomController } from './symptom.controller';
import { SymptomService } from './symptom.service';

@Module({
  imports: [HealthModule],
  controllers: [SymptomController],
  providers: [SymptomService],
})
export class SymptomModule {}
