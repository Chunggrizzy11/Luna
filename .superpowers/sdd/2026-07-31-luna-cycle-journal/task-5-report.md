# Task 5 Report — Flutter owner health experience

## Delivered

- Added immutable typed cycle, calendar, dashboard, care, journal, mood, symptom, and note models that consume the exact Task 2–4 global `data` envelopes and wire enums.
- Extended the shared `ApiClient` with typed `PUT` and `DELETE` support while preserving the existing Dio auth, redacted logging, and `ErrorMapper` behavior.
- Added focused repositories for `/cycles`, `/calendar`, `/moods/:date`, `/symptoms/:date`, `/notes/:date`, and `/health/{dashboard,care/today,journal}`.
- Added Riverpod providers/controllers for dashboard, current cycle, month calendar, daily care, daily log, and journal. Successful cycle/daily-log mutations invalidate dashboard, calendar, journal, and current-cycle projections.
- Replaced the identified-device placeholder route with a responsive owner shell and Vietnamese bottom navigation: Tổng quan, Lịch, Nhật ký, Chu kỳ.
- Added dashboard cycle summary, today's health snapshot and daily care; confirmed cycle start/end with prediction disclaimer; semantic month calendar legend/day interactions; seven-mood single-select, ten-symptom multi-select, discomfort 0–5, note edit/delete; and newest-first health journal timeline.
- Reused existing theme colors, shared loading/empty/error/card/button/dialog/bottom-sheet widgets, AppRouter, Dio token injection, and secure identity bootstrap. No dependency was added.

## TDD evidence

- `flutter test test/features/health/health_models_test.dart test/features/health/health_repository_test.dart`
  - RED: compilation failed because the typed models/repository did not exist.
  - GREEN: mapper/offline/401 tests passed.
- `flutter test test/core/network/api_client_test.dart --plain-name "put and delete decode global envelopes with the intended verbs"`
  - RED: `ApiClient.put` and `ApiClient.delete` were undefined.
  - GREEN: exact PUT/DELETE verb/envelope test passed.
- `flutter test test/features/health/health_controllers_test.dart`
  - RED: controller files/types did not exist.
  - GREEN: 3/3 mutation, invalidation, unauthorized, and offline controller tests passed.
- `flutter test test/features/health/owner_experience_widget_test.dart`
  - RED: requested pages/sheet did not exist.
  - GREEN: 5/5 start/end confirmation, calendar legend/day tap, mood/symptom/note, and timeline interactions passed.

## Final verification

Executed from `Luna_FE`:

- `dart format lib test` → `Formatted 94 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!`, 52 tests, exit 0.
- `git diff --check` → no whitespace errors (Git only reported the repository's LF→CRLF checkout warning).

## Self-review

- Contract review: endpoint paths, required dashboard date/month queries, nullable current cycle, Task 4 journal pagination shape, seven moods, ten symptoms, and discomfort bounds match backend source/e2e fixtures.
- State review: shared typed failures reach retryable error UI; loading/empty/success states use shared widgets; controller errors preserve `UnauthorizedFailure` and `NetworkFailure` rather than converting them to strings.
- Security review: credentials remain exclusively in the existing Dio authorization interceptor; no token is persisted, logged, passed in query/body, or represented by feature models.
- Accessibility review: destructive note action has a tooltip/semantic label; moods expose selected semantic state; discomfort slider exposes range/value; calendar days expose status labels; journal entries expose date labels.
- Responsive review: dashboard constrains wide content and changes daily/care cards from a row to a stack below 620 logical pixels; all detail screens remain scrollable.

## Concerns

- Platform builds were not part of the Task 5 verification command set and were not run. Flutter analyzer and the complete widget/unit suite are clean; physical-device visual QA remains useful for final release acceptance.
- The server currently has ovulation disabled in its default cycle settings, so the green legend is implemented and tested with deterministic fixtures but appears only when the backend returns `ovulation` days.

## Review Fix Round 1/5

### Delivered

- Removed the daily-log mutation controller's `autoDispose` lifecycle hazard and made the sheet actively watch mutation state for its entire lifetime.
- Added typed inline feedback for offline, unauthorized, validation, and unknown mutation failures. Save UI now always clears its busy state via `try/finally`; unauthorized feedback directs the user to re-register the device.
- Moved projection invalidation into mutation `finally`, so dashboard/calendar/journal/current-cycle data refreshes even when concurrent daily-log writes partially persist before another write fails. The UI explicitly warns that some data may already have been saved.
- Routed `/home` from the persisted `DeviceIdentity.role`: owners receive `OwnerShell`; partners and any impossible null identity receive a privacy-safe `PartnerPendingPage` that never mounts owner providers.
- Replaced the cached `nowProvider` value with an injectable `Clock` and `LocalDayController`. Dashboard and daily-care providers now refresh at the next local midnight; date-sensitive actions call the clock at action time.
- Changed the daily-log heading from a hard-coded “today” label to `Nhật ký ngày dd/MM/yyyy` using the selected calendar date.
- Added complete behavioral coverage for exact `{data,timestamp}` repository fixtures, endpoints, methods, query parameters, payloads, decoding, provider lifecycle, partial failures, deterministic midnight rollover, loading/empty/offline/401 widgets, bottom navigation, and persisted-role routing.

### TDD evidence

- `flutter test test/features/health/health_controllers_test.dart`
  - RED: delayed mutation reproduced `Tried to use DailyLogController after dispose`; partial failure expected one invalidation but observed zero.
  - GREEN: delayed lifecycle and partial-write invalidation tests pass.
- `flutter test test/features/health/day_rollover_test.dart test/core/router/app_router_test.dart test/features/health/owner_experience_widget_test.dart`
  - RED: missing `LocalDayController`, `PartnerPendingPage`, `AppRouter.homeForIdentity`, historical-date label, and mutation error rendering.
  - GREEN: rollover, persisted owner/partner routing, historical date, and save-state feedback pass.
- `flutter test test/features/health/owner_repositories_contract_test.dart`
  - GREEN: 4 contract groups cover cycle, calendar, mood, symptom, note, dashboard, care, and journal envelopes/requests.
- `flutter test test/features/health/owner_states_widget_test.dart`
  - GREEN: 7 widget-state groups cover loading, empty, offline, 401, owner navigation, partner privacy, and mutation feedback.

### Final verification

Executed from `Luna_FE` after all review fixes:

- `dart format lib test` → `Formatted 99 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!`, 70 tests, exit 0.
- `git diff --check` → no whitespace errors; only the repository's existing LF→CRLF checkout warnings were emitted.

### Self-review and concerns

- Confirmed date-bound providers depend on the rollover state while action dates evaluate the injected clock at tap time, eliminating both midnight-stale query and mutation dates.
- Confirmed partial failures retain the original typed `Failure`, invalidate projections once, keep the sheet open, reset loading state, and present the partial-save warning.
- Confirmed the partner destination contains no owner repository/provider references and the actual router builder consumes `identityState.identity` rather than a caller-supplied role.
- No new package dependency or credential-handling path was introduced.
- Platform builds remain outside the requested verification set; physical-device layout/rollover QA remains a release acceptance concern.
