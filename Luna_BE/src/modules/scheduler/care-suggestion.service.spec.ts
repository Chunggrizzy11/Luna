import { DeviceRole, DeviceStatus } from '../device/schemas/device.schema';
import { DashboardService } from '../health/dashboard.service';
import { CARE_SUGGESTION_SEEDS } from './care-suggestion.seed';
import { CareSuggestionService } from './care-suggestion.service';

describe('CareSuggestionService', () => {
  const pairedOwner = {
    deviceId: 'owner-device',
    role: DeviceRole.OWNER,
    status: DeviceStatus.ACTIVE,
    pairId: 'pair-1',
  };

  it('seeds all eight requested Vietnamese care actions for each audience', () => {
    for (const audience of ['owner', 'partner'] as const) {
      expect(
        CARE_SUGGESTION_SEEDS.filter(
          (suggestion) => suggestion.audience === audience,
        ).map((suggestion) => suggestion.id),
      ).toEqual([
        `${audience}-message`,
        `${audience}-drink`,
        `${audience}-chocolate`,
        `${audience}-movie`,
        `${audience}-walk`,
        `${audience}-hot-meal`,
        `${audience}-flowers`,
        `${audience}-song`,
      ]);
    }
    expect(
      CARE_SUGGESTION_SEEDS.find(
        (suggestion) => suggestion.id === 'owner-drink',
      )?.title,
    ).toBe('Mua đồ uống ấm');
    expect(
      CARE_SUGGESTION_SEEDS.find(
        (suggestion) => suggestion.id === 'owner-chocolate',
      )?.title,
    ).toBe('Mua một chút socola');
  });

  it('selects the same Vietnamese owner suggestion for the same date and pair', async () => {
    const dashboard = {
      resolveAudience: jest.fn().mockResolvedValue({
        audience: 'owner',
        pairId: 'pair-1',
        relationship: 'owner',
      }),
    } as unknown as DashboardService;
    const service = new CareSuggestionService(dashboard, () => '2026-03-12');

    const [first, second] = await Promise.all([
      service.getToday(pairedOwner),
      service.getToday(pairedOwner),
    ]);

    expect(first).toEqual(second);
    expect(first.date).toBe('2026-03-12');
    expect(first.relationship).toBe('owner');
    expect(first.suggestion).not.toBeNull();
    if (!first.suggestion) throw new Error('Expected a care suggestion.');
    expect(first.suggestion.id).toEqual(expect.any(String));
    expect(first.suggestion.title).toEqual(expect.any(String));
    expect(first.suggestion.description).toEqual(expect.any(String));
  });

  it('returns an unpaired state instead of attempting a partner suggestion', async () => {
    const dashboard = {
      resolveAudience: jest.fn().mockResolvedValue({
        audience: 'partner',
        relationship: 'unpaired',
      }),
    } as unknown as DashboardService;
    const service = new CareSuggestionService(dashboard, () => '2026-03-12');

    await expect(
      service.getToday({ ...pairedOwner, role: DeviceRole.PARTNER }),
    ).resolves.toEqual({
      date: '2026-03-12',
      relationship: 'unpaired',
      suggestion: null,
    });
  });
});
