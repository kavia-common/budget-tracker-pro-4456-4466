# Budget Tracker Pro - Flutter Frontend

A cross-platform Flutter app for managing and tracking monthly expenses with budgets, goals, and alerts.

## Features
- Mock demo mode (default) with seeded sample data
- Dashboard summary with KPIs, top categories, and 6-month bars
- Transactions list with quick add (in-memory mutations in mock mode)
- Budgets list with quick add and progress bars
- Goals list with quick add and progress
- Alerts list (mark read in mock mode)
- Ocean Professional theme
- API client using `.env` (flutter_dotenv) and `shared_preferences`
- Real backend mode (toggle via `.env`)

## Requirements
- Flutter 3.29+
- Optional: a running backend API (only when USE_MOCK_DATA=false)

## Environment variables
Create a `.env` file at project root with:
```
# Toggle demo mock mode (default true)
USE_MOCK_DATA=true

# Android emulator: use 10.0.2.2 to reach host machine
# Only used when USE_MOCK_DATA=false
API_BASE_URL=http://10.0.2.2:3001/api/v1
```

Platform notes:
- Android emulator: use `http://10.0.2.2:3001/api/v1`
- iOS simulator: use `http://localhost:3001/api/v1`
- When `USE_MOCK_DATA=true`, the app does not call the network.

## Quickstart (mock demo mode)
1) flutter pub get
2) Ensure `.env` contains `USE_MOCK_DATA=true`
3) flutter run

The app launches directly to the main tabs with sample dashboards and lists. Creating items mutates in-memory data only.

## Quickstart (real backend)
1) Start your backend and ensure it exposes endpoints similar to:
   - POST /auth/register
   - POST /auth/login -> { token }
   - GET /auth/me
   - GET /dashboard
   - GET/POST /transactions
   - GET/POST /budgets
   - GET/POST /goals
   - GET /alerts
2) Update `.env`:
```
USE_MOCK_DATA=false
API_BASE_URL=http://10.0.0.2:3001/api/v1
```
3) flutter run

## Troubleshooting
- Android cannot reach backend: ensure `API_BASE_URL` uses `10.0.2.2` not `localhost`.
- 401 errors: token is cleared to force re-login (real mode only).
- In mock mode, no Authorization header is sent.

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
- Tokens are stored in SharedPreferences under `auth_token` (real mode).
- Mock mode uses an in-memory data store and bypasses authentication entirely.
- Switch `USE_MOCK_DATA` to `false` to use a real backend and login/register screens if you re-enable navigation guards.
