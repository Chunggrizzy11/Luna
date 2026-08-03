import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export enum DeviceRole {
  OWNER = 'owner',
  PARTNER = 'partner',
}

export enum DeviceStatus {
  ACTIVE = 'active',
  REVOKED = 'revoked',
}

@Schema({ timestamps: true })
export class Device {
  @Prop({ required: true, select: false, unique: true })
  tokenHash!: string;

  @Prop({ enum: DeviceRole, required: true, default: DeviceRole.OWNER })
  role!: DeviceRole;

  @Prop({ enum: DeviceStatus, required: true, default: DeviceStatus.ACTIVE })
  status!: DeviceStatus;

  @Prop({ required: true, trim: true, maxlength: 32 })
  platform!: string;

  @Prop({ trim: true, maxlength: 128 })
  deviceName?: string;

  @Prop({ trim: true, maxlength: 4096 })
  fcmToken?: string;
}

export type DeviceDocument = HydratedDocument<Device>;
export const DeviceSchema = SchemaFactory.createForClass(Device);
