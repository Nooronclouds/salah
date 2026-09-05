"""
Salah PoC — place ONE real phone call that plays the adhan (manual test).

This proves the riskiest part of the app: at prayer time, instead of a
notification you can silence and swipe away, your phone *rings*. When you answer,
you hear the adhan.

Runs entirely on your laptop. No server — the call's instructions (TwiML) are
sent inline with the API request. For the AUTOMATIC version that fires at the
five prayer times, see scheduler.py.

Usage:
    1. pip install -r requirements.txt
    2. Copy .env.example to .env and fill in your Twilio credentials + numbers
    3. python call_adhan.py
"""

import os
import sys

from dotenv import load_dotenv
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

from adhan_call import place_call

# A public, hotlink-friendly adhan clip so the PoC works out of the box.
# Override with ADHAN_AUDIO_URL in .env to use your own hosted adhan.
DEFAULT_ADHAN_URL = "https://raw.githubusercontent.com/Nooronclouds/salah/main/poc/adhans/azan6.mp3"

# Optional soft spoken intro clip played before the adhan (an audio URL). Empty
# by default = pure adhan. Set INTRO_URL in .env to test a specific intro, e.g.
# https://raw.githubusercontent.com/Nooronclouds/salah/main/poc/intros/fajr.mp3
DEFAULT_INTRO_URL = ""


def require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        sys.exit(
            f"Missing required setting: {name}\n"
            f"Copy .env.example to .env and fill it in (see the README)."
        )
    return value


def main() -> None:
    load_dotenv()

    account_sid = require_env("TWILIO_ACCOUNT_SID")
    auth_token = require_env("TWILIO_AUTH_TOKEN")
    from_number = require_env("TWILIO_FROM_NUMBER")
    to_number = require_env("TO_NUMBER")

    adhan_url = os.getenv("ADHAN_AUDIO_URL", DEFAULT_ADHAN_URL)
    intro_url = os.getenv("INTRO_URL", DEFAULT_INTRO_URL)

    client = Client(account_sid, auth_token)

    print(f"Placing call:  {from_number}  ->  {to_number}")
    print("(Twilio trial: answer, then press any key to get past the trial gate.)")

    try:
        sid = place_call(client, from_number, to_number, adhan_url, intro_url)
    except TwilioRestException as exc:
        sys.exit(f"\nTwilio rejected the call: {exc.msg}\n(code {exc.code})")

    print(f"\nCall queued. SID: {sid}")
    print("Your phone should ring in a few seconds.")


if __name__ == "__main__":
    main()
