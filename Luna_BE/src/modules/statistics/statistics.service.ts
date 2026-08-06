import { Injectable, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DeviceRole } from '../device/schemas/device.schema';
import { DeviceService } from '../device/device.service';
import { Device } from '../device/schemas/device.schema';
import { Cycle } from '../cycle/schemas/cycle.schema';
import { DailyLog } from '../health/schemas/daily-log.schema';

export interface CycleStatisticsResponse {
  totalCycles: number;
  averageCycleLength: number | null;
  shortestCycle: number | null;
  longestCycle: number | null;
  averagePeriodLength: number | null;
  cycleLengthHistory: { cycleNumber: number; length: number }[];
  periodLengthHistory: { cycleNumber: number; length: number }[];
}

export interface MoodStatisticsResponse {
  moodCounts: { mood: string; count: number }[];
  averageDiscomfort: number | null;
  totalEntries: number;
}

@Injectable()
export class StatisticsService {
  constructor(
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @InjectModel(DailyLog.name) private readonly dailyLogModel: Model<DailyLog>,
    @InjectModel(Device.name) private readonly deviceModel: Model<Device>,
    private readonly deviceService: DeviceService,
  ) {}

  async getCycleStatistics(
    device: AuthenticatedDevice,
  ): Promise<CycleStatisticsResponse> {
    const ownerDeviceId = await this.deviceService.resolveOwnerId(device);

    const cycles = await this.cycleModel
      .find({ ownerDeviceId })
      .sort({ startDate: 1 })
      .lean()
      .exec();

    const cycleLengths = cycles
      .filter((c) => c.cycleLength != null && c.cycleLength > 0)
      .map((c) => c.cycleLength as number);

    const periodLengths = cycles
      .filter((c) => c.periodLength != null && c.periodLength > 0)
      .map((c) => c.periodLength as number);

    return {
      totalCycles: cycles.length,
      averageCycleLength: this.average(cycleLengths),
      shortestCycle: cycleLengths.length > 0 ? Math.min(...cycleLengths) : null,
      longestCycle: cycleLengths.length > 0 ? Math.max(...cycleLengths) : null,
      averagePeriodLength: this.average(periodLengths),
      cycleLengthHistory: cycles.map((c, i) => ({
        cycleNumber: i + 1,
        length: c.cycleLength ?? 0,
      })).filter((c) => c.length > 0),
      periodLengthHistory: cycles.map((c, i) => ({
        cycleNumber: i + 1,
        length: c.periodLength ?? 0,
      })).filter((c) => c.length > 0),
    };
  }

  async getMoodStatistics(
    device: AuthenticatedDevice,
    from?: string,
    to?: string,
  ): Promise<MoodStatisticsResponse> {
    const ownerDeviceId = await this.deviceService.resolveOwnerId(device);
    const filter: any = { ownerDeviceId };
    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = from;
      if (to) filter.date.$lte = to;
    }

    const logs = await this.dailyLogModel
      .find(filter)
      .select('mood discomfortLevel')
      .lean()
      .exec();

    const moodCounts: Record<string, number> = {};
    let totalDiscomfort = 0;
    let discomfortCount = 0;

    for (const log of logs) {
      if (log.mood) {
        moodCounts[log.mood] = (moodCounts[log.mood] || 0) + 1;
      }
      if (log.discomfortLevel != null) {
        totalDiscomfort += log.discomfortLevel;
        discomfortCount++;
      }
    }

    return {
      moodCounts: Object.entries(moodCounts)
        .map(([mood, count]) => ({ mood, count }))
        .sort((a, b) => b.count - a.count),
      averageDiscomfort:
        discomfortCount > 0 ? totalDiscomfort / discomfortCount : null,
      totalEntries: logs.length,
    };
  }

  private average(values: number[]): number | null {
    if (values.length === 0) return null;
    return values.reduce((a, b) => a + b, 0) / values.length;
  }
}
