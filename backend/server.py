"""Salah call service — a small API the app pushes settings to, plus a
background scheduler that places the adhan calls at prayer times.

Secrets (Twilio + API token) come from the environment, never from the app:
  TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER, API_TOKEN
"""

import os
from contextlib import asynccontextmanager
from datetime import datetime
from zoneinfo import ZoneInfo

from dotenv import load_dotenv
from fastapi import Body, Depends, FastAPI, Header, HTTPException

from caller import place_call
from config import CallConfig
from prayer import prayer_times
from scheduler import Scheduler

load_dotenv()

_scheduler = Scheduler(CallConfig.load())


@asynccontextmanager
async def lifespan(app: FastAPI):
    _scheduler.start()
    yield
    _scheduler.stop()


app = FastAPI(title="Salah call service", lifespan=lifespan)


def require_token(authorization: str = Header(default="")) -> None:
    """Bearer-token auth. The token is a server secret shared with the app."""
    expected = os.environ.get("API_TOKEN", "")
    if not expected:
        raise HTTPException(500, "Server missing API_TOKEN")
    if authorization != f"Bearer {expected}":
        raise HTTPException(401, "Invalid or missing token")


def _next_times(cfg: CallConfig) -> dict[str, str]:
    try:
        now = datetime.now(ZoneInfo(cfg.timezone))
        return {p: t.strftime("%H:%M") for p, t in prayer_times(cfg, now).items()}
    except Exception:
        return {}


@app.get("/health")
def health() -> dict:
    cfg = _scheduler.config
    return {
        "status": "ok",
        "enabled": cfg.enabled,
        "phone_set": bool(cfg.to_number),
        "today": _next_times(cfg),
    }


@app.get("/config", dependencies=[Depends(require_token)])
def get_config() -> dict:
    return _scheduler.config.public_dict()


@app.post("/config", dependencies=[Depends(require_token)])
def set_config(payload: dict = Body(...)) -> dict:
    cfg = CallConfig.from_payload(payload)
    cfg.save()
    _scheduler.update_config(cfg)
    return cfg.public_dict()


@app.post("/test-call", dependencies=[Depends(require_token)])
def test_call() -> dict:
    cfg = _scheduler.config
    if not cfg.to_number:
        raise HTTPException(400, "No phone number set")
    try:
        sid = place_call(cfg, "fajr")
    except Exception as exc:
        raise HTTPException(502, f"Call failed: {exc}") from exc
    return {"status": "calling", "sid": sid}
