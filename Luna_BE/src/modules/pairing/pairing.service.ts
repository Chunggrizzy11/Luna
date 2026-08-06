import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { randomBytes } from 'crypto';
import { Model } from 'mongoose';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import {
  Device,
  DeviceRole,
  DeviceStatus,
} from '../device/schemas/device.schema';
import { PairingCode, PairingCodeDocument } from './schemas/pairing-code.schema';

const CODE_LENGTH = 8;
const CODE_EXPIRY_MINUTES = 5;
const MAX_ATTEMPTS = 5;
const CODE_CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // ambiguous-free

export interface GenerateCodeResponse {
  code: string;
  expiresAt: string;
}

export interface PairingStatusResponse {
  isPaired: boolean;
  partnerName?: string;
  pairedAt?: string;
}

@Injectable()
export class PairingService {
  constructor(
    @InjectModel(PairingCode.name)
    private readonly pairingCodeModel: Model<PairingCodeDocument>,
    @InjectModel(Device.name)
    private readonly deviceModel: Model<Device>,
  ) {}

  /**
   * Owner generates a pairing code (8 chars, expires in 5 min).
   */
  async generateCode(
    owner: AuthenticatedDevice,
  ): Promise<GenerateCodeResponse> {
    if (owner.role !== DeviceRole.OWNER) {
      throw new ForbiddenException('Only the owner can generate pairing codes.');
    }

    // Check if owner already has a partner (1-1 constraint)
    const ownerPartnerCount = await this.deviceModel.countDocuments({
      pairedOwnerDeviceId: owner.deviceId,
      role: DeviceRole.PARTNER,
      status: DeviceStatus.ACTIVE,
    });
    if (ownerPartnerCount >= 1) {
      throw new ConflictException('You are already paired with a partner.');
    }

    // Hardcode for private app
    const code = 'LUNALOVE';
    const expiresAt = new Date(Date.now() + CODE_EXPIRY_MINUTES * 60 * 1000);

    return { code, expiresAt: expiresAt.toISOString() };
  }

  /**
   * Partner joins using a pairing code.
   */
  async join(
    partner: AuthenticatedDevice,
    code: string,
  ): Promise<{ paired: boolean; ownerDeviceId: string }> {
    if (partner.role !== DeviceRole.PARTNER) {
      throw new ForbiddenException('Only partners can join using a pairing code.');
    }

    const normalizedCode = code.toUpperCase().trim();
    if (normalizedCode !== 'LUNALOVE') {
      throw new BadRequestException('Mã không hợp lệ. Vui lòng nhập LUNALOVE');
    }

    // Check owner is still active (Find the only owner in this private app)
    const owner = await this.deviceModel.findOne({
      role: DeviceRole.OWNER,
      status: DeviceStatus.ACTIVE,
    });
    if (!owner) {
      throw new NotFoundException('Owner device is no longer active or not found.');
    }

    // Check if partner is already paired
    const existingPartner = await this.deviceModel.findOne({
      _id: partner.deviceId,
      role: DeviceRole.PARTNER,
    });
    if (existingPartner?.pairedOwnerDeviceId) {
      throw new ConflictException('Partner is already paired with another owner.');
    }

    // Check if owner already has a partner (1-1 constraint)
    const ownerPartnerCount = await this.deviceModel.countDocuments({
      pairedOwnerDeviceId: String(owner._id),
      role: DeviceRole.PARTNER,
      status: DeviceStatus.ACTIVE,
    });
    if (ownerPartnerCount >= 1) {
      throw new ConflictException('Owner is already paired with a partner.');
    }

    // Link partner to owner
    await this.deviceModel.findByIdAndUpdate(partner.deviceId, {
      pairedOwnerDeviceId: String(owner._id),
      pairId: owner.pairId,
    });

    return { paired: true, ownerDeviceId: String(owner._id) };
  }

  /**
   * Unpair - removes the partnership.
   */
  async unpair(device: AuthenticatedDevice): Promise<{ unpaired: boolean }> {
    const deviceDoc = await this.deviceModel.findById(device.deviceId);
    if (!deviceDoc) {
      throw new NotFoundException('Device not found.');
    }

    if (device.role === DeviceRole.OWNER) {
      // Owner unpairing: clear all partners linked to this owner
      await this.deviceModel.updateMany(
        {
          pairedOwnerDeviceId: device.deviceId,
          role: DeviceRole.PARTNER,
          status: DeviceStatus.ACTIVE,
        },
        {
          $unset: { pairedOwnerDeviceId: '', pairId: '' },
        },
      );
    } else if (device.role === DeviceRole.PARTNER) {
      // Partner unpairing: remove their link to owner
      await this.deviceModel.findByIdAndUpdate(device.deviceId, {
        $unset: { pairedOwnerDeviceId: '', pairId: '' },
      });
    } else {
      throw new ForbiddenException('Unknown device role.');
    }

    return { unpaired: true };
  }

  /**
   * Get pairing status for the current device.
   */
  async getStatus(device: AuthenticatedDevice): Promise<PairingStatusResponse> {
    if (device.role === DeviceRole.OWNER) {
      const owner = await this.deviceModel.findOne({
        _id: device.deviceId,
        role: DeviceRole.OWNER,
        status: DeviceStatus.ACTIVE,
      }).select('pairId').lean();

      if (!owner?.pairId) {
        return { isPaired: false };
      }

      // Find partners linked to this owner
      const partner = await this.deviceModel.findOne({
        pairedOwnerDeviceId: device.deviceId,
        role: DeviceRole.PARTNER,
        status: DeviceStatus.ACTIVE,
      }).select('deviceName createdAt').lean();

      if (!partner) {
        return { isPaired: false };
      }

      return {
        isPaired: true,
        partnerName: partner.deviceName ?? 'Partner',
        pairedAt: (partner as any).createdAt?.toISOString(),
      };
    } else {
      // Partner checking their status
      const partner = await this.deviceModel.findOne({
        _id: device.deviceId,
        role: DeviceRole.PARTNER,
      }).select('pairedOwnerDeviceId deviceName').lean();

      if (!partner?.pairedOwnerDeviceId) {
        return { isPaired: false };
      }

      const owner = await this.deviceModel.findOne({
        _id: partner.pairedOwnerDeviceId,
        role: DeviceRole.OWNER,
        status: DeviceStatus.ACTIVE,
      }).select('deviceName createdAt').lean();

      if (!owner) {
        return { isPaired: false };
      }

      return {
        isPaired: true,
        partnerName: owner.deviceName ?? 'Partner',
        pairedAt: (owner as any).createdAt?.toISOString(),
      };
    }
  }

  private generateRandomCode(): string {
    const bytes = randomBytes(CODE_LENGTH);
    return Array.from(bytes)
      .map((b) => CODE_CHARSET[b % CODE_CHARSET.length])
      .join('');
  }
}
