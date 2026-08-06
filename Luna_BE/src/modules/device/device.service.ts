import { ForbiddenException, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { createHash, randomBytes, randomUUID } from 'crypto';
import type { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { PushTokenDto } from './dto/push-token.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';
import { Device, DeviceRole, DeviceStatus } from './schemas/device.schema';

export const DEVICE_TOKEN_PEPPER = 'DEVICE_TOKEN_PEPPER';

@Injectable()
export class DeviceService {
  constructor(
    @InjectModel(Device.name) private readonly deviceModel: Model<Device>,
    @Inject(DEVICE_TOKEN_PEPPER) private readonly tokenPepper: string,
  ) {}

  async register(
    dto: RegisterDeviceDto,
  ): Promise<{ deviceId: string; token: string }> {
    const token = randomBytes(32).toString('hex');
    const registration = { ...dto };
    delete registration.pairId;
    const device = await this.deviceModel.create({
      ...registration,
      ...(dto.role === DeviceRole.OWNER ? { pairId: randomUUID() } : {}),
      tokenHash: this.hashToken(token),
      status: DeviceStatus.ACTIVE,
    });

    return { deviceId: device.id ?? String(device._id), token };
  }

  async authenticate(token: string): Promise<AuthenticatedDevice> {
    const device = await this.deviceModel
      .findOne({
        tokenHash: this.hashToken(token),
        status: DeviceStatus.ACTIVE,
      })
      .exec();

    if (!device) {
      throw new UnauthorizedException();
    }

    return {
      deviceId: device.id ?? String(device._id),
      role: device.role,
      status: device.status,
    };
  }

  async update(deviceId: string, dto: UpdateDeviceDto): Promise<void> {
    await this.deviceModel
      .findByIdAndUpdate(deviceId, dto, { runValidators: true })
      .exec();
  }

  async updatePushToken(deviceId: string, dto: PushTokenDto): Promise<void> {
    await this.deviceModel
      .findByIdAndUpdate(deviceId, { fcmToken: dto.fcmToken })
      .exec();
  }

  async revoke(deviceId: string): Promise<void> {
    await this.deviceModel
      .findByIdAndUpdate(deviceId, { status: DeviceStatus.REVOKED })
      .exec();
  }

  async resolveOwnerId(device: AuthenticatedDevice): Promise<string> {
    if (device.role === DeviceRole.OWNER) {
      return device.deviceId;
    }
    const partner = await this.deviceModel
      .findById(device.deviceId)
      .select('pairedOwnerDeviceId')
      .lean()
      .exec();
    if (!partner?.pairedOwnerDeviceId) {
      throw new ForbiddenException('Partner is not paired with any owner.');
    }
    return partner.pairedOwnerDeviceId;
  }

  private hashToken(token: string): string {
    return createHash('sha256')
      .update(`${token}${this.tokenPepper}`)
      .digest('hex');
  }
}
