import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Cron, CronExpression } from '@nestjs/schedule';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { Device } from '../device/schemas/device.schema';
import { CycleService } from '../cycle/cycle.service';
import { CareSuggestionService } from './care-suggestion.service';
import { NotificationService } from '../notification/notification.service';
import { PushNotificationService } from '../notification/push-notification.service';

@Injectable()
export class NotificationSchedulerService {
  private readonly logger = new Logger(NotificationSchedulerService.name);

  constructor(
    @InjectModel(Device.name)
    private readonly deviceModel: Model<Device>,
    private readonly cycleService: CycleService,
    private readonly careSuggestionService: CareSuggestionService,
    private readonly notificationService: NotificationService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async checkCycleReminders(): Promise<void> {
    try {
      // Find all paired devices (owners)
      const owners = await this.deviceModel
        .find({ role: 'owner', pairId: { $exists: true } } as any)
        .lean()
        .exec();

      for (const owner of owners) {
        await this.checkOwnerCycleReminders(owner._id as unknown as string);
      }
    } catch (error) {
      this.logger.error('Failed to check cycle reminders', error);
    }
  }

  @Cron(CronExpression.EVERY_6_HOURS)
  async checkCareSuggestions(): Promise<void> {
    try {
      // Check all paired devices for care suggestions
      const owners = await this.deviceModel
        .find({ role: 'owner', pairId: { $exists: true } } as any)
        .lean()
        .exec();

      for (const owner of owners) {
        const partner = await this.deviceModel.findOne({
          pairId: owner.pairId,
          role: 'partner',
        } as any);

        if (!partner) continue;

        await this.checkCareSuggestion(
          owner._id as unknown as string,
          partner._id as unknown as string,
        );
      }
    } catch (error) {
      this.logger.error('Failed to check care suggestions', error);
    }
  }

  @Cron(CronExpression.EVERY_DAY_AT_9AM)
  async checkDailyLogReminders(): Promise<void> {
    try {
      const today = new Date().toISOString().split('T')[0];
      const owners = await this.deviceModel
        .find({ role: 'owner', pairId: { $exists: true } } as any)
        .lean()
        .exec();

      for (const owner of owners) {
        await this.checkDailyLogReminder(
          owner._id as unknown as string,
          today,
        );
      }
    } catch (error) {
      this.logger.error('Failed to check daily log reminders', error);
    }
  }

  private async checkOwnerCycleReminders(ownerDeviceId: string): Promise<void> {
    const owner: any = await this.deviceModel.findById(ownerDeviceId).lean().exec();
    if (!owner) return;

    const cycles = await this.cycleService.list(
      { deviceId: ownerDeviceId } as any,
      { from: undefined, to: undefined, page: 1, limit: 10 } as any,
    );

    for (const cycle of cycles.items) {
      if (cycle.endDate) continue; // Skip completed cycles

      const cycleStart = new Date(cycle.startDate);
      const today = new Date();
      const daysInCycle = Math.floor(
        (today.getTime() - cycleStart.getTime()) / (1000 * 60 * 60 * 24),
      );

      // Send notifications for key cycle milestones
      if (daysInCycle > 0 && daysInCycle <= 3) {
        await this.createReminder(
          ownerDeviceId,
          'Chu kỳ bắt đầu',
          `Chu kỳ kinh nguyệt của bạn có thể đã bắt đầu! 📥️ Hôm nay là ngày ${daysInCycle} của chu kỳ.`,
          'cycle_reminder',
          { cycleStart: cycle.startDate, day: daysInCycle.toString() },
        );
      }

      if (daysInCycle > 0 && daysInCycle >= 28 && daysInCycle <= 34) {
        await this.createReminder(
          ownerDeviceId,
          'Dự kiến ngày đèn đỏ',
          `Theo chu kỳ của bạn, ngày đèn đỏ dự kiến sẽ rơi vào khoảng ngày ${daysInCycle} (hoặc gần đây).`,
          'cycle_reminder',
          { cycleStart: cycle.startDate, day: daysInCycle.toString() },
        );
      }
    }
  }

  private async checkCareSuggestion(
    ownerDeviceId: string,
    partnerDeviceId: string,
  ): Promise<void> {
    const owner = await this.deviceModel.findById(ownerDeviceId).lean().exec();
    if (!owner) return;

    const suggestion = await this.careSuggestionService.getToday(owner as any);
    if (!suggestion?.suggestion) return;

    await this.createReminder(
      partnerDeviceId,
      'Gợi ý chăm sóc',
      `Chuyên gia khuyên bạn: ${suggestion.suggestion.title} - ${suggestion.suggestion.description}`,
      'care_suggestion',
      {
        suggestionId: suggestion.suggestion.id,
        ownerDeviceId,
      },
    );

    await this.pushNotificationService.sendToDevice(
      partnerDeviceId,
      'Gợi ý chăm sóc',
      `${suggestion.suggestion.title} - ${suggestion.suggestion.description}`,
      { suggestionId: suggestion.suggestion.id },
    );
  }

  private async checkDailyLogReminder(
    ownerDeviceId: string,
    date: string,
  ): Promise<void> {
    const owner: any = await this.deviceModel.findById(ownerDeviceId).lean().exec();
    if (!owner) return;

    // Check if owner has logged their daily data for today
    const hasLoggedData = await this.hasLoggedDataToday(ownerDeviceId, date);
    if (!hasLoggedData) {
      await this.createReminder(
        ownerDeviceId,
        'Nhắc nhở nhật ký hàng ngày',
        `Hôm nay bạn chưa ghi chép biểu đồ sức khỏe. Hãy ghi nhanh vài thông tin!`,
        'journal_prompt',
        { date },
      );

      await this.pushNotificationService.sendToDevice(
        ownerDeviceId,
        'Nhắc nhở: Ghi chép biểu đồ sức khỏe',
        'Hôm nay bạn chưa ghi chép! Hãy ghi nhanh vài thông tin.',
        { date },
      );
    }
  }

  private async createReminder(
    deviceId: string,
    title: string,
    body: string,
    type: string,
    data?: Record<string, string>,
  ): Promise<void> {
    const message = {
      recipientDeviceId: deviceId,
      type: type as any,
      title,
      body,
      data,
    };

    await this.notificationService.create(message);
    await this.pushNotificationService.sendToDevice(deviceId, title, body, data);
  }

  private async hasLoggedDataToday(
    ownerDeviceId: string,
    date: string,
  ): Promise<boolean> {
    const device: any = await this.deviceModel
      .findById(ownerDeviceId)
      .select('pairedOwnerDeviceId')
      .lean()
      .exec();

    if (device?.pairedOwnerDeviceId) {
      // For paired devices, check partner's logs if needed
    }

    return true; // Placeholder - integrate with daily log check
  }
}
