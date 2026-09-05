"""
Salah PoC — the prayer-time scheduler.

Computes today's prayer times for your location and places an adhan call at each
one, automatically. This is the "always-on" engine (running locally for now):
a small loop wakes up often, and when a prayer time arrives it fires the call
using the same Twilio logic as the manual test.

Pattern (the same one the real cloud version will use): don't try to sleep until
an exact second — instead wake up every few seconds and ask "has any prayer time
arrived that I haven't called for yet?". Simple and robust.

Usage:
    python scheduler.py            # run the scheduler (keeps running)
    python scheduler.py --dry-run  # just print today's prayer times and exit
    python scheduler.py --test     # add a fake prayer 60s from now, to test calls

Stop it with Ctrl+C.

Config comes from .env (see .env.example): your location, timezone, calculation
method, which prayers are enabled, your name, plus the Twilio credentials.
"""

import argparse
import os
import sys
import time
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from dotenv import load_dotenv
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

from adhanpy.PrayerTimes import PrayerTimes
from adhanpy.calculation.CalculationMethod import CalculationMethod
from adhanpy.calculation.CalculationParameters import CalculationParameters
from adhanpy.calculation.Madhab import Madhab

from adhan_call import place_call

# Self-hosted adhan audio (our own GitHub repo, served raw). Stable, audio/mpeg,
# and no dependency on any third-party site staying up.
_RAW = "https://raw.githubusercontent.com/Nooronclouds/salah/main/poc/adhans"
DEFAULT_ADHAN_URL = f"{_RAW}/azan6.mp3"
# Fajr has its own adhan (adds "as-salatu khayrun min an-nawm"), sped up 1.5x so
# it wakes you rather than lulling you back to sleep.
DEFAULT_FAJR_ADHAN_URL = f"{_RAW}/fajr_1.5x.mp3"

# Pre-recorded soft spoken intros ("It's time for <prayer>"), one per prayer,
# self-hosted alongside the adhans. A prayer with no intro file just plays the
# adhan with no preamble.
_RAW_INTROS = "https://raw.githubusercontent.com/Nooronclouds/salah/main/poc/intros"
INTRO_PRAYERS = {"fajr", "dhuhr", "asr", "maghrib", "isha"}

# How often the loop wakes up to check the time (seconds). Small enough to hit
# the right minute; large enough to be gentle.
CHECK_INTERVAL_SECONDS = 20

# If the scheduler starts (or wakes) more than this long after a prayer time,
# that prayer is treated as already passed and skipped — so starting the script
# at noon doesn't dial you for every earlier prayer.
GRACE_SECONDS = 120

# Display labels used in the spoken intro ("Noor, it's time for Fajr").
PRAYER_LABELS = {
    "fajr": "Fajr",
    "sunrise": "Ishraq",
    "dhuhr": "Dhuhr",
    "asr": "Asr",
    "maghrib": "Maghrib",
    "isha": "Isha",
}


def require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        sys.exit(f"Missing required setting: {name}\nSee .env.example.")
    return value


def load_config() -> dict:
    load_dotenv()
    method_name = os.getenv("CALC_METHOD", "KARACHI").upper()
    if not hasattr(CalculationMethod, method_name):
        valid = [m for m in dir(CalculationMethod) if m.isupper()]
        sys.exit(f"Unknown CALC_METHOD '{method_name}'. Valid: {', '.join(valid)}")

    # Madhab affects Asr timing only: HANAFI is later than SHAFI.
    madhab_name = os.getenv("MADHAB", "HANAFI").upper()
    if not hasattr(Madhab, madhab_name):
        sys.exit(f"Unknown MADHAB '{madhab_name}'. Valid: HANAFI, SHAFI")

    enabled = [
        p.strip().lower()
        for p in os.getenv("ENABLED_PRAYERS", "fajr,dhuhr,asr,maghrib,isha").split(",")
        if p.strip()
    ]

    return {
        "name": os.getenv("NAME", "").strip(),
        "coords": (float(require_env("LATITUDE")), float(require_env("LONGITUDE"))),
        "tz": ZoneInfo(require_env("TIMEZONE")),
        "method": getattr(CalculationMethod, method_name),
        "madhab": getattr(Madhab, madhab_name),
        "enabled": enabled,
        "adhan_url": os.getenv("ADHAN_AUDIO_URL", DEFAULT_ADHAN_URL),
        "fajr_adhan_url": os.getenv("FAJR_ADHAN_URL", DEFAULT_FAJR_ADHAN_URL),
        "from_number": require_env("TWILIO_FROM_NUMBER"),
        "to_number": require_env("TO_NUMBER"),
        "client": Client(require_env("TWILIO_ACCOUNT_SID"), require_env("TWILIO_AUTH_TOKEN")),
    }


def compute_times(cfg: dict, now_local: datetime) -> dict:
    """Return {prayer: local datetime} for the enabled prayers, today."""
    params = CalculationParameters(method=cfg["method"])
    params.madhab = cfg["madhab"]
    pt = PrayerTimes(cfg["coords"], now_local, calculation_parameters=params)
    times = {}
    for prayer in cfg["enabled"]:
        utc_dt = getattr(pt, prayer, None)
        if utc_dt is None:
            print(f"  (skipping unknown prayer '{prayer}')")
            continue
        times[prayer] = utc_dt.astimezone(cfg["tz"])
    return times


def intro_url_for(prayer: str) -> str:
    """URL of the spoken intro clip for this prayer, or '' if none exists."""
    return f"{_RAW_INTROS}/{prayer}.mp3" if prayer in INTRO_PRAYERS else ""


def print_schedule(cfg: dict, times: dict, now_local: datetime) -> None:
    print(f"\nPrayer times for {now_local.date()} ({cfg['tz']}):")
    for prayer, when in sorted(times.items(), key=lambda kv: kv[1]):
        marker = "  (passed)" if when < now_local else ""
        print(f"  {PRAYER_LABELS.get(prayer, prayer.title()):8} {when.strftime('%H:%M')}{marker}")
    print()


def fire_call(cfg: dict, prayer: str) -> None:
    # Fajr gets its own adhan; the other four share the default.
    adhan_url = cfg["fajr_adhan_url"] if prayer == "fajr" else cfg["adhan_url"]
    intro_url = intro_url_for(prayer)
    label = PRAYER_LABELS.get(prayer, prayer.title())
    print(f"[{datetime.now(cfg['tz']).strftime('%H:%M:%S')}] Calling for {label}")
    try:
        sid = place_call(
            cfg["client"], cfg["from_number"], cfg["to_number"],
            adhan_url, intro_url,
        )
        print(f"    call placed (SID {sid})")
    except TwilioRestException as exc:
        print(f"    Twilio error: {exc.msg} (code {exc.code})")


def run(cfg: dict, test: bool) -> None:
    tz = cfg["tz"]
    today = None
    times: dict = {}
    fired: set = set()

    print("Scheduler running. Press Ctrl+C to stop.")
    while True:
        now = datetime.now(tz)

        # New day (or first loop): recompute and reset.
        if now.date() != today:
            today = now.date()
            times = compute_times(cfg, now)
            fired = set()
            print_schedule(cfg, times, now)
            # On startup, treat already-passed prayers as done so we don't
            # dial for prayers earlier in the day.
            for prayer, when in times.items():
                if (now - when).total_seconds() > GRACE_SECONDS:
                    fired.add(prayer)
            if test:
                test_time = now + timedelta(seconds=60)
                times["_test"] = test_time
                print(f"  [--test] fake call scheduled for {test_time.strftime('%H:%M:%S')}\n")

        for prayer, when in times.items():
            if prayer in fired:
                continue
            delta = (now - when).total_seconds()
            if 0 <= delta <= GRACE_SECONDS:
                real = prayer if prayer != "_test" else "fajr"  # test uses fajr label
                fire_call(cfg, real)
                fired.add(prayer)

        time.sleep(CHECK_INTERVAL_SECONDS)


def main() -> None:
    parser = argparse.ArgumentParser(description="Salah prayer-time call scheduler")
    parser.add_argument("--dry-run", action="store_true", help="print today's times and exit")
    parser.add_argument("--test", action="store_true", help="add a fake prayer 60s from now")
    args = parser.parse_args()

    cfg = load_config()

    if args.dry_run:
        now = datetime.now(cfg["tz"])
        print_schedule(cfg, compute_times(cfg, now), now)
        return

    try:
        run(cfg, args.test)
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
