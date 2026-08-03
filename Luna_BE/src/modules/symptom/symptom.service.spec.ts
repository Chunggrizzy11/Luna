import type { DailyLogService } from '../health/daily-log.service';
import { Symptom } from '../health/schemas/daily-log.schema';
import { SymptomService } from './symptom.service';

const owner = { deviceId: 'owner-device' };

describe('SymptomService', () => {
  let dailyLogService: jest.Mocked<
    Pick<DailyLogService, 'findByDate' | 'upsertFields'>
  >;
  let service: SymptomService;

  beforeEach(() => {
    dailyLogService = { findByDate: jest.fn(), upsertFields: jest.fn() };
    service = new SymptomService(dailyLogService as unknown as DailyLogService);
  });

  it('projects an absent daily log as no symptoms and no discomfort level', async () => {
    dailyLogService.findByDate.mockResolvedValue(null);

    await expect(service.get(owner, '2026-08-03')).resolves.toEqual({
      date: '2026-08-03',
      symptoms: [],
      discomfortLevel: null,
    });
  });

  it('writes symptom fields together without supplying mood or note', async () => {
    dailyLogService.upsertFields.mockResolvedValue({
      date: '2026-08-03',
      symptoms: [Symptom.CRAMPS],
      discomfortLevel: 3,
    });

    await expect(
      service.update(owner, '2026-08-03', [Symptom.CRAMPS], 3),
    ).resolves.toEqual({
      date: '2026-08-03',
      symptoms: [Symptom.CRAMPS],
      discomfortLevel: 3,
    });
    expect(dailyLogService.upsertFields).toHaveBeenCalledWith(
      owner,
      '2026-08-03',
      { symptoms: [Symptom.CRAMPS], discomfortLevel: 3 },
    );
  });
});
