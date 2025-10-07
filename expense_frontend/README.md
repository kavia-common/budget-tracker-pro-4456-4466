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
API_BASE_URL=http://10.0.2.2:3000
```
Notes:
- `10.0.2.2` is Android emulator alias to host. On iOS simulator use `http://localhost:3000`.
- The app falls back to `10.0.2.2:3000` if `.env` is missing.

## Run
- flutter pub get
- flutter run

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
