import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Device, DeviceRole, DeviceStatus } from '../modules/device/schemas/device.schema';
import { PairingCode } from '../modules/pairing/schemas/pairing-code.schema';
import { Cycle, CycleSource } from '../modules/cycle/schemas/cycle.schema';
import { DailyLog } from '../modules/health/schemas/daily-log.schema';

@Injectable()
export class UatSeedService {
  private readonly logger = new Logger(UatSeedService.name);

  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<Device>,
    @InjectModel(PairingCode.name) private readonly pairingCodeModel: Model<PairingCode>,
    @InjectModel(Cycle.name) private readonly cycleModel: Model<Cycle>,
    @InjectModel(DailyLog.name) private readonly dailyLogModel: Model<DailyLog>,
  ) {}

  async seed(): Promise<void> {
    this.logger.log('Starting UAT seed...');

    // Clear existing UAT data
    await this.deviceModel.deleteMany({ platform: 'uat-seed' });

    // Create Owner
    const owner = await this.deviceModel.create({
      role: DeviceRole.OWNER,
      platform: 'uat-seed',
      deviceName: 'Luna UAT Owner',
      status: DeviceStatus.ACTIVE,
      pairId: 'UAT-PAIR-001',
      tokenHash: 'uat-owner-token-hash',
    });

    // Create Partner
    const partner = await this.deviceModel.create({
      role: DeviceRole.PARTNER,
      platform: 'uat-seed',
      deviceName: 'Luna UAT Partner',
      status: DeviceStatus.ACTIVE,
      pairId: 'UAT-PAIR-001',
      pairedOwnerDeviceId: String(owner._id),
      tokenHash: 'uat-partner-token-hash',
    });

    // Seed Cycle Data (5 cycles)
    const cycles = [];
    let startDate = new Date();
    for (let i = 0; i < 5; i++) {
      cycles.push({
        ownerDeviceId: owner._id,
        startDate: new Date(startDate),
        endDate: new Date(startDate.getTime() + 5 * 24 * 60 * 60 * 1000),
        periodLength: 5,
        cycleLength: 28,
        source: CycleSource.MANUAL,
      });
      startDate = new Date(startDate.getTime() + 28 * 24 * 60 * 60 * 1000);
    }
    await this.cycleModel.insertMany(cycles);

    // Seed Daily Logs
    const dailyLogs = [];
    const moods = ['happy', 'calm', 'stressed', 'anxious', 'sad'];
    const symptoms = ['headache', 'cramps', 'fatigue', 'bloating', 'moodSwings'];

    for (let i = 0; i < 30; i++) {
      const logDate = new Date();
      logDate.setDate(logDate.getDate() - i);
      dailyLogs.push({
        ownerDeviceId: owner._id,
        date: logDate.toISOString().split('T')[0],
        mood: moods[Math.floor(Math.random() * moods.length)],
        symptoms: [symptoms[Math.floor(Math.random() * symptoms.length)]],
        discomfortLevel: Math.floor(Math.random() * 5) + 1,
        note: `Test note for day ${i + 1}`,
      });
    }
    await this.dailyLogModel.insertMany(dailyLogs);

    this.logger.log(`UAT seed completed: Owner=${owner._id}, Partner=${partner._id}`);
    this.logger.log(`Seeded ${cycles.length} cycles and ${dailyLogs.length} daily logs`);
  }
}
