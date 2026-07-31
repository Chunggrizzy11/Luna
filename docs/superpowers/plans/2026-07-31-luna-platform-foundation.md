# Luna Platform Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create runnable Flutter and NestJS projects with MongoDB UAT configuration, shared contracts, anonymous device authentication, secure token storage, themes, routing, networking, and onboarding.

**Architecture:** `Luna_BE` is a NestJS modular monolith whose global guard resolves an authenticated device from an opaque token. `Luna_FE` is feature-first, uses Riverpod/GoRouter/Dio, stores secrets in Keychain/Keystore, and bootstraps an anonymous device without a login screen.

**Tech Stack:** Flutter 3.44.2, Dart 3.12.2, Riverpod, GoRouter, Dio, flutter_secure_storage, NestJS 11, Node.js 22.11.0, TypeScript, Mongoose, MongoDB.

## Global Constraints

- UAT database URI is `mongodb://127.0.0.1:27017/luna_uat`; MongoDB server must be installed separately because `mongod` is not currently on PATH.
- Flutter never connects directly to MongoDB.
- Device tokens are 256-bit random values returned once, stored only in Keychain/Keystore, and persisted server-side only as SHA-256 hashes.
- Production rejects plain HTTP; local UAT may allow it only when `ALLOW_INSECURE_HTTP=true`.
- Vietnamese is the default locale; all dates sent to APIs use `yyyy-MM-dd` in Asia/Bangkok.

---

### Task 1: Scaffold both runnable applications

**Files:**
- Create: `Luna_FE/pubspec.yaml`, Flutter platform folders, `Luna_FE/lib/main.dart`, `Luna_FE/lib/app.dart`
- Create: `Luna_BE/package.json`, `Luna_BE/tsconfig.json`, `Luna_BE/src/main.ts`, `Luna_BE/src/app.module.ts`
- Create: all user-requested empty directories under `Luna_FE/lib` and `Luna_BE/src`

**Interfaces:**
- Produces: Flutter application `LunaApp`; NestJS root module `AppModule` listening on `PORT`.

- [ ] **Step 1: Scaffold Flutter and record a failing smoke test**

Run:

```powershell
Set-Location E:\Luna\Luna_FE
flutter create --project-name luna_fe --org com.luna .
```

Replace `test/widget_test.dart` with a test that pumps `LunaApp` and expects text `Luna`.

- [ ] **Step 2: Add Flutter dependencies and verify the smoke test initially fails**

```powershell
flutter pub add flutter_riverpod go_router dio connectivity_plus flutter_secure_storage shared_preferences intl socket_io_client table_calendar fl_chart equatable json_annotation
flutter pub add --dev build_runner json_serializable mocktail
flutter test test/widget_test.dart
```

Expected: FAIL because `LunaApp` is not defined yet.

- [ ] **Step 3: Implement `main.dart` and `app.dart` minimally**

```dart
void main() => runApp(const ProviderScope(child: LunaApp()));

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Luna',
    home: const Scaffold(body: Center(child: Text('Luna'))),
  );
}
```

- [ ] **Step 4: Scaffold NestJS and add runtime dependencies**

```powershell
Set-Location E:\Luna\Luna_BE
npx @nestjs/cli@latest new . --package-manager npm --skip-git --strict
npm install @nestjs/config @nestjs/mongoose mongoose @nestjs/swagger class-validator class-transformer helmet compression @nestjs/throttler bcrypt
npm install --save-dev mongodb-memory-server supertest @types/supertest
```

- [ ] **Step 5: Run baseline tests**

```powershell
flutter test
Set-Location E:\Luna\Luna_BE
npm test -- --runInBand
npm run build
```

- [ ] **Step 6: Initialize repository and commit**

```powershell
Set-Location E:\Luna
git init
git add Luna_FE Luna_BE docs
git commit -m "chore: scaffold Luna Flutter and NestJS applications"
```

### Task 2: Backend configuration, database, response, and errors

**Files:**
- Create: `Luna_BE/.env.example`
- Create: `Luna_BE/src/config/app.config.ts`, `database.config.ts`, `notification.config.ts`, `env.validation.ts`
- Create: `Luna_BE/src/database/database.module.ts`, `database.service.ts`, `mongo.providers.ts`
- Create: `Luna_BE/src/common/interceptors/api-response.interceptor.ts`
- Create: `Luna_BE/src/common/filters/http-exception.filter.ts`
- Create: `Luna_BE/src/common/interfaces/api-envelope.interface.ts`
- Test: `Luna_BE/src/config/env.validation.spec.ts`, `Luna_BE/src/common/filters/http-exception.filter.spec.ts`

**Interfaces:**
- Produces: `validateEnvironment(config): Environment`; `DatabaseModule`; success envelope `{ data, timestamp }`; error envelope `{ code, message, details, timestamp, path }`.

- [ ] **Step 1: Write validation tests**

Test missing `DEVICE_TOKEN_PEPPER`, invalid `PORT`, production HTTP allowance, and valid UAT defaults.

```ts
expect(() => validateEnvironment({ NODE_ENV: 'production', ALLOW_INSECURE_HTTP: 'true' })).toThrow();
expect(validateEnvironment(validUat).MONGODB_URI).toBe('mongodb://127.0.0.1:27017/luna_uat');
```

- [ ] **Step 2: Run the focused tests and confirm failure**

```powershell
npm test -- --runInBand src/config/env.validation.spec.ts
```

- [ ] **Step 3: Implement typed config and Mongo module**

Use `registerAs` for `app`, `database`, and `notification`; use `ConfigModule.forRoot({ isGlobal: true, validate: validateEnvironment })`; use `MongooseModule.forRootAsync` in `DatabaseModule`.

- [ ] **Step 4: Implement global response/error layers and bootstrap hardening**

In `main.ts`, set prefix `/api/v1`, Helmet, compression, global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`, interceptor, filter, CORS allowlist, and Swagger at `/docs`.

- [ ] **Step 5: Verify**

```powershell
npm test -- --runInBand src/config src/common
npm run build
```

- [ ] **Step 6: Commit**

```powershell
git add Luna_BE
git commit -m "feat(be): add validated configuration and Mongo foundation"
```

### Task 3: Anonymous device authentication and revocation

**Files:**
- Create: `Luna_BE/src/modules/device/device.module.ts`, `device.controller.ts`, `device.service.ts`
- Create: `Luna_BE/src/modules/device/schemas/device.schema.ts`
- Create: `Luna_BE/src/modules/device/dto/register-device.dto.ts`, `update-device.dto.ts`, `push-token.dto.ts`
- Create: `Luna_BE/src/common/decorators/current-device.decorator.ts`, `public.decorator.ts`
- Create: `Luna_BE/src/common/guards/device-auth.guard.ts`
- Create: `Luna_BE/src/common/interfaces/authenticated-device.interface.ts`
- Test: `Luna_BE/src/modules/device/device.service.spec.ts`, `device.e2e-spec.ts`

**Interfaces:**
- Produces: `DeviceService.register(dto): Promise<{ deviceId: string; token: string }>`; `authenticate(token): Promise<AuthenticatedDevice>`; `revoke(deviceId): Promise<void>`.

- [ ] **Step 1: Write failing token lifecycle tests**

Assert registration returns a 64-character hex token, stored document has only `tokenHash`, authentication resolves the device, and revoked token throws `UnauthorizedException`.

- [ ] **Step 2: Run and confirm failure**

```powershell
npm test -- --runInBand src/modules/device
```

- [ ] **Step 3: Implement schema and service**

Generate token using `randomBytes(32).toString('hex')`; hash `token + DEVICE_TOKEN_PEPPER` with SHA-256; never log DTO/token. Roles are `owner | partner`; status is `active | revoked`.

- [ ] **Step 4: Implement controller and global guard**

Expose public `POST /devices/register`; authenticated `GET /devices/me`, `PATCH /devices/me`, `POST /devices/push-token`, and `DELETE /devices/me`. Read `Authorization: Bearer <token>` and attach `AuthenticatedDevice` to request.

- [ ] **Step 5: Run unit/e2e tests and build**

```powershell
npm test -- --runInBand src/modules/device
npm run test:e2e -- --runInBand
npm run build
```

- [ ] **Step 6: Commit**

```powershell
git add Luna_BE
git commit -m "feat(be): add anonymous device authentication"
```

### Task 4: Flutter core, secure bootstrap, router, and onboarding

**Files:**
- Create: every requested file under `Luna_FE/lib/core/config`, `network`, `router`, `theme`, `storage`, `utils`, `error`, `widgets`
- Create: `Luna_FE/lib/shared/enums/device_role.dart`, `shared/entities/device_identity.dart`
- Create: `Luna_FE/lib/features/splash/presentation/splash_page.dart`
- Create: `Luna_FE/lib/features/onboarding/data/device_repository.dart`, `domain/register_device.dart`, `presentation/onboarding_page.dart`, `onboarding_controller.dart`
- Test: `Luna_FE/test/core/network/api_client_test.dart`, `features/onboarding/onboarding_controller_test.dart`

**Interfaces:**
- Consumes: backend `POST /devices/register`.
- Produces: `SecureStorageService.readIdentity/writeIdentity/clearIdentity`; `DeviceRepository.register(DeviceRole)`; `AppRouter.router`.

- [ ] **Step 1: Write failing repository/controller tests**

Mock Dio and secure storage; assert first launch registers once and later launches reuse the stored identity; assert token is passed only in the authorization header.

- [ ] **Step 2: Run focused Flutter tests and confirm failure**

```powershell
flutter test test/core/network test/features/onboarding
```

- [ ] **Step 3: Implement config/network/error/storage files**

`Env.apiBaseUrl` reads `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api/v1')`. Dio uses 15-second timeouts, JSON headers, sanitized logging, auth interceptor, and maps errors into typed failures.

- [ ] **Step 4: Implement theme, router, shared widgets, splash, and onboarding**

Routes are `/splash`, `/onboarding`, `/home`; the router redirects to onboarding only when no secure identity exists. Create accessible light/dark themes with menstrual red, prediction amber, and ovulation green semantic colors.

- [ ] **Step 5: Create remaining requested feature directory skeletons with barrel-free focused files**

Create `data`, `domain`, `presentation` folders only for features that will receive code in later plans; add `.gitkeep` only to `generated`, empty asset folders, and translation folders. Register all `lib/assets/**` paths in `pubspec.yaml`.

- [ ] **Step 6: Verify and commit**

```powershell
dart format lib test
flutter analyze
flutter test
git add Luna_FE
git commit -m "feat(fe): add secure bootstrap and onboarding foundation"
```

### Task 5: Foundation UAT smoke test

**Files:**
- Create: `Luna_BE/scripts/create-uat-user.js`
- Create: `Luna_BE/README.md`, `Luna_FE/README.md`
- Test: `Luna_BE/test/foundation.e2e-spec.ts`

**Interfaces:**
- Produces: documented MongoDB Compass connection and commands to run BE/FE.

- [ ] **Step 1: Add e2e smoke test**

Test `/api/v1/devices/register`, `/api/v1/devices/me`, response envelopes, invalid bearer token, and Swagger document creation using `mongodb-memory-server`.

- [ ] **Step 2: Run test and fix only foundation defects**

```powershell
npm run test:e2e -- --runInBand test/foundation.e2e-spec.ts
```

- [ ] **Step 3: Add UAT instructions**

Document creating Mongo users `luna_app` (`readWrite` on `luna_uat`) and `luna_compass` (`read` on `luna_uat`), setting `.env`, running `npm run start:dev`, and starting Flutter with `--dart-define=API_BASE_URL=...`.

- [ ] **Step 4: Final foundation verification and commit**

```powershell
Set-Location E:\Luna\Luna_BE
npm run lint
npm test -- --runInBand
npm run test:e2e -- --runInBand
npm run build
Set-Location E:\Luna\Luna_FE
flutter analyze
flutter test
git add .
git commit -m "test: verify Luna platform foundation"
```

