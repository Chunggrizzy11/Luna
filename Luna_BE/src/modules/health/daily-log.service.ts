import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DeviceRole } from '../device/schemas/device.schema';
import { DailyLog, Mood, Symptom } from './schemas/daily-log.schema';

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

export interface DailyLogFields {
  mood?: Mood;
  symptoms?: Symptom[];
  discomfortLevel?: number;
  note?: string;
}

export type DailyLogRecord = Pick<DailyLog, 'date'> & DailyLogFields;

@Injectable()
export class DailyLogService {
  constructor(
    @InjectModel(DailyLog.name)
    private readonly dailyLogModel: Model<DailyLog>,
  ) {}

  async findByDate(
    owner: AuthenticatedDevice,
    date: string,
  ): Promise<DailyLogRecord | null> {
    this.requireOwner(owner);
    const normalizedDate = this.assertDateOnly(date);
    return this.dailyLogModel
      .findOne({ ownerDeviceId: owner.deviceId, date: normalizedDate })
      .lean()
      .exec();
  }

  async upsertFields(
    owner: AuthenticatedDevice,
    date: string,
    patch: DailyLogFields,
  ): Promise<DailyLogRecord> {
    this.requireOwner(owner);
    const normalizedDate = this.assertDateOnly(date);
    const fields = Object.fromEntries(
      Object.entries(patch).filter(([, value]) => value !== undefined),
    ) as DailyLogFields;
    if (Object.keys(fields).length === 0) {
      throw new BadRequestException(
        'At least one daily log field is required.',
      );
    }

    let dailyLog: DailyLogRecord | null;
    try {
      dailyLog = await this.dailyLogModel
        .findOneAndUpdate(
          { ownerDeviceId: owner.deviceId, date: normalizedDate },
          {
            $set: fields,
            $setOnInsert: {
              ownerDeviceId: owner.deviceId,
              date: normalizedDate,
            },
          },
          { returnDocument: 'after', runValidators: true, upsert: true },
        )
        .lean()
        .exec();
    } catch (error: unknown) {
      if (!this.isDuplicateKeyError(error)) throw error;
      dailyLog = await this.dailyLogModel
        .findOneAndUpdate(
          { ownerDeviceId: owner.deviceId, date: normalizedDate },
          { $set: fields },
          { returnDocument: 'after', runValidators: true },
        )
        .lean()
        .exec();
    }
    if (!dailyLog) {
      throw new Error('Daily log upsert did not return a record.');
    }
    return dailyLog;
  }

  async unsetFields(
    owner: AuthenticatedDevice,
    date: string,
    fields: Array<keyof DailyLogFields>,
  ): Promise<DailyLogRecord | null> {
    this.requireOwner(owner);
    const normalizedDate = this.assertDateOnly(date);
    if (fields.length === 0) {
      throw new BadRequestException(
        'At least one daily log field is required.',
      );
    }
    const unset = Object.fromEntries(fields.map((field) => [field, 1]));
    return this.dailyLogModel
      .findOneAndUpdate(
        { ownerDeviceId: owner.deviceId, date: normalizedDate },
        { $unset: unset },
        { returnDocument: 'after', runValidators: true },
      )
      .lean()
      .exec();
  }

  private requireOwner(device: AuthenticatedDevice): void {
    if (device.role !== DeviceRole.OWNER) {
      throw new ForbiddenException('Only the owner can access daily log data.');
    }
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

  private isDuplicateKeyError(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: unknown }).code === 11000
    );
  }
}
