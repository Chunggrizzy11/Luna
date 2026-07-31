# Luna Statistics, Settings, Backup, and Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete statistics, settings, encrypted export/import, notification preferences, app lock, iPhone widget integration, seed data, and full UAT verification.

**Architecture:** Statistics are server-derived read models over cycles/daily logs. Versioned backup validates the complete payload before a MongoDB transaction/upsert. Device-specific settings remain separate from owner health data; the iOS widget receives only a minimal App Group dashboard snapshot.

**Tech Stack:** NestJS/Mongoose aggregation, JSON schema validation, Flutter fl_chart, file_picker/share_plus, local_auth, home_widget/WidgetKit, Jest and Flutter integration tests.

## Global Constraints

- Backup version is `1`; import validates fully before writing and never partially applies invalid data.
- Backup files containing health data are encrypted with AES-256-GCM using a key derived from a user-provided passphrase with Argon2id or PBKDF2-HMAC-SHA256 where Argon2id is unavailable.
- Widget snapshot contains only days-to-period, period-day, and care suggestion; no notes or symptom details.
- WidgetKit signing and App Group require the user's Apple Developer Team and therefore cannot be activated automatically.
- Atomic backup import requires MongoDB transactions; UAT setup configures the local database as single-node replica set `rs0`, which remains accessible from MongoDB Compass.

---

### Task 1: Statistics read models

**Files:**
- Create: `Luna_BE/src/modules/statistics/statistics.module.ts`, controller/service/types
- Test: `statistics.service.spec.ts`, `Luna_BE/test/statistics.e2e-spec.ts`

**Interfaces:**
- Produces: `GET /statistics/summary`, `/statistics/cycles`, `/statistics/trends?from&to`.

- [ ] Write failing aggregation tests for empty data, average cycle/period length, recent history ordering, mood frequency, symptom frequency, and monthly chart points.
- [ ] Implement scoped aggregation pipelines filtered by owner/pair and stable tie-breaking by enum order.
- [ ] Run focused/e2e tests and commit with `feat(be): add cycle and health statistics`.

### Task 2: Device settings and notification preferences

**Files:**
- Create: `Luna_BE/src/modules/settings/settings.module.ts`, controller/service/schema/DTOs
- Test: `settings.service.spec.ts`
- Create: `Luna_FE/lib/features/settings/{data,domain,presentation}/...`
- Test: Flutter settings repository/controller/widget tests

**Interfaces:**
- Produces: `GET|PUT /settings/me`; settings fields `defaultCycleLength`, `defaultPeriodLength`, `ovulationEnabled`, `notificationsEnabled`, reminder preferences, `themeMode`, `biometricLockEnabled`.

- [ ] Write failing backend validation/default/isolation tests and implement device-scoped upsert.
- [ ] Write failing Flutter theme/notification/biometric preference tests.
- [ ] Implement settings UI, bind theme provider, reschedule local notifications after changes, and use `local_auth` for optional app unlock.
- [ ] Run BE/FE tests and commit with `feat: add device settings and optional app lock`.

### Task 3: Versioned encrypted backup and atomic import

**Files:**
- Create: `Luna_BE/src/modules/health/backup.service.ts`, backup DTO/schema validator
- Create: `Luna_FE/lib/features/settings/data/backup_repository.dart`, `backup_crypto_service.dart`, backup UI
- Test: backend backup specs/e2e and Flutter crypto/controller tests

**Interfaces:**
- Produces: `GET /health/backup/export`; `POST /health/backup/import`; Flutter `.luna` encrypted file format `{ version, kdf, salt, nonce, ciphertext, tag }`.

- [ ] Write failing tests for round-trip export/import, wrong owner, unsupported version, invalid date/enums, duplicates, wrong passphrase, and tampered authentication tag.
- [ ] Implement backend canonical version-1 JSON export and transaction-based validated upsert.
- [ ] Add Flutter dependencies `cryptography`, `file_picker`, `share_plus`, `path_provider`; encrypt/decrypt only on device and never send passphrase to backend.
- [ ] Implement export/share and import/picker confirmation screens; invalidate all health providers after success.
- [ ] Run tests and commit with `feat: add encrypted health backup and restore`.

### Task 4: Flutter statistics and complete navigation

**Files:**
- Create: `Luna_FE/lib/features/statistics/{data,domain,presentation}/...`
- Modify: router and bottom navigation shell
- Test: mapper/controller/chart/widget tests

**Interfaces:**
- Consumes: statistics endpoints.
- Produces: summary cards, cycle history, mood/symptom rankings, and monthly line/bar charts.

- [ ] Write failing tests for empty/single/multiple data sets and accessible chart semantics.
- [ ] Implement repositories/entities/providers and fl_chart views with non-chart textual summaries.
- [ ] Confirm all requested screens are reachable for their permitted role and deep links redirect safely.
- [ ] Run analyze/tests and commit with `feat(fe): add statistics and complete app navigation`.

### Task 5: iPhone WidgetKit bridge

**Files:**
- Create: `Luna_FE/lib/shared/services/widget_snapshot_service.dart`
- Modify: `Luna_FE/ios/Runner/Runner.entitlements`, `AppDelegate.swift`, Podfile/project settings as supported
- Create: `Luna_FE/ios/LunaWidget/LunaWidget.swift`, `Info.plist`, extension entitlements
- Test: Dart snapshot service test; Swift timeline/provider test when Xcode is available

**Interfaces:**
- Produces App Group keys `daysUntilNextPeriod`, `periodDay`, `careTitle`, `updatedAt`; group ID `group.com.luna.shared` as a documented default.

- [ ] Add `home_widget` dependency and write failing Dart serialization/update tests.
- [ ] Implement minimal snapshot writer invoked after dashboard refresh or cycle update.
- [ ] Implement SwiftUI small/medium widgets with stale-data state and no sensitive details.
- [ ] Document manual Apple Team, bundle ID, App Group, signing, and extension target steps; do not claim device verification without macOS/Xcode.
- [ ] Run Flutter tests and commit with `feat(ios): add Luna dashboard widget bridge`.

### Task 6: Seed UAT data and operational documentation

**Files:**
- Create: `Luna_BE/src/database/seeds/uat.seed.ts`, `Luna_BE/scripts/seed-uat.ts`
- Create: `E:/Luna/README.md`, update project READMEs and `.env.example`
- Test: `uat.seed.spec.ts`

**Interfaces:**
- Produces idempotent care suggestions and optional deterministic demo owner/partner/cycles/logs guarded by `ENABLE_UAT_SEED=true`.

- [ ] Write failing idempotency test and implement upserts by stable keys.
- [ ] Document MongoDB Community installation because `mongod` is absent, authorization setup, Compass connection, emulator/physical-device API URLs, Firebase credential placement, and common troubleshooting.
- [ ] Run seed twice and assert counts do not change.
- [ ] Commit with `docs: add Luna UAT setup and seed workflow`.

### Task 7: Full acceptance and security verification

**Files:**
- Create: `Luna_BE/test/luna-acceptance.e2e-spec.ts`
- Create: `Luna_FE/integration_test/luna_acceptance_test.dart`
- Create: `docs/uat-checklist.md`, `docs/security-checklist.md`

**Interfaces:**
- Verifies all 17 requested feature groups and security decisions.

- [ ] Add acceptance assertions for owner and partner dashboards, cycle lifecycle, calendar colors, seven moods, ten symptoms, notes, statistics, pairing, partner notifications, daily care, checklist, notification center, settings, backup, sync, journal, and widget snapshot.
- [ ] Add security assertions for token redaction, revoked access, wrong-pair object IDs, pairing expiry/attempts, note privacy, payload validation, and production HTTP rejection.
- [ ] Run `npm run lint`, all Jest unit/e2e tests, `npm run build`, `dart format --output=none --set-exit-if-changed`, `flutter analyze`, all Flutter tests, and `flutter build apk --debug`.
- [ ] Record exact pass/fail evidence and external limitations (MongoDB service, Firebase credentials, macOS signing) in `docs/uat-checklist.md`.
- [ ] Commit with `test: complete Luna full-stack UAT acceptance suite`.
