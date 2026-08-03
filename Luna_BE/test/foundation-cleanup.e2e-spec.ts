import { cleanupFoundationE2e } from './foundation-e2e-cleanup';

describe('foundation e2e cleanup', () => {
  it('restores the environment and attempts every resource cleanup when both fail', async () => {
    const calls: string[] = [];

    await expect(
      cleanupFoundationE2e({
        closeApp: () => {
          calls.push('app');
          throw new Error('app cleanup failed');
        },
        stopMongo: () => {
          calls.push('mongo');
          throw new Error('mongo cleanup failed');
        },
        restoreEnvironment: () => {
          calls.push('env');
        },
      }),
    ).rejects.toThrow(AggregateError);

    expect(calls).toEqual(['app', 'mongo', 'env']);
  });
});
