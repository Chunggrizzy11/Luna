import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { calculateCycleSummary } from '../cycle/cycle-calculator.service';
import {
  CYCLE_SETTINGS_PROVIDER,
  type CycleSettingsProvider,
} from '../cycle/cycle.service';
import { Cycle } from '../cycle/schemas/cycle.schema';
import type { CycleSummary } from '../cycle/cycle.types';
import {
  Device,
  DeviceRole,
  DeviceStatus,
} from '../device/schemas/device.schema';
import { DailyLog } from './schemas/daily-log.schema';

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

export type CareAudience = 'owner' | 'partner';

export interface AudienceResolution {
  audience: CareAudience;
  relationship: 'owner' | 'paired' | 'unpaired';
  pairId?: string;
  ownerDeviceId?: string;
}

export interface OwnerDashboardResponse {
  date: string;
  relationship: 'owner';
  cycle: CycleSummary;
  dailyLog: {
    mood: string | null;
    symptoms: string[];
    discomfortLevel: number | null;
    note: string | null;
  };
}

export interface PartnerDashboardResponse {
  date: string;
  relationship: 'paired' | 'unpaired';
  cycle: {
    currentCycleDay: number | null;
    isPeriodActive: boolean;
    daysUntilNextPeriod: number | null;
    predictedPeriodStart: string | null;
    predictedPeriodEnd: string | null;
  } | null;
  discomfortLevel: number | null;
}

@Injectable()
export class DashboardService {
  constructor(
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @InjectModel(DailyLog.name) private readonly dailyLogModel: Model<DailyLog>,
    @InjectModel(Device.name) private readonly deviceModel: Model<Device>,
    @Inject(CYCLE_SETTINGS_PROVIDER)
    private readonly settingsProvider: CycleSettingsProvider,
  ) {}

  async getDashboard(
    device: AuthenticatedDevice,
    date: string,
  ): Promise<OwnerDashboardResponse | PartnerDashboardResponse> {
    const normalizedDate = this.assertDateOnly(date);
    const audience = await this.resolveAudience(device);
    if (audience.relationship === 'unpaired') {
      return {
        date: normalizedDate,
        relationship: 'unpaired',
        cycle: null,
        discomfortLevel: null,
      };
    }

    const ownerDeviceId = audience.ownerDeviceId;
    if (!ownerDeviceId) {
      throw new Error('Paired audience is missing its owner device id.');
    }
    const [cycles, dailyLog, settings] = await Promise.all([
      this.cycleModel
        .find({ ownerDeviceId })
        .select('startDate endDate periodLength cycleLength -_id')
        .lean()
        .exec(),
      this.dailyLogModel
        .findOne({ ownerDeviceId, date: normalizedDate })
        .select('mood symptoms discomfortLevel note -_id')
        .lean()
        .exec(),
      this.settingsProvider.getSettings(ownerDeviceId),
    ]);
    const cycle = calculateCycleSummary(cycles, settings, normalizedDate);
    if (audience.audience === 'partner') {
      return {
        date: normalizedDate,
        relationship: 'paired',
        cycle: this.toPartnerCycle(cycle),
        discomfortLevel: dailyLog?.discomfortLevel ?? null,
      };
    }
    return {
      date: normalizedDate,
      relationship: 'owner',
      cycle,
      dailyLog: {
        mood: dailyLog?.mood ?? null,
        symptoms: dailyLog?.symptoms ?? [],
        discomfortLevel: dailyLog?.discomfortLevel ?? null,
        note: dailyLog?.note ?? null,
      },
    };
  }

  async resolveAudience(
    device: AuthenticatedDevice,
  ): Promise<AudienceResolution> {
    if (device.role === DeviceRole.OWNER) {
      const owner = await this.deviceModel
        .findOne({
          _id: device.deviceId,
          role: DeviceRole.OWNER,
          status: DeviceStatus.ACTIVE,
        })
        .select('_id pairId')
        .lean()
        .exec();
      if (!owner?.pairId) {
        throw new Error('Active owner is missing its server-managed pair id.');
      }
      return {
        audience: 'owner',
        relationship: 'owner',
        pairId: owner.pairId,
        ownerDeviceId: String(owner._id),
      };
    }
    const partner = await this.deviceModel
      .findOne({
        _id: device.deviceId,
        role: DeviceRole.PARTNER,
        status: DeviceStatus.ACTIVE,
      })
      .select('_id pairId pairedOwnerDeviceId')
      .lean()
      .exec();
    if (!partner?.pairId || !partner.pairedOwnerDeviceId) {
      return { audience: 'partner', relationship: 'unpaired' };
    }
    const owner = await this.deviceModel
      .findOne({
        _id: partner.pairedOwnerDeviceId,
        role: DeviceRole.OWNER,
        status: DeviceStatus.ACTIVE,
      })
      .select('_id pairId')
      .lean()
      .exec();
    if (!owner || owner.pairId !== partner.pairId) {
      return { audience: 'partner', relationship: 'unpaired' };
    }
    return {
      audience: 'partner',
      relationship: 'paired',
      pairId: partner.pairId,
      ownerDeviceId: String(owner._id),
    };
  }

  private toPartnerCycle(
    cycle: CycleSummary,
  ): PartnerDashboardResponse['cycle'] {
    return {
      currentCycleDay: cycle.currentCycleDay,
      isPeriodActive: cycle.isPeriodActive,
      daysUntilNextPeriod: cycle.daysUntilNextPeriod,
      predictedPeriodStart: cycle.predictedPeriodStart,
      predictedPeriodEnd: cycle.predictedPeriodEnd,
    };
  }

  private assertDateOnly(value: string): string {
    const match = DATE_PATTERN.exec(value);
    if (!match) {
      throw new BadRequestException('date must be a yyyy-MM-dd date.');
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const parsed = new Date(Date.UTC(year, month - 1, day, 12));
    if (
      parsed.getUTCFullYear() !== year ||
      parsed.getUTCMonth() !== month - 1 ||
      parsed.getUTCDate() !== day
    ) {
      throw new BadRequestException('date must be a valid yyyy-MM-dd date.');
    }
    return value;
  }
}
