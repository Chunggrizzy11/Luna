import { Module } from '@nestjs/common';
import { HealthModule } from '../health/health.module';
import { NoteController } from './note.controller';
import { NoteService } from './note.service';

@Module({
  imports: [HealthModule],
  controllers: [NoteController],
  providers: [NoteService],
})
export class NoteModule {}
