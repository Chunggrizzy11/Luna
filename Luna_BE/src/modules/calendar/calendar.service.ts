import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import { BusinessDateClock } from '../../common/date/business-date';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { DeviceRole } from '../device/schemas/device.schema';
import { DeviceService } from '../device/device.service';
import {
  buildCalendarDays,
  calculateCycleSummary,
} from '../cycle/cycle-calculator.service';
import {
  CYCLE_SETTINGS_PROVIDER,
  type CycleSettingsProvider,
} from '../cycle/cycle.service';
import { Cycle } from '../cycle/schemas/cycle.schema';
import type { CalendarDay } from '../cycle/cycle.types';

const MONTH_PATTERN = /^(\d{4})-(\d{2})$/;

export interface CalendarResponse {
  month: string;
  days: CalendarDay[];
}

@Injectable()
export class CalendarService {
  constructor(
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @Inject(CYCLE_SETTINGS_PROVIDER)
    private readonly settingsProvider: CycleSettingsProvider,
    private readonly businessDate: BusinessDateClock,
    private readonly deviceService: DeviceService,
  ) {}

  async getMonth(
    device: AuthenticatedDevice,
    month: string,
  ): Promise<CalendarResponse> {
    const ownerDeviceId = await this.deviceService.resolveOwnerId(device);
    this.assertMonth(month);
    const [cycles, settings] = await Promise.all([
      this.cycleModel
        .find({ ownerDeviceId })
        .select('startDate endDate periodLength cycleLength -_id')
        .lean()
        .exec(),
      this.settingsProvider.getSettings(ownerDeviceId),
    ]);
    const today = this.businessDate.today();
    const summary = calculateCycleSummary(cycles, settings, today);
    return { month, days: buildCalendarDays(summary, month) };
  }

  private assertMonth(value: string): void {
    const match = MONTH_PATTERN.exec(value);
    if (!match) {
      throw new BadRequestException('month must be a yyyy-MM month.');
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const parsed = new Date(Date.UTC(year, month - 1, 1, 12));
    if (
      parsed.getUTCFullYear() !== year ||
      parsed.getUTCMonth() !== month - 1
    ) {
      throw new BadRequestException('month must be a valid yyyy-MM month.');
    }
  }
}
