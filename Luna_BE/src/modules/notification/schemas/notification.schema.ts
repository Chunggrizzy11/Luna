import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum NotificationType {
  CYCLE_REMINDER = 'cycle_reminder',
  CARE_SUGGESTION = 'care_suggestion',
  JOURNAL_PROMPT = 'journal_prompt',
  PAIRING_UPDATE = 'pairing_update',
  GENERAL = 'general',
  SOS = 'sos',
}

@Schema({ timestamps: true })
export class Notification {
  @Prop({ type: Types.ObjectId, ref: 'Device', required: true, index: true })
  recipientDeviceId!: Types.ObjectId;

  @Prop({ enum: NotificationType, required: true })
  type!: NotificationType;

  @Prop({ required: true, maxlength: 200 })
  title!: string;

  @Prop({ required: true, maxlength: 500 })
  body!: string;

  @Prop({ type: Object })
  data?: Record<string, string>;

  @Prop({ default: false })
  read!: boolean;

  @Prop({ default: false })
  sent!: boolean;
}

export type NotificationDocument = HydratedDocument<Notification>;
export const NotificationSchema = SchemaFactory.createForClass(Notification);
NotificationSchema.index({ recipientDeviceId: 1, read: 1 });
NotificationSchema.index({ recipientDeviceId: 1, createdAt: -1 });
