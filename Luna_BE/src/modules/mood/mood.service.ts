import { Injectable } from '@nestjs/common';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DailyLogService } from '../health/daily-log.service';
import { Mood } from '../health/schemas/daily-log.schema';

export interface MoodResponse {
  date: string;
  mood: Mood | null;
}

@Injectable()
export class MoodService {
  constructor(private readonly dailyLogService: DailyLogService) {}

  async get(owner: AuthenticatedDevice, date: string): Promise<MoodResponse> {
    const dailyLog = await this.dailyLogService.findByDate(owner, date);
    return { date, mood: dailyLog?.mood ?? null };
  }

  async update(
    owner: AuthenticatedDevice,
    date: string,
    mood: Mood,
  ): Promise<MoodResponse> {
    const dailyLog = await this.dailyLogService.upsertFields(owner, date, {
      mood,
    });
    return { date, mood: dailyLog.mood ?? null };
  }
}
