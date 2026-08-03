# Luna Flutter app

## Run against UAT

Install Flutter, fetch packages, and start the app with the API base URL. The
value includes the backend's `/api/v1` prefix and should use HTTPS for UAT.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://<UAT_API_HOST>/api/v1
```

For an Android emulator running a local development backend, use its host
alias only with an explicit development backend configuration:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

The backend environment and MongoDB UAT user setup are documented in
`../Luna_BE/README.md`. MongoDB Compass is an optional read-only inspection
client, not the MongoDB Server used by the app.

## Quality checks

```powershell
flutter analyze
flutter test
```
