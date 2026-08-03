export interface FoundationCleanupActions {
  closeApp: () => void | Promise<unknown>;
  stopMongo: () => void | Promise<unknown>;
  restoreEnvironment: () => void;
}

export async function cleanupFoundationE2e(
  actions: FoundationCleanupActions,
): Promise<void> {
  const errors: unknown[] = [];

  try {
    try {
      await actions.closeApp();
    } catch (error) {
      errors.push(error);
    }

    try {
      await actions.stopMongo();
    } catch (error) {
      errors.push(error);
    }
  } finally {
    try {
      actions.restoreEnvironment();
    } catch (error) {
      errors.push(error);
    }
  }

  if (errors.length > 0) {
    throw new AggregateError(errors, 'Foundation e2e cleanup failed');
  }
}
