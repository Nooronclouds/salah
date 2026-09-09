# Salah call service

The always-on backend: the app pushes your settings here, and this service
places the adhan calls at prayer times. Twilio credentials and the API token
stay server-side — the app never sees them.

## Run locally

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env          # fill in Twilio creds + a random API_TOKEN
uvicorn server:app --host 0.0.0.0 --port 8000
```

## Endpoints

| Method | Path         | Auth | Purpose                                  |
|--------|--------------|------|------------------------------------------|
| GET    | `/health`    | no   | status + today's computed times          |
| GET    | `/config`    | yes  | current config                           |
| POST   | `/config`    | yes  | replace config (the app pushes settings) |
| POST   | `/test-call` | yes  | place a test call right now              |

Auth: send `Authorization: Bearer <API_TOKEN>`.

### Example

```bash
TOKEN=your_api_token
curl -s localhost:8000/health

curl -s -X POST localhost:8000/config \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"enabled":true,"to_number":"+9199...","latitude":13.0073,"longitude":76.0962,
       "timezone":"Asia/Kolkata","method":"karachi","madhab":"hanafi",
       "call_prayers":["fajr","dhuhr","asr","maghrib","isha"],
       "adhan_choice":6,"fajr_speed":1.5}'
```

## How it connects to the app

The Flutter app's Settings → "Call service" section holds this service's URL and
the API token, and pushes the current settings via `POST /config`. The audio
(adhans + spoken intros) is served from the repo's `poc/` assets over
raw.githubusercontent, so the service only needs the URLs, which it derives from
`adhan_choice` / `fajr_speed`.

## Next: deploy

This runs on a laptop today. To make calls fire without your computer on, deploy
to a small always-on host (Fly.io / Render / a tiny VPS) and point the app's
"Call service URL" at it. `config.json` persists the last pushed settings.
