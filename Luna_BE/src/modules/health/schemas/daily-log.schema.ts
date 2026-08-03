import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export enum Mood {
  NEUTRAL = 'neutral',
  HAPPY = 'happy',
  SAD = 'sad',
  ANGRY = 'angry',
  SLEEPY = 'sleepy',
  TIRED = 'tired',
  ANXIOUS = 'anxious',
}

export enum Symptom {
  CRAMPS = 'cramps',
  BACK_PAIN = 'back_pain',
  HEADACHE = 'headache',
  NAUSEA = 'nausea',
  DIZZINESS = 'dizziness',
  FATIGUE = 'fatigue',
  INSOMNIA = 'insomnia',
  SWEET_CRAVINGS = 'sweet_cravings',
  BREAST_TENDERNESS = 'breast_tenderness',
  ACNE = 'acne',
}

@Schema({ timestamps: true })
export class DailyLog {
  @Prop({ required: true, trim: true })
  ownerDeviceId!: string;

  @Prop({ required: true, match: /^\d{4}-\d{2}-\d{2}$/ })
  date!: string;

  @Prop({ enum: Mood })
  mood?: Mood;

  @Prop({ type: [String], enum: Symptom, default: undefined })
  symptoms?: Symptom[];

  @Prop({ type: Number, min: 0, max: 5 })
  discomfortLevel?: number;

  @Prop({ type: String, trim: true, maxlength: 4000 })
  note?: string;
}

export type DailyLogDocument = HydratedDocument<DailyLog>;
export const DailyLogSchema = SchemaFactory.createForClass(DailyLog);

DailyLogSchema.index(
  { ownerDeviceId: 1, date: 1 },
  { name: 'one_daily_log_per_owner_and_date', unique: true },
);
