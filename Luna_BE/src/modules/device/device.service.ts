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

    let pairId: string | undefined;
    let pairedOwnerDeviceId: string | undefined;

    if (dto.role === DeviceRole.OWNER) {
      pairId = randomUUID();
    } else if (dto.role === DeviceRole.PARTNER) {
      const owner = await this.deviceModel
        .findOne({ role: DeviceRole.OWNER, status: DeviceStatus.ACTIVE })
        .sort({ createdAt: -1 });
      if (owner) {
        pairId = owner.pairId;
        pairedOwnerDeviceId = String(owner._id);

        await this.deviceModel.updateMany(
          {
            pairedOwnerDeviceId: String(owner._id),
            role: DeviceRole.PARTNER,
            status: DeviceStatus.ACTIVE,
          },
          {
            $unset: { pairedOwnerDeviceId: '', pairId: '' },
          },
        );
      }
    }

    const device = await this.deviceModel.create({
      ...registration,
      ...(pairId ? { pairId } : {}),
      ...(pairedOwnerDeviceId ? { pairedOwnerDeviceId } : {}),
      tokenHash: this.hashToken(token),
      status: DeviceStatus.ACTIVE,
    });

    if (dto.role === DeviceRole.OWNER) {
      const partner = await this.deviceModel
        .findOne({ role: DeviceRole.PARTNER, status: DeviceStatus.ACTIVE })
        .sort({ createdAt: -1 });
      if (partner) {
        await this.deviceModel.findByIdAndUpdate(partner._id, {
          pairId: pairId,
          pairedOwnerDeviceId: String(device._id),
        });
      }
    }

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
