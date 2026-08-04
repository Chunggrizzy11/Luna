import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { BusinessDateClock } from '../../common/date/business-date';
import type { AuthenticatedDevice } from '../../common/interfaces/authenticated-device.interface';
import {
  DashboardService,
  type AudienceResolution,
} from '../health/dashboard.service';
import {
  CARE_SUGGESTION_SEEDS,
  type CareSuggestionSeed,
} from './care-suggestion.seed';

export interface CareSuggestionResponse {
  date: string;
  relationship: 'owner' | 'paired' | 'unpaired';
  suggestion: Pick<CareSuggestionSeed, 'id' | 'title' | 'description'> | null;
}

@Injectable()
export class CareSuggestionService {
  constructor(
    private readonly dashboardService: DashboardService,
    private readonly businessDate: BusinessDateClock,
  ) {}

  async getToday(device: AuthenticatedDevice): Promise<CareSuggestionResponse> {
    const date = this.businessDate.today();
    const audience = await this.dashboardService.resolveAudience(device);
    if (audience.relationship === 'unpaired') {
      return { date, relationship: 'unpaired', suggestion: null };
    }
    return {
      date,
      relationship: audience.relationship,
      suggestion: this.select(date, audience),
    };
  }

  private select(
    date: string,
    audience: AudienceResolution,
  ): Pick<CareSuggestionSeed, 'id' | 'title' | 'description'> {
    if (!audience.pairId) {
      throw new Error('Paired care suggestions require a pair id.');
    }
    const candidates = CARE_SUGGESTION_SEEDS.filter(
      (suggestion) => suggestion.audience === audience.audience,
    );
    const hash = createHash('sha256')
      .update(`${date}${audience.pairId}${audience.audience}`)
      .digest();
    const index = hash.readUInt32BE(0) % candidates.length;
    const suggestion = candidates[index];
    if (!suggestion) throw new Error('No care suggestion is configured.');
    return {
      id: suggestion.id,
      title: suggestion.title,
      description: suggestion.description,
    };
  }
}
