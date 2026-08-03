# Task 6 — Cycle/journal integration checkpoint report

## Scope delivered

- Added `Luna_BE/test/cycle-journal-flow.e2e-spec.ts`.
  - Creates the real `AppModule`, global validation/interceptor/filter stack, and an isolated `MongoMemoryReplSet` database.
  - Executes register owner → start cycle → mood/symptom/note → dashboard/calendar → end cycle → journal.
  - Checks the exact success envelope keys (`data`, `timestamp`) and ISO timestamp on every response used in the flow.
  - Checks persisted owner-only dashboard, calendar, and journal projections.
- Added `Luna_FE/integration_test/cycle_journal_test.dart` with an in-process deterministic HTTP server.
  - Uses production `ApiClient`, repositories, Riverpod providers/controllers, and `OwnerShell` UI rather than repository/unit mocks.
  - Proves UI mutations reach the fake API, dashboard/calendar/journal invalidation refetches persisted state, and the journal retains the completed daily entry after cycle end.
- Added the Flutter SDK `integration_test` dev dependency and lockfile entries.

## Red/green and fixes

1. `npm run test:e2e -- --runInBand test/cycle-journal-flow.e2e-spec.ts`
   - Initial result: failed at the calendar assertion because the test expected only `date`/`status`, while the real calendar payload also includes `isObservedPeriod`, `isPredictedPeriod`, and `isOvulation`.
   - Fix: made the check select the observed day and assert the complete real status shape. No production code defect was found.
2. Re-ran the same command: 1 suite / 1 test passed.

## Verification commands and results

Backend, working directory `Luna_BE`:

```text
npx prettier --write test/cycle-journal-flow.e2e-spec.ts
=> formatted the new test

npm run lint
=> exit 0

npm test -- --runInBand
=> 15 suites passed, 89 tests passed

npm run test:e2e -- --runInBand
=> 8 suites passed, 29 tests passed
=> expected existing test diagnostic: "Unhandled HTTP 500: predecessor write failed"

npm run build
=> exit 0

npm audit --omit=dev
=> found 0 vulnerabilities
```

Flutter, working directory `Luna_FE`:

```text
flutter pub get
=> exit 0; added SDK integration_test transitive dependencies

dart format integration_test\\cycle_journal_test.dart
=> 1 file formatted

flutter analyze integration_test\\cycle_journal_test.dart
=> No issues found

dart format --set-exit-if-changed lib test integration_test
=> Formatted 101 files (0 changed)

flutter analyze
=> No issues found

flutter test
=> All tests passed (77 tests)
```

## Integration runner limitation

The integration test source compiles under `flutter analyze`, but it could not be executed on the available Windows desktop target:

```text
flutter test -d windows integration_test\\cycle_journal_test.dart
=> Failed to load test: Building with plugins requires symlink support.
=> Flutter requests Windows Developer Mode: start ms-settings:developers
```

An unspecified `flutter test integration_test\\cycle_journal_test.dart` also refused to choose automatically among Windows, Chrome, and Edge. Chrome/Edge are not an equivalent fallback because this deterministic test intentionally uses `dart:io` `HttpServer`; enable Windows Developer Mode (or run on an Android/iOS desktop-capable runner) to execute it end-to-end.

## Self-review

- Only checkpoint tests, the required test dependency, and this report changed; no feature expansion or production-code changes.
- Backend state is isolated by a unique in-memory ReplicaSet database and all environment variables are restored.
- Frontend fake state is recreated per test and exercised only through the production HTTP/repository/provider/controller path.
- `git diff --check` is clean.

## Concerns

- The only outstanding validation is runtime execution of the Flutter integration target, blocked by the host's Developer Mode/symlink policy; static analysis and the full non-integration Flutter suite are clean.
