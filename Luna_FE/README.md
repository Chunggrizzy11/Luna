# Luna Flutter app

## Run against local UAT

Install Flutter, fetch packages, and start the app with the API base URL. The
value includes the backend's `/api/v1` prefix. A local UAT backend runs over
HTTP only with the backend's explicit local-only UAT configuration
(`NODE_ENV=uat`, `ALLOW_INSECURE_HTTP=true`, and `TRUST_PROXY=false`).

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<LOCAL_UAT_API_HOST>:3000/api/v1
```

For an Android emulator, replace the local host with its host alias:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Run against deployed UAT or production

Use the public HTTPS URL when the backend is behind the trusted TLS-terminator
topology documented in `../Luna_BE/README.md`:

```powershell
flutter run --dart-define=API_BASE_URL=https://<PUBLIC_API_HOST>/api/v1
```

The backend environment and MongoDB UAT user setup are documented in
`../Luna_BE/README.md`. MongoDB Compass is an optional read-only inspection
client, not the MongoDB Server used by the app.

## Quality checks

```powershell
flutter analyze
flutter test
```
