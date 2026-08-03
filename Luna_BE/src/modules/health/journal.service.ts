import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DeviceRole } from '../device/schemas/device.schema';
import { DailyLog } from './schemas/daily-log.schema';

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const MAX_PAGE_SIZE = 100;

export interface JournalQuery {
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
}

export interface JournalResponse {
  items: Array<{
    date: string;
    mood?: string;
    symptoms?: string[];
    discomfortLevel?: number;
    note?: string;
  }>;
  page: number;
  limit: number;
}

@Injectable()
export class JournalService {
  constructor(
    @InjectModel(DailyLog.name)
    private readonly dailyLogModel: Model<DailyLog>,
  ) {}

  async list(
    owner: AuthenticatedDevice,
    query: JournalQuery,
  ): Promise<JournalResponse> {
    if (owner.role !== DeviceRole.OWNER) {
      throw new ForbiddenException('Only the owner can access journal data.');
    }
    const from = query.from ? this.assertDateOnly(query.from) : undefined;
    const to = query.to ? this.assertDateOnly(query.to) : undefined;
    if (from && to && from > to) {
      throw new ConflictException('from cannot be after to.');
    }
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    if (!Number.isInteger(page) || page < 1) {
      throw new BadRequestException('page must be a positive integer.');
    }
    if (!Number.isInteger(limit) || limit < 1 || limit > MAX_PAGE_SIZE) {
      throw new BadRequestException('limit must be between 1 and 100.');
    }
    const date = {
      ...(from ? { $gte: from } : {}),
      ...(to ? { $lte: to } : {}),
    };
    const filter = {
      ownerDeviceId: owner.deviceId,
      ...(Object.keys(date).length > 0 ? { date } : {}),
    };
    const items = await this.dailyLogModel
      .find(filter)
      .select('date mood symptoms discomfortLevel note -_id')
      .sort({ date: -1, _id: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean()
      .exec();
    return { items, page, limit };
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
