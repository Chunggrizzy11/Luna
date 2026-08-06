import { ApiProperty, getSchemaPath } from '@nestjs/swagger';
import { CycleSource } from '../../modules/cycle/schemas/cycle.schema';
import { Mood, Symptom } from '../../modules/health/schemas/daily-log.schema';

const DATE_EXAMPLE = '2026-08-03';

class TimestampedEnvelopeDto {
  @ApiProperty({ format: 'date-time', example: '2026-08-03T10:30:00.000Z' })
  timestamp!: string;
}

export class CycleDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  startDate!: string;

  @ApiProperty({ type: String, format: 'date', nullable: true })
  endDate!: string | null;

  @ApiProperty({ type: Number, nullable: true, minimum: 1, maximum: 90 })
  periodLength!: number | null;

  @ApiProperty({ type: Number, nullable: true, minimum: 1, maximum: 365 })
  cycleLength!: number | null;

  @ApiProperty({ enum: CycleSource })
  source!: CycleSource;
}

export class CycleEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => CycleDto })
  data!: CycleDto;
}

export class NullableCycleEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => CycleDto, nullable: true })
  data!: CycleDto | null;
}

export class CycleListDataDto {
  @ApiProperty({ type: () => [CycleDto] })
  items!: CycleDto[];

  @ApiProperty({ minimum: 1, example: 1 })
  page!: number;

  @ApiProperty({ minimum: 1, maximum: 100, example: 20 })
  limit!: number;
}

export class CycleListEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => CycleListDataDto })
  data!: CycleListDataDto;
}

export class PeriodRangeDto {
  @ApiProperty({ format: 'date', example: '2026-07-06' })
  startDate!: string;

  @ApiProperty({ format: 'date', example: '2026-07-10' })
  endDate!: string;
}

export class CycleSummaryDto {
  @ApiProperty({ type: Number, nullable: true, minimum: 1 })
  currentCycleDay!: number | null;

  @ApiProperty()
  isPeriodActive!: boolean;

  @ApiProperty({ type: Number, nullable: true })
  daysUntilNextPeriod!: number | null;

  @ApiProperty({ minimum: 1, maximum: 365 })
  averageCycleLength!: number;

  @ApiProperty({ minimum: 1, maximum: 90 })
  averagePeriodLength!: number;

  @ApiProperty({ type: String, format: 'date', nullable: true })
  predictedPeriodStart!: string | null;

  @ApiProperty({ type: String, format: 'date', nullable: true })
  predictedPeriodEnd!: string | null;

  @ApiProperty({ type: String, format: 'date', nullable: true })
  ovulationDate!: string | null;

  @ApiProperty({ type: () => [PeriodRangeDto] })
  observedPeriods!: PeriodRangeDto[];
}

export class CycleSummaryEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => CycleSummaryDto })
  data!: CycleSummaryDto;
}

export class CalendarDayDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({
    enum: ['none', 'observed-period', 'predicted-period', 'ovulation'],
  })
  status!: string;

  @ApiProperty()
  isObservedPeriod!: boolean;

  @ApiProperty()
  isPredictedPeriod!: boolean;

  @ApiProperty()
  isOvulation!: boolean;
}

export class CalendarDataDto {
  @ApiProperty({ example: '2026-08', pattern: '^\\d{4}-\\d{2}$' })
  month!: string;

  @ApiProperty({ type: () => [CalendarDayDto] })
  days!: CalendarDayDto[];
}

export class CalendarEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => CalendarDataDto })
  data!: CalendarDataDto;
}

export class DailyLogDto {
  @ApiProperty({ enum: Mood, type: String, nullable: true })
  mood!: Mood | null;

  @ApiProperty({ enum: Symptom, isArray: true })
  symptoms!: Symptom[];

  @ApiProperty({ type: Number, nullable: true, minimum: 0, maximum: 5 })
  discomfortLevel!: number | null;

  @ApiProperty({ type: String, nullable: true, maxLength: 4000 })
  note!: string | null;
}

export class OwnerDashboardDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ enum: ['owner'] })
  relationship!: 'owner';

  @ApiProperty({ type: () => CycleSummaryDto })
  cycle!: CycleSummaryDto;

  @ApiProperty({ type: () => DailyLogDto })
  dailyLog!: DailyLogDto;
}

export class PartnerDashboardDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ enum: ['paired', 'unpaired'] })
  relationship!: 'paired' | 'unpaired';

  @ApiProperty({ type: () => CycleSummaryDto, nullable: true })
  cycle!: CycleSummaryDto | null;

  @ApiProperty({ type: () => DailyLogDto, nullable: true })
  dailyLog!: DailyLogDto | null;
}

export class DashboardEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({
    oneOf: [
      { $ref: getSchemaPath(OwnerDashboardDto) },
      { $ref: getSchemaPath(PartnerDashboardDto) },
    ],
  })
  data!: OwnerDashboardDto | PartnerDashboardDto;
}

export class CareSuggestionDto {
  @ApiProperty({ example: 'owner-rest' })
  id!: string;

  @ApiProperty({ example: 'Take a gentle pause' })
  title!: string;

  @ApiProperty()
  description!: string;
}

export class CareDataDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ enum: ['owner', 'paired', 'unpaired'] })
  relationship!: 'owner' | 'paired' | 'unpaired';

  @ApiProperty({ type: () => CareSuggestionDto, nullable: true })
  suggestion!: CareSuggestionDto | null;
}

export class CareEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => CareDataDto })
  data!: CareDataDto;
}

export class JournalEntryDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ enum: Mood, required: false })
  mood?: Mood;

  @ApiProperty({ enum: Symptom, isArray: true, required: false })
  symptoms?: Symptom[];

  @ApiProperty({ minimum: 0, maximum: 5, required: false })
  discomfortLevel?: number;

  @ApiProperty({ maxLength: 4000, required: false })
  note?: string;
}

export class JournalDataDto {
  @ApiProperty({ type: () => [JournalEntryDto] })
  items!: JournalEntryDto[];

  @ApiProperty({ minimum: 1, example: 1 })
  page!: number;

  @ApiProperty({ minimum: 1, maximum: 100, example: 20 })
  limit!: number;

  @ApiProperty()
  hasMore!: boolean;
}

export class JournalEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => JournalDataDto })
  data!: JournalDataDto;
}

export class MoodDataDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ enum: Mood, type: String, nullable: true })
  mood!: Mood | null;
}

export class MoodEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => MoodDataDto })
  data!: MoodDataDto;
}

export class SymptomDataDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ enum: Symptom, isArray: true })
  symptoms!: Symptom[];

  @ApiProperty({ type: Number, nullable: true, minimum: 0, maximum: 5 })
  discomfortLevel!: number | null;
}

export class SymptomEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => SymptomDataDto })
  data!: SymptomDataDto;
}

export class NoteDataDto {
  @ApiProperty({ format: 'date', example: DATE_EXAMPLE })
  date!: string;

  @ApiProperty({ type: String, nullable: true, maxLength: 4000 })
  note!: string | null;
}

export class NoteEnvelopeDto extends TimestampedEnvelopeDto {
  @ApiProperty({ type: () => NoteDataDto })
  data!: NoteDataDto;
}
