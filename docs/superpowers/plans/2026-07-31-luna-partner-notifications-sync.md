# Luna Partner, Notifications, and Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement secure two-device pairing, partner dashboard/checklist, notification center, scheduled care notifications, FCM adapter, and Socket.IO synchronization.

**Architecture:** Pairing uses a hashed single-use eight-character secret or QR payload, a five-minute TTL, five-attempt lockout, and throttled endpoints. Domain services create durable notification records first; optional FCM and realtime adapters deliver them without becoming the source of truth.

**Tech Stack:** NestJS Throttler, Mongoose TTL indexes, Socket.IO, Firebase Admin adapter; Flutter Riverpod, Dio, socket_io_client, mobile_scanner, local notifications.

## Global Constraints

- Pairing secret expires after five minutes, is single-use, and locks after five failed attempts.
- Owner health notes never appear in partner responses, logs, push payloads, or socket payloads.
- Socket payloads contain resource ID, change kind, and `updatedAt`; clients refetch canonical REST data.
- Missing Firebase credentials disables remote delivery without preventing record creation or local UAT tests.

---

### Task 1: Secure pairing and unpairing

**Files:**
- Create: `Luna_BE/src/modules/partner/partner.module.ts`, `partner.controller.ts`, `partner.service.ts`
- Create: `Luna_BE/src/modules/partner/schemas/pair.schema.ts`
- Create: pairing DTOs and `Luna_BE/src/common/utils/pairing-code.util.ts`
- Test: `partner.service.spec.ts`, `Luna_BE/test/partner.e2e-spec.ts`

**Interfaces:**
- Produces: `createCode(owner): PairingOffer`; `join(partner, code): PairStatus`; `status(device)`; `unpair(owner)`.

- [ ] Write failing tests for eight-character alphabet, hash-only persistence, TTL, one-time use, fifth-attempt lock, owner/partner role validation, and unpair token access.
- [ ] Implement Pair schema with TTL/compound indexes and constant-time hash comparison; never return raw pair IDs as authorization credentials.
- [ ] Expose `POST /partners/codes`, `POST /partners/join`, `GET /partners/status`, `DELETE /partners/unpair`; add per-device/IP throttling.
- [ ] Run tests/build and commit with `feat(be): add secure two-device pairing`.

### Task 2: Partner checklist and privacy projection

**Files:**
- Create: `Luna_BE/src/modules/partner/schemas/checklist.schema.ts`, `checklist.service.ts`, checklist DTOs
- Modify: `Luna_BE/src/modules/health/dashboard.service.ts`
- Test: `checklist.service.spec.ts`, `partner-privacy.e2e-spec.ts`

**Interfaces:**
- Produces: `GET|PUT /checklists/:date`; partner dashboard projection `{ phase, daysUntilNextPeriod, discomfortBand, careSuggestion }`.

- [ ] Write failing tests for eight checklist keys, idempotent upsert, owner write denial, wrong-pair access denial, and complete absence of note text in partner JSON.
- [ ] Implement unique `{ pairId, partnerDeviceId, date }` checklist and role-scoped queries.
- [ ] Run privacy-focused tests and commit with `feat(be): add partner checklist and privacy projection`.

### Task 3: Durable notifications and scheduler rules

**Files:**
- Create: `Luna_BE/src/modules/notification/notification.module.ts`, controller/service/schema/DTOs
- Create: `Luna_BE/src/modules/scheduler/scheduler.module.ts`, scheduler.service.ts, notification-rules.service.ts
- Create: `Luna_BE/src/modules/notification/fcm.adapter.ts`, `notification-delivery.interface.ts`
- Test: notification and scheduler specs

**Interfaces:**
- Produces: notification CRUD; `evaluatePair(pairId, date): NotificationCommand[]`; `NotificationDelivery.send(device, notification)`.

- [ ] Write failing tests for pre-period, first day, high discomfort, end-period, hydration/log reminders, and dedupe by `{ recipientDeviceId, type, scheduledDate }`.
- [ ] Implement durable records and read/delete endpoints before delivery adapters.
- [ ] Implement Firebase Admin adapter loaded only when service-account environment values exist; use a no-op adapter otherwise.
- [ ] Add cron-safe scheduler with distributed dedupe in MongoDB; run tests/build and commit with `feat(be): add Luna notification rules`.

### Task 4: Socket.IO authenticated synchronization

**Files:**
- Create: `Luna_BE/src/gateway/socket.gateway.ts`, `sync-events.service.ts`
- Modify: cycle, daily-log, checklist, notification, settings, and partner services to publish after successful writes
- Test: `socket.gateway.spec.ts`, `Luna_BE/test/sync.e2e-spec.ts`

**Interfaces:**
- Produces namespace `/sync`; events `cycle.updated`, `daily-log.updated`, `checklist.updated`, `notification.created`, `settings.updated`, `pair.updated`; `GET /health/sync/changes?since=`.

- [ ] Write failing tests for token handshake, room isolation by device/pair, forbidden note fields, disconnect/reconnect, and change feed ordering.
- [ ] Implement gateway auth through `DeviceService.authenticate`, sanitized event DTOs, and capped change query.
- [ ] Run socket/e2e tests and commit with `feat(be): add authenticated realtime sync`.

### Task 5: Flutter pairing, partner care, notifications, and socket refresh

**Files:**
- Create: `Luna_FE/lib/features/partner/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/notification/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/features/daily_care/{data,domain,presentation}/...`
- Create: `Luna_FE/lib/core/notification/fcm_service.dart`, `local_notification_service.dart`, `notification_handler.dart`, `notification_permission.dart`
- Create: `Luna_FE/lib/shared/services/sync_service.dart`
- Test: controllers, repositories, and widget tests

**Interfaces:**
- Consumes: pairing/checklist/notification endpoints and `/sync` events.
- Produces: pairing code/QR screens, partner dashboard, daily-care card, checklist page, notification center, reconnect refresh coordinator.

- [ ] Add dependencies `mobile_scanner`, `qr_flutter`, `flutter_local_notifications`, `firebase_core`, `firebase_messaging`; attempt Firebase initialization only when native platform configuration exists, catch the missing-configuration error, and keep notification center/local reminders active.
- [ ] Write failing tests for code create/join/expiry, QR parsing, checklist toggle rollback, read/delete notification, partner privacy DTO, and socket-triggered provider invalidation.
- [ ] Implement repositories/controllers/UI and local reminder scheduling; show actionable setup message when camera/notification permission is denied.
- [ ] Run analyze/tests and commit with `feat(fe): add partner care notifications and realtime sync`.

### Task 6: Two-device integration checkpoint

**Files:**
- Test: `Luna_BE/test/two-device-flow.e2e-spec.ts`, `Luna_FE/integration_test/two_device_test.dart`

**Interfaces:**
- Verifies: two registrations → pair → owner log/cycle → partner sanitized update → checklist → notification → unpair blocks access.

- [ ] Implement exact backend scenario and assert no note leakage in REST/socket/push command payloads.
- [ ] Implement Flutter dual-client fake-server scenario for provider refresh and screen state.
- [ ] Run all BE/FE verification commands and commit with `test: verify secure two-device experience`.
