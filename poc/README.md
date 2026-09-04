# Salah PoC — the ringing adhan call

Proves the hardest part of the app: at prayer time your phone gets a **real call**,
and when you answer, the **adhan plays**. Runs on your laptop — no server needed.

## One-time setup

1. **Make a Twilio trial account** — https://www.twilio.com/try-twilio (free).
2. In the Console, note your **Account SID** and **Auth Token** (dashboard).
3. Get your free trial **phone number** (Console → Phone Numbers → get a number).
4. **Verify your own phone** so the trial is allowed to call it:
   Console → Phone Numbers → Verified Caller IDs → add your number.

## Run it

```bash
cd poc
pip install -r requirements.txt
cp .env.example .env      # then edit .env with your details
python call_adhan.py
```

Your phone should ring within a few seconds. Answer it — you'll hear a short
Twilio trial message (unavoidable on the free tier), then the adhan.

## The scheduler (automatic calls at prayer times)

Once the manual call works, `scheduler.py` fires it automatically at the five
prayer times. Fill in the scheduler settings in `.env` (name, latitude/longitude,
timezone, calculation method), then:

```bash
python scheduler.py --dry-run   # preview today's prayer times, no calls
python scheduler.py --test      # places a test call ~60s from now
python scheduler.py             # run for real; Ctrl+C to stop
```

At each prayer time it calls you with a soothing spoken intro
("Noor, it's time for Fajr") followed by the adhan.

Notes:
- It computes times **offline** (no API) from your coordinates using the
  calculation method you pick — set `CALC_METHOD` to whatever your local
  community uses.
- Starting it late in the day won't dial you for prayers that already passed.
- While the PoC runs on your laptop, this same loop is what moves to a free
  serverless + cron host for the real app — nothing to babysit.

## What this proves — and what's next

- ✅ A real phone call, triggered from code, plays the adhan.
- ✅ It fires automatically at the correct prayer times for your location.
- ⏭️ **Next:** pick/host the actual adhan audio(s), then build the mobile app
  (settings + the gratitude journal).

## Notes / gotchas

- **Trial limits:** free trials can only call *verified* numbers and prepend a
  trial message. Both go away once you add a little credit — fine for testing.
- **E.164 numbers:** always `+<countrycode><number>`, e.g. `+91...` for India.
- The default adhan clip is a public URL; swap in your own via `ADHAN_AUDIO_URL`.
- `.env` holds secrets and is gitignored — keep it that way.
