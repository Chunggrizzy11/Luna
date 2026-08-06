import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import type { ClientSession, Connection, Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DeviceRole } from '../device/schemas/device.schema';
import { DeviceService } from '../device/device.service';
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
const MAX_DERIVED_CYCLE_LENGTH = 365;
const MAX_RECORDED_PERIOD_LENGTH = 90;

@Injectable()
export class CycleService {
  constructor(
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @Inject(CYCLE_SETTINGS_PROVIDER)
    private readonly settingsProvider: CycleSettingsProvider,
    @InjectConnection() private readonly connection: Connection,
    private readonly deviceService: DeviceService,
  ) {}

  async start(
    owner: AuthenticatedDevice,
    date: string,
  ): Promise<CycleResponse> {
    this.requireOwner(owner);
    const startDate = this.assertDateOnly(date);
    try {
      return await this.connection.transaction((session) =>
        this.startInTransaction(owner, startDate, session),
      );
    } catch (error: unknown) {
      if (this.isDuplicateKeyError(error)) {
        throw new ConflictException('An active cycle already exists.');
      }
      throw error;
    }
  }

  private async startInTransaction(
    owner: AuthenticatedDevice,
    startDate: string,
    session: ClientSession,
  ): Promise<CycleResponse> {
    const active = await this.cycleModel
      .findOne({ ownerDeviceId: owner.deviceId, endDate: null })
      .session(session)
      .lean()
      .exec();
    if (active) {
      throw new ConflictException('An active cycle already exists.');
    }

    const previous = await this.cycleModel
      .findOne({ ownerDeviceId: owner.deviceId })
      .sort({ startDate: -1, _id: -1 })
      .session(session)
      .lean()
      .exec();
    if (
      previous &&
      (startDate <= previous.startDate ||
        (previous.endDate !== null && startDate <= previous.endDate))
    ) {
      throw new ConflictException(
        'A new cycle must start after the latest cycle dates.',
      );
    }
    const derivedCycleLength = previous
      ? this.daysBetween(previous.startDate, startDate)
      : null;

    const [created] = await this.cycleModel.create(
      [
        {
          ownerDeviceId: owner.deviceId,
          startDate,
          endDate: null,
          source: CycleSource.MANUAL,
        },
      ],
      { session },
    );

    if (
      previous &&
      derivedCycleLength !== null &&
      derivedCycleLength <= MAX_DERIVED_CYCLE_LENGTH
    ) {
      const updatedPrevious = await this.cycleModel
        .findOneAndUpdate(
          { _id: previous._id, ownerDeviceId: owner.deviceId },
          { cycleLength: derivedCycleLength },
          { runValidators: true, session },
        )
        .exec();
      if (!updatedPrevious) {
        throw new Error('The previous cycle could not be updated.');
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

    const inclusivePeriodLength =
      this.daysBetween(active.startDate, endDate) + 1;
    const periodLength =
      inclusivePeriodLength <= MAX_RECORDED_PERIOD_LENGTH
        ? inclusivePeriodLength
        : null;
    const updated = await this.cycleModel
      .findOneAndUpdate(
        { _id: active._id, ownerDeviceId: owner.deviceId, endDate: null },
        {
          endDate,
          periodLength,
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

  async findCurrent(device: AuthenticatedDevice): Promise<CycleResponse | null> {
    const ownerDeviceId = await this.deviceService.resolveOwnerId(device);
    const cycle = await this.cycleModel
      .findOne({ ownerDeviceId, endDate: null })
      .lean()
      .exec();
    return cycle ? this.toResponse(cycle) : null;
  }

  async list(
    device: AuthenticatedDevice,
    range: Pick<CycleQueryDto, 'from' | 'to' | 'page' | 'limit'>,
  ): Promise<CycleListResponse> {
    const ownerDeviceId = await this.deviceService.resolveOwnerId(device);
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
      ownerDeviceId,
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
    device: AuthenticatedDevice,
    today: string,
  ): Promise<CycleSummary> {
    const ownerDeviceId = await this.deviceService.resolveOwnerId(device);
    const normalizedToday = this.assertDateOnly(today);
    const [cycles, settings] = await Promise.all([
      this.cycleModel.find({ ownerDeviceId }).lean().exec(),
      this.settingsProvider.getSettings(ownerDeviceId),
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
