"""Places the adhan call via Twilio. Credentials come from the environment."""

import os

from twilio.rest import Client

from config import CallConfig


def _client() -> Client:
    return Client(
        os.environ["TWILIO_ACCOUNT_SID"],
        os.environ["TWILIO_AUTH_TOKEN"],
    )


def build_twiml(adhan_url: str, intro_url: str = "") -> str:
    """Play the soft intro (if any), then the adhan."""
    intro = f"<Play>{intro_url}</Play>" if intro_url else ""
    return f"<Response>{intro}<Play>{adhan_url}</Play></Response>"


def place_call(cfg: CallConfig, prayer: str) -> str:
    """Place the call for one prayer and return the Twilio call SID."""
    from_number = os.environ["TWILIO_FROM_NUMBER"]
    adhan_url = cfg.fajr_adhan_url() if prayer == "fajr" else cfg.adhan_url()
    twiml = build_twiml(adhan_url, cfg.intro_url(prayer))
    call = _client().calls.create(
        to=cfg.to_number,
        from_=from_number,
        twiml=twiml,
    )
    return call.sid
