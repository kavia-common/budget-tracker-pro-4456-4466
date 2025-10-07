Frontend environment quickstart

- Set API_BASE_URL and USE_DEMO_DATA via --dart-define or .env mapping:
  Web/local:           --dart-define=API_BASE_URL=http://localhost:3001 --dart-define=USE_DEMO_DATA=true
  Android emulator:    --dart-define=API_BASE_URL=http://10.0.2.2:3001 --dart-define=USE_DEMO_DATA=true

- USE_DEMO_DATA=true will populate local demo data and skip network calls so the UI is immediately useful.

- Ensure the backend is running and accessible from the device/emulator when USE_DEMO_DATA=false.
