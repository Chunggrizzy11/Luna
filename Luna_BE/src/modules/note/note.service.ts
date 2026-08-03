import { Injectable } from '@nestjs/common';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DailyLogService } from '../health/daily-log.service';

export interface NoteResponse {
  date: string;
  note: string | null;
}

@Injectable()
export class NoteService {
  constructor(private readonly dailyLogService: DailyLogService) {}

  async get(owner: AuthenticatedDevice, date: string): Promise<NoteResponse> {
    const dailyLog = await this.dailyLogService.findByDate(owner, date);
    return { date, note: dailyLog?.note ?? null };
  }

  async update(
    owner: AuthenticatedDevice,
    date: string,
    note: string,
  ): Promise<NoteResponse> {
    const dailyLog = await this.dailyLogService.upsertFields(owner, date, {
      note,
    });
    return { date, note: dailyLog.note ?? null };
  }

  async remove(
    owner: AuthenticatedDevice,
    date: string,
  ): Promise<NoteResponse> {
    await this.dailyLogService.unsetFields(owner, date, ['note']);
    return { date, note: null };
  }
}
