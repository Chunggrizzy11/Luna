import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DeviceRole } from '../device/schemas/device.schema';
import { calculateCycleSummary } from './cycle-calculator.service';
import type { CycleQueryDto } from './dto/cycle-query.dto';
import { Cycle, CycleSource } from './schemas/cycle.schema';
import type { CycleRecord, CycleSettings, CycleSummary } from './cycle.types';

export const CYCLE_SETTINGS_PROVIDER = 'CYCLE_SETTINGS_PROVIDER';

export interface CycleSettingsProvider {
  getSettings(ownerDeviceId: string): CycleSettings | Promise<CycleSettings>;
}

export interface CycleResponse extends CycleRecord {
  source: CycleSource;
}

export interface CycleListResponse {
  items: CycleResponse[];
  page: number;
  limit: number;
}

interface StoredCycle extends CycleRecord {
  _id?: unknown;
  ownerDeviceId: string;
  source: CycleSource;
}

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class CycleService {
  constructor(
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @Inject(CYCLE_SETTINGS_PROVIDER)
    private readonly settingsProvider: CycleSettingsProvider,
  ) {}

  async start(
    owner: AuthenticatedDevice,
    date: string,
  ): Promise<CycleResponse> {
    this.requireOwner(owner);
    const startDate = this.assertDateOnly(date);
    const active = await this.cycleModel
      .findOne({ ownerDeviceId: owner.deviceId, endDate: null })
      .lean()
      .exec();
    if (active) {
      throw new ConflictException('An active cycle already exists.');
    }

    const previous = await this.cycleModel
      .findOne({
        ownerDeviceId: owner.deviceId,
        endDate: { $ne: null },
        startDate: { $lt: startDate },
      })
      .sort({ startDate: -1, _id: -1 })
      .lean()
      .exec();
    const derivedCycleLength = previous
      ? this.daysBetween(previous.startDate, startDate)
      : null;
    if (
      derivedCycleLength !== null &&
      (derivedCycleLength < 1 || derivedCycleLength > 365)
    ) {
      throw new BadRequestException(
        'Derived cycle length must be between 1 and 365 days.',
      );
    }

    let created: Cycle & { _id: unknown };
    try {
      created = (await this.cycleModel.create({
        ownerDeviceId: owner.deviceId,
        startDate,
        endDate: null,
        source: CycleSource.MANUAL,
      })) as Cycle & { _id: unknown };
    } catch (error: unknown) {
      if (this.isDuplicateKeyError(error)) {
        throw new ConflictException('An active cycle already exists.');
      }
      throw error;
    }

    if (previous && derivedCycleLength !== null) {
      try {
        const updatedPrevious = await this.cycleModel
          .findOneAndUpdate(
            { _id: previous._id, ownerDeviceId: owner.deviceId },
            { cycleLength: derivedCycleLength },
            { runValidators: true },
          )
          .exec();
        if (!updatedPrevious) {
          throw new Error('The previous cycle could not be updated.');
        }
      } catch (error: unknown) {
        // A reservation without its predecessor update is not a valid start.
        // Preserve the update failure after best-effort removal of only this request's active record.
        await this.cycleModel
          .deleteOne({
            _id: created._id,
            ownerDeviceId: owner.deviceId,
            endDate: null,
          })
          .exec()
          .catch(() => undefined);
        throw error;
      }
    }

    return this.toResponse(created);
  }

  async end(owner: AuthenticatedDevice, date: string): Promise<CycleResponse> {
    this.requireOwner(owner);
    const endDate = this.assertDateOnly(date);
    const active = await this.cycleModel
      .findOne({ ownerDeviceId: owner.deviceId, endDate: null })
      .lean()
      .exec();
    if (!active) {
      throw new NotFoundException('No active cycle exists.');
    }
    if (endDate < active.startDate) {
      throw new ConflictException('A cycle cannot end before it starts.');
    }

    const updated = await this.cycleModel
      .findOneAndUpdate(
        { _id: active._id, ownerDeviceId: owner.deviceId, endDate: null },
        {
          endDate,
          periodLength: this.daysBetween(active.startDate, endDate) + 1,
        },
        { returnDocument: 'after', runValidators: true },
      )
      .lean()
      .exec();
    if (!updated) {
      throw new NotFoundException('No active cycle exists.');
    }
    return this.toResponse(updated);
  }

  async findCurrent(owner: AuthenticatedDevice): Promise<CycleResponse | null> {
    this.requireOwner(owner);
    const cycle = await this.cycleModel
      .findOne({ ownerDeviceId: owner.deviceId, endDate: null })
      .lean()
      .exec();
    return cycle ? this.toResponse(cycle) : null;
  }

  async list(
    owner: AuthenticatedDevice,
    range: Pick<CycleQueryDto, 'from' | 'to' | 'page' | 'limit'>,
  ): Promise<CycleListResponse> {
    this.requireOwner(owner);
    const from = range.from ? this.assertDateOnly(range.from) : undefined;
    const to = range.to ? this.assertDateOnly(range.to) : undefined;
    if (from && to && from > to) {
      throw new ConflictException('from cannot be after to.');
    }
    const page = range.page ?? 1;
    const limit = range.limit ?? 20;
    const startDate = {
      ...(from ? { $gte: from } : {}),
      ...(to ? { $lte: to } : {}),
    };
    const filter = {
      ownerDeviceId: owner.deviceId,
      ...(Object.keys(startDate).length > 0 ? { startDate } : {}),
    };
    const cycles = await this.cycleModel
      .find(filter)
      .sort({ startDate: -1, _id: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean()
      .exec();
    return {
      items: cycles.map((cycle) => this.toResponse(cycle)),
      page,
      limit,
    };
  }

  async prediction(
    owner: AuthenticatedDevice,
    today: string,
  ): Promise<CycleSummary> {
    this.requireOwner(owner);
    const normalizedToday = this.assertDateOnly(today);
    const [cycles, settings] = await Promise.all([
      this.cycleModel.find({ ownerDeviceId: owner.deviceId }).lean().exec(),
      this.settingsProvider.getSettings(owner.deviceId),
    ]);
    return calculateCycleSummary(cycles, settings, normalizedToday);
  }

  private requireOwner(device: AuthenticatedDevice): void {
    if (device.role !== DeviceRole.OWNER) {
      throw new ForbiddenException('Only the owner can access cycle data.');
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

  private daysBetween(startDate: string, endDate: string): number {
    const [start, end] = [startDate, endDate].map((date) => {
      const match = DATE_PATTERN.exec(date);
      if (!match) throw new BadRequestException('Invalid stored cycle date.');
      return Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
    });
    return Math.round((end - start) / DAY_MS);
  }

  private toResponse(cycle: Cycle | StoredCycle): CycleResponse {
    return {
      startDate: cycle.startDate,
      endDate: cycle.endDate ?? null,
      periodLength: cycle.periodLength ?? null,
      cycleLength: cycle.cycleLength ?? null,
      source: cycle.source,
    };
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
