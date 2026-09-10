# Deploying the call service to Koyeb (free, always-on)

Koyeb builds straight from your GitHub repo and keeps one service running 24/7 on
the free tier — which is what the prayer-time scheduler needs. No CLI, no card.

## Before you start

You'll need one secret you invent yourself: an **API token** — a long random
string. The server and the app both hold it so only your app can push settings.
Generate one (any long random string works), e.g.:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Keep it handy — you'll paste it into Koyeb *and* the app.

## Steps

1. **Sign up** at https://www.koyeb.com with your GitHub account.
2. **Create Service → GitHub.** Authorize Koyeb to access `Nooronclouds/salah`.
3. **Repository:** `Nooronclouds/salah`, branch `main`.
4. **Builder:** choose **Dockerfile**. Set **Work directory** to `backend`
   (so it uses `backend/Dockerfile`).
5. **Instance:** the **Free** (Eco/Nano) instance. Pick any region.
6. **Ports:** expose port **8000**, HTTP, public. Set the **health check** to
   HTTP path `/health`.
7. **Environment variables** — add these, marking each as **Secret**:
   - `TWILIO_ACCOUNT_SID` — from your Twilio console
   - `TWILIO_AUTH_TOKEN` — from your Twilio console
   - `TWILIO_FROM_NUMBER` — your Twilio number, e.g. `+1...`
   - `API_TOKEN` — the random token you generated above
8. **Name** the service (e.g. `salah`) and **Deploy**. First build takes a few
   minutes.
9. When it's live, Koyeb shows a public URL like
   `https://salah-<your-org>.koyeb.app`. Open `<url>/health` in a browser — you
   should see today's prayer times.

## Point the app at it

In the app: **Settings → Call service**
- **Service URL:** your Koyeb URL (e.g. `https://salah-xxx.koyeb.app`)
- **API token:** the same `API_TOKEN`
- Turn **Calls enabled** on
- Tap **Sync settings** (pushes your config), then **Test call** to confirm your
  phone rings.

## Good to know

- **Free tier storage is ephemeral.** If Koyeb restarts/redeploys the service,
  the last-pushed config is lost. The app **auto-syncs when you open it** (if
  calls are enabled and the service URL/token are set), so simply opening the app
  restores the config — or tap **Sync settings** to force it.
- **One instance only.** Don't scale to multiple instances — each would run its
  own scheduler and you'd get duplicate calls.
- Twilio still needs the destination number verified while on a trial, and adds
  its trial preamble; add a little credit to remove both.
