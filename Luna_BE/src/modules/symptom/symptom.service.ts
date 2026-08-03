import { Injectable } from '@nestjs/common';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DailyLogService } from '../health/daily-log.service';
import { Symptom } from '../health/schemas/daily-log.schema';

export interface SymptomResponse {
  date: string;
  symptoms: Symptom[];
  discomfortLevel: number | null;
}

@Injectable()
export class SymptomService {
  constructor(private readonly dailyLogService: DailyLogService) {}

  async get(
    owner: AuthenticatedDevice,
    date: string,
  ): Promise<SymptomResponse> {
    const dailyLog = await this.dailyLogService.findByDate(owner, date);
    return {
      date,
      symptoms: dailyLog?.symptoms ?? [],
      discomfortLevel: dailyLog?.discomfortLevel ?? null,
    };
  }

  async update(
    owner: AuthenticatedDevice,
    date: string,
    symptoms: Symptom[],
    discomfortLevel: number,
  ): Promise<SymptomResponse> {
    const dailyLog = await this.dailyLogService.upsertFields(owner, date, {
      symptoms,
      discomfortLevel,
    });
    return {
      date,
      symptoms: dailyLog.symptoms ?? [],
      discomfortLevel: dailyLog.discomfortLevel ?? null,
    };
  }
}
