"""
Shared call logic: build the TwiML and place the adhan call.

Used by both call_adhan.py (manual one-off test) and scheduler.py (the automatic
prayer-time scheduler), so there is a single source of truth for how a call is
made.

The call plays an optional soft spoken intro (a pre-recorded audio clip, e.g.
"It's time for Fajr") followed by the adhan. Both are just audio URLs Twilio
fetches and plays — no robotic text-to-speech on the call itself.
"""

from twilio.rest import Client


def build_twiml(adhan_url: str, intro_url: str = "") -> str:
    """
    Build the call script (TwiML): play the intro clip (if given), then the adhan.
    """
    intro = f"<Play>{intro_url}</Play>" if intro_url else ""
    return f"<Response>{intro}<Play>{adhan_url}</Play></Response>"


def place_call(
    client: Client,
    from_number: str,
    to_number: str,
    adhan_url: str,
    intro_url: str = "",
) -> str:
    """Place the call and return the Twilio call SID."""
    twiml = build_twiml(adhan_url, intro_url)
    call = client.calls.create(to=to_number, from_=from_number, twiml=twiml)
    return call.sid
