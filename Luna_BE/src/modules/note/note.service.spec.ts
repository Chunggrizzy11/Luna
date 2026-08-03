import type { DailyLogService } from '../health/daily-log.service';
import { NoteService } from './note.service';

const owner = { deviceId: 'owner-device' };

describe('NoteService', () => {
  let dailyLogService: jest.Mocked<
    Pick<DailyLogService, 'findByDate' | 'upsertFields' | 'unsetFields'>
  >;
  let service: NoteService;

  beforeEach(() => {
    dailyLogService = {
      findByDate: jest.fn(),
      upsertFields: jest.fn(),
      unsetFields: jest.fn(),
    };
    service = new NoteService(dailyLogService as unknown as DailyLogService);
  });

  it('projects an absent daily log as a null note for the requested date', async () => {
    dailyLogService.findByDate.mockResolvedValue(null);

    await expect(service.get(owner, '2026-08-03')).resolves.toEqual({
      date: '2026-08-03',
      note: null,
    });
  });

  it('deletes a note through a field-only unset and returns null', async () => {
    dailyLogService.unsetFields.mockResolvedValue({ date: '2026-08-03' });

    await expect(service.remove(owner, '2026-08-03')).resolves.toEqual({
      date: '2026-08-03',
      note: null,
    });
    expect(dailyLogService.unsetFields).toHaveBeenCalledWith(
      owner,
      '2026-08-03',
      ['note'],
    );
  });
});
