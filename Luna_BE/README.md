# Luna Backend

## Local setup

Install Node.js 22+ and a **MongoDB Server** instance, then install the
backend dependencies:

```powershell
npm ci
Copy-Item .env.example .env
```

Edit `.env` before starting the API. For UAT, use the application account
created below and a URL-encoded password:

```dotenv
NODE_ENV=uat
PORT=3000
MONGODB_URI=mongodb://luna_app:<URL_ENCODED_APP_PASSWORD>@127.0.0.1:27017/luna_uat?authSource=admin
DEVICE_TOKEN_PEPPER=<LONG_RANDOM_SECRET>
ALLOW_INSECURE_HTTP=false
TRUST_PROXY=false
TRUSTED_PROXY_IPS=
CORS_ORIGINS=https://<UAT_WEB_ORIGIN>
```

Start the backend:

```powershell
npm run start:dev
```

The API is served below `https://<HOST>:<PORT>/api/v1`; Swagger is available
at `https://<HOST>:<PORT>/docs`. UAT and production traffic must use HTTPS.
`ALLOW_INSECURE_HTTP=true` is only appropriate for explicit local/test
configuration and is rejected in production.

## UAT MongoDB users

MongoDB Server stores the data. MongoDB Compass is only a desktop client for
viewing that server; installing Compass does not start MongoDB or create
database users.

Run the bootstrap script with a MongoDB administrator URI that has permission
to manage users. Supply credentials through environment variables (preferred)
or `--mongo-admin-uri`, `--app-password`, and `--compass-password` arguments.
Never commit, paste, or log real passwords.

```powershell
$env:MONGO_ADMIN_URI='mongodb://<MONGO_ADMIN_USERNAME>:<URL_ENCODED_MONGO_ADMIN_PASSWORD>@127.0.0.1:27017/admin?authSource=admin'
$env:MONGO_APP_PASSWORD='<APP_PASSWORD>'
$env:MONGO_COMPASS_PASSWORD='<COMPASS_PASSWORD>'
node scripts/create-uat-user.js
```

The script is safe to rerun: it creates or updates these users with the
specified password and least-privilege role.

| User | Role | Database |
| --- | --- | --- |
| `luna_app` | `readWrite` | `luna_uat` |
| `luna_compass` | `read` | `luna_uat` |

Use this authenticated application connection string in `.env`:

```text
mongodb://luna_app:<URL_ENCODED_APP_PASSWORD>@127.0.0.1:27017/luna_uat?authSource=admin
```

Connect Compass with the read-only account, not the application account:

```text
mongodb://luna_compass:<URL_ENCODED_COMPASS_PASSWORD>@127.0.0.1:27017/luna_uat?authSource=admin
```

## Verification

```powershell
npm run lint
npm test -- --runInBand
npm run test:e2e -- --runInBand
npm run build
```
