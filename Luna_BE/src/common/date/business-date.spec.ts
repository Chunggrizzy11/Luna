import { BangkokBusinessDate } from './business-date';

describe('BangkokBusinessDate', () => {
  it.each([
    ['2026-08-03T16:59:59.999Z', '2026-08-03'],
    ['2026-08-03T17:00:00.000Z', '2026-08-04'],
  ])('formats %s as Bangkok business date %s', (instant, expected) => {
    const businessDate = new BangkokBusinessDate(() => new Date(instant));

    expect(businessDate.today()).toBe(expected);
    expect(businessDate.formatInstant(new Date(instant))).toBe(expected);
  });
});
