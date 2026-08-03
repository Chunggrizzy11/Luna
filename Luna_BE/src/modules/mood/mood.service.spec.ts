import type { DailyLogService } from '../health/daily-log.service';
import { Mood } from '../health/schemas/daily-log.schema';
import { MoodService } from './mood.service';

const owner = { deviceId: 'owner-device' };

describe('MoodService', () => {
  let dailyLogService: jest.Mocked<
    Pick<DailyLogService, 'findByDate' | 'upsertFields'>
  >;
  let service: MoodService;

  beforeEach(() => {
    dailyLogService = { findByDate: jest.fn(), upsertFields: jest.fn() };
    service = new MoodService(dailyLogService as unknown as DailyLogService);
  });

  it('projects an absent daily log as a nullable mood for the requested date', async () => {
    dailyLogService.findByDate.mockResolvedValue(null);

    await expect(service.get(owner, '2026-08-03')).resolves.toEqual({
      date: '2026-08-03',
      mood: null,
    });
  });

  it('writes a mood through the field-only daily-log upsert', async () => {
    dailyLogService.upsertFields.mockResolvedValue({
      date: '2026-08-03',
      mood: Mood.HAPPY,
    });

    await expect(
      service.update(owner, '2026-08-03', Mood.HAPPY),
    ).resolves.toEqual({
      date: '2026-08-03',
      mood: Mood.HAPPY,
    });
    expect(dailyLogService.upsertFields).toHaveBeenCalledWith(
      owner,
      '2026-08-03',
      { mood: Mood.HAPPY },
    );
  });
});
