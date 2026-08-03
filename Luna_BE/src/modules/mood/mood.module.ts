import { Module } from '@nestjs/common';
import { HealthModule } from '../health/health.module';
import { MoodController } from './mood.controller';
import { MoodService } from './mood.service';

@Module({
  imports: [HealthModule],
  controllers: [MoodController],
  providers: [MoodService],
})
export class MoodModule {}
