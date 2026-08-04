import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { Device, DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { Cycle, CycleSource } from '../cycle/schemas/cycle.schema';
import { DailyLog } from '../health/schemas/daily-log.schema';

export interface UserDataExport {
  device: {
    role: string;
    platform: string;
    deviceName?: string;
    exportedAt: string;
  };
  cycles: any[];
  dailyLogs: any[];
}

export interface ImportResult {
  imported: boolean;
  cyclesCount: number;
  dailyLogsCount: number;
}

@Injectable()
export class SettingsService {
  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<Device>,
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @InjectModel(DailyLog.name) private readonly dailyLogModel: Model<DailyLog>,
  ) {}

  async getDeviceInfo(device: AuthenticatedDevice): Promise<any> {
    const doc = await this.deviceModel.findById(device.deviceId).lean().exec();
    if (!doc) throw new NotFoundException('Device not found');
    return {
      id: String(doc._id),
      role: doc.role,
      platform: doc.platform,
      deviceName: doc.deviceName,
      status: doc.status,
      createdAt: (doc as any).createdAt,
    };
  }

  async exportUserData(device: AuthenticatedDevice): Promise<UserDataExport> {
    const doc = await this.deviceModel.findById(device.deviceId).lean().exec();
    if (!doc) throw new NotFoundException('Device not found');

    const ownerDeviceId = device.deviceId;
    const [cycles, dailyLogs] = await Promise.all([
      this.cycleModel.find({ ownerDeviceId }).lean().exec(),
      this.dailyLogModel.find({ ownerDeviceId }).lean().exec(),
    ]);

    return {
      device: {
        role: doc.role,
        platform: doc.platform,
        deviceName: doc.deviceName,
        exportedAt: new Date().toISOString(),
      },
      cycles: cycles.map((c) => ({
        startDate: c.startDate,
        endDate: c.endDate,
        periodLength: c.periodLength,
        cycleLength: c.cycleLength,
        source: c.source,
      })),
      dailyLogs: dailyLogs.map((l) => ({
        date: l.date,
        mood: l.mood,
        symptoms: l.symptoms,
        discomfortLevel: l.discomfortLevel,
        note: l.note,
      })),
    };
  }

  async importUserData(
    device: AuthenticatedDevice,
    data: UserDataExport,
  ): Promise<ImportResult> {
    if (device.role !== DeviceRole.OWNER) {
      throw new Error('Only owners can import data.');
    }

    let cyclesCount = 0;
    let dailyLogsCount = 0;

    // Import cycles
    for (const cycle of data.cycles) {
      await this.cycleModel.findOneAndUpdate(
        {
          ownerDeviceId: device.deviceId,
          startDate: cycle.startDate,
        },
        {
          ownerDeviceId: device.deviceId,
          startDate: cycle.startDate,
          endDate: cycle.endDate,
          periodLength: cycle.periodLength,
          cycleLength: cycle.cycleLength,
          source: CycleSource.MANUAL,
        },
        { upsert: true },
      );
      cyclesCount++;
    }

    // Import daily logs
    for (const log of data.dailyLogs) {
      await this.dailyLogModel.findOneAndUpdate(
        {
          ownerDeviceId: device.deviceId,
          date: log.date,
        },
        {
          ownerDeviceId: device.deviceId,
          date: log.date,
          mood: log.mood,
          symptoms: log.symptoms,
          discomfortLevel: log.discomfortLevel,
          note: log.note,
        },
        { upsert: true },
      );
      dailyLogsCount++;
    }

    return {
      imported: true,
      cyclesCount,
      dailyLogsCount,
    };
  }
}
