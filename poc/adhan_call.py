"""
Shared call logic: build the TwiML and place the adhan call.

Used by both call_adhan.py (manual one-off test) and scheduler.py (the automatic
prayer-time scheduler), so there is a single source of truth for how a call is
made.
"""

from twilio.rest import Client


def build_twiml(adhan_url: str, intro_text: str = "", voice: str = "Polly.Matthew-Neural") -> str:
    """
    Build the call script (TwiML).

    - If intro_text is given, it's spoken first in `voice` (a soothing male voice
      by default), e.g. "Noor, it's time for Fajr".
    - Then the adhan mp3 is played.

    intro_text is escaped for the few XML-special characters so a name or prayer
    label can never break the markup.
    """
    say = ""
    if intro_text.strip():
        safe = (
            intro_text.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        )
        say = f'<Say voice="{voice}">{safe}</Say>'
    return f"<Response>{say}<Play>{adhan_url}</Play></Response>"


def place_call(
    client: Client,
    from_number: str,
    to_number: str,
    adhan_url: str,
    intro_text: str = "",
    voice: str = "Polly.Matthew-Neural",
) -> str:
    """Place the call and return the Twilio call SID."""
    twiml = build_twiml(adhan_url, intro_text, voice)
    call = client.calls.create(to=to_number, from_=from_number, twiml=twiml)
    return call.sid
