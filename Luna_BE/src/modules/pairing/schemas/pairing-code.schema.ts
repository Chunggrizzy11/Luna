import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

@Schema({ timestamps: { createdAt: true, updatedAt: false } })
export class PairingCode {
  @Prop({ required: true, unique: true, length: 8, uppercase: true })
  code!: string;

  @Prop({ type: Types.ObjectId, ref: 'Device', required: true, index: true })
  ownerDeviceId!: Types.ObjectId;

  @Prop({ required: true })
  expiresAt!: Date;

  @Prop({ default: 0, max: 5 })
  attempts!: number;

  @Prop({ default: false })
  used!: boolean;
}

export type PairingCodeDocument = HydratedDocument<PairingCode>;
export const PairingCodeSchema = SchemaFactory.createForClass(PairingCode);
PairingCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 300 });
