# Budget Tracker Pro - Flutter Frontend

A cross-platform Flutter app for managing and tracking monthly expenses with budgets, goals, and alerts.

## Features
- User authentication (register, login, logout)
- Dashboard summary
- Transactions list with quick add
- Budgets list with quick add and progress bars
- Goals list with quick add and progress
- Alerts list
- Ocean Professional theme
- API client using `.env` (flutter_dotenv) and `shared_preferences`

## Requirements
- Flutter 3.29+
- A running backend API providing:
  - POST /auth/register
  - POST /auth/login -> { token }
  - GET /auth/me -> { name, email, ... }
  - GET /dashboard
  - GET/POST /transactions
  - GET/POST /budgets
  - GET/POST /goals
  - GET /alerts

## Environment variables
Create a `.env` file at project root with:
```
# Android emulator: use 10.0.2.2 to reach host machine
API_BASE_URL=http://10.0.2.2:3001/api/v1
```

Platform notes:
- Android emulator: use `http://10.0.2.2:3001/api/v1`
- iOS simulator: use `http://localhost:3001/api/v1`
- The app falls back to `http://10.0.2.2:3001/api/v1` if `.env` is missing.

## Quickstart (local dev)
1) Start database at 127.0.0.1:5001 (db name example: `myapp`)
2) Start backend with:
   - PORT=3001
   - POSTGRES_URL=postgres://<user>:<password>@127.0.0.1:5001/myapp
   - JWT_SECRET set
3) Flutter:
   - flutter pub get
   - Create/update `.env` per above
   - flutter run

Smoke test:
- Register -> Login -> Transactions list -> Create a transaction

## Troubleshooting
- Android cannot reach backend: ensure `API_BASE_URL` uses `10.0.2.2` not `localhost`.
- 401 errors repeatedly: token may be invalid; the app clears token on 401 to force re-login.
- Backend connection to DB fails: confirm DB is on `127.0.0.1:5001` and `POSTGRES_URL` is correct.
- CORS in development: ensure backend allows emulator origins (10.0.2.2 and localhost).

## Theming
The app uses the Ocean Professional palette:
- Primary: #1E3A8A
- Secondary: #F59E0B
- Success: #059669
- Error: #DC2626
- Background: #F3F4F6
- Surface: #FFFFFF
- Text: #111827

## Notes
- Tokens are stored in SharedPreferences under `auth_token`.
- A 401 from the API clears the token to force re-login.
- Update API_BASE_URL to your backend environment.
