# Luna Cycle and Health Journal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement dashboard, cycle tracking, calendar, mood, symptoms, notes, daily care summary, and complete health journal across NestJS and Flutter.

**Architecture:** Backend stores cycles and one atomic daily log per owner/date, with a pure calculation service for predictions. Flutter repositories map REST DTOs into immutable domain entities and Riverpod controllers drive dashboard, calendar, and editors.

**Tech Stack:** NestJS, Mongoose, class-validator, Jest; Flutter, Riverpod, Dio, TableCalendar, intl.

## Global Constraints

- Dates are normalized as `yyyy-MM-dd` in Asia/Bangkok; calculations use date-only values, never device-local timestamps.
- An owner may have at most one active cycle and one daily log per date.
- Prediction uses configured defaults until two complete cycles exist, then averages at most six recent complete cycles.
- Ovulation is optional and estimated 14 days before the predicted next period; UI states clearly that predictions are estimates, not medical advice.

---

### Task 1: Pure cycle calculation domain

**Files:**
- Create: `Luna_BE/src/modules/cycle/cycle-calculator.service.ts`, `cycle.types.ts`
- Test: `Luna_BE/src/modules/cycle/cycle-calculator.service.spec.ts`

**Interfaces:**
- Produces: `calculateCycleSummary(cycles, settings, today): CycleSummary`; `buildCalendarDays(summary, month): CalendarDay[]`.

- [ ] Write table-driven failing tests for no history, one active cycle, six-cycle averaging, cross-month dates, leap day, and enabled/disabled ovulation.
- [ ] Run `npm test -- --runInBand cycle-calculator` and confirm failure.
- [ ] Implement date-only helpers using UTC noon normalization and integer day differences.
- [ ] Run focused tests and commit with `feat(be): add cycle prediction domain`.

### Task 2: Cycle persistence and endpoints

**Files:**
- Create: `Luna_BE/src/modules/cycle/cycle.module.ts`, `cycle.controller.ts`, `cycle.service.ts`
- Create: `Luna_BE/src/modules/cycle/schemas/cycle.schema.ts`
- Create: `Luna_BE/src/modules/cycle/dto/start-cycle.dto.ts`, `end-cycle.dto.ts`, `cycle-query.dto.ts`
- Test: `Luna_BE/src/modules/cycle/cycle.service.spec.ts`, `Luna_BE/test/cycle.e2e-spec.ts`

**Interfaces:**
- Produces: `start(owner, date)`, `end(owner, date)`, `findCurrent(owner)`, `list(owner, range)`, `prediction(owner, today)`.

- [ ] Write failing tests for start/end, duplicate active cycle, end-before-start, partner denial, and derived period/cycle length.
- [ ] Implement unique partial index for active owner cycles and indexes on `{ ownerDeviceId, startDate }`.
- [ ] Expose `POST /cycles/start`, `POST /cycles/end`, `GET /cycles`, `GET /cycles/current`, `GET /cycles/prediction` with owner authorization.
- [ ] Run unit/e2e tests, build, and commit with `feat(be): implement cycle tracking`.

### Task 3: Atomic daily log with mood, symptom, and note modules

**Files:**
- Create: `Luna_BE/src/modules/health/health.module.ts`, `daily-log.service.ts`, `schemas/daily-log.schema.ts`
- Create: `Luna_BE/src/modules/mood/*`, `Luna_BE/src/modules/symptom/*`, `Luna_BE/src/modules/note/*`
- Test: service specs for all four modules and `Luna_BE/test/daily-log.e2e-spec.ts`

**Interfaces:**
- Produces: `DailyLogService.upsertFields(owner, date, patch)` with `$set` only for supplied fields; mood/symptom/note controllers never overwrite neighboring fields.

- [ ] Write concurrency-oriented tests proving mood update preserves symptoms/note and note deletion only unsets note.
- [ ] Define enums for seven moods and ten requested symptoms; validate discomfort from 0 to 5.
- [ ] Implement `GET|PUT /moods/:date`, `GET|PUT /symptoms/:date`, `GET|PUT|DELETE /notes/:date`.
- [ ] Add unique `{ ownerDeviceId, date }` index, run all focused/e2e tests, and commit with `feat(be): add daily health logs`.

### Task 4: Dashboard, calendar, care suggestion, and journal queries

**Files:**
- Create: `Luna_BE/src/modules/calendar/calendar.module.ts`, `calendar.controller.ts`, `calendar.service.ts`
- Create: `Luna_BE/src/modules/health/health.controller.ts`, `dashboard.service.ts`, `journal.service.ts`
- Create: `Luna_BE/src/modules/scheduler/care-suggestion.service.ts`, `care-suggestion.seed.ts`
- Test: `calendar.service.spec.ts`, `dashboard.service.spec.ts`, `journal.service.spec.ts`

**Interfaces:**
- Produces: `GET /calendar?month=yyyy-MM`; `GET /health/dashboard?date=yyyy-MM-dd`; `GET /health/care/today`; `GET /health/journal?from&to&page&limit`.

- [ ] Write failing query tests for real/predicted/ovulation colors, active-period dashboard, no-data dashboard, privacy-filtered partner dashboard, deterministic daily care, and paginated journal.
- [ ] Implement query services using lean Mongo projections and cycle calculator; care selection hashes `date + pairId + audience` into the seeded list.
- [ ] Run tests/build and commit with `feat(be): add dashboard calendar and journal queries`.

### Task 5: Flutter owner health experience

**Files:**
- Create: `Luna_FE/lib/features/home/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/cycle/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/calendar/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/mood/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/symptom/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/note/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/health/{data,domain,presentation}/...`
- Test: repository/controller/widget tests for each feature

**Interfaces:**
- Consumes: cycle, calendar, daily-log, and health endpoints from Tasks 2–4.
- Produces: `HomePage`, `CyclePage`, `CycleCalendarPage`, `DailyLogSheet`, `HealthJournalPage` and typed Riverpod providers.

- [ ] Write failing mapper/controller tests using fixture JSON for empty, loading, success, unauthorized, and offline states.
- [ ] Implement repositories and immutable entities; invalidate dashboard/calendar/journal providers after mutations.
- [ ] Write failing widget tests for cycle start/end confirmation, calendar legend/day tap, mood single-select, symptom multi-select, note edit/delete, and journal timeline.
- [ ] Implement responsive Vietnamese UI with accessibility labels, prediction disclaimer, shared loading/empty/error widgets, and bottom navigation.
- [ ] Run `dart format lib test`, `flutter analyze`, `flutter test`, then commit with `feat(fe): implement cycle and health journal experience`.

### Task 6: Cycle/journal integration checkpoint

**Files:**
- Test: `Luna_BE/test/cycle-journal-flow.e2e-spec.ts`, `Luna_FE/integration_test/cycle_journal_test.dart`

**Interfaces:**
- Verifies: register owner → start cycle → save daily log → dashboard/calendar reflect changes → end cycle → journal retains history.

- [ ] Add backend end-to-end flow using memory MongoDB and assert exact response envelopes.
- [ ] Add Flutter integration flow using a deterministic fake API server.
- [ ] Run backend lint/test/build and Flutter analyze/test; fix only defects found by these checks.
- [ ] Commit with `test: verify cycle and journal flow`.

