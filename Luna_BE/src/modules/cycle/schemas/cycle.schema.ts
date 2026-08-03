import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export enum CycleSource {
  MANUAL = 'manual',
}

@Schema({ timestamps: true })
export class Cycle {
  @Prop({ required: true, trim: true, index: true })
  ownerDeviceId!: string;

  @Prop({ required: true, match: /^\d{4}-\d{2}-\d{2}$/ })
  startDate!: string;

  @Prop({ type: String, default: null, match: /^\d{4}-\d{2}-\d{2}$/ })
  endDate!: string | null;

  @Prop({ type: Number, min: 1, max: 90, default: null })
  periodLength!: number | null;

  @Prop({ type: Number, min: 1, max: 365, default: null })
  cycleLength!: number | null;

  @Prop({ enum: CycleSource, required: true, default: CycleSource.MANUAL })
  source!: CycleSource;
}

export type CycleDocument = HydratedDocument<Cycle>;
export const CycleSchema = SchemaFactory.createForClass(Cycle);

CycleSchema.index(
  { ownerDeviceId: 1 },
  {
    name: 'one_active_cycle_per_owner',
    unique: true,
    partialFilterExpression: { endDate: null },
  },
);
CycleSchema.index(
  { ownerDeviceId: 1, startDate: -1 },
  { name: 'cycles_by_owner_and_newest_start' },
);
