"""Backend runtime config: the per-user call settings pushed from the app.

Twilio credentials and the API token live in the environment (.env), never in
this config and never sent from the app. This config holds only the call
preferences the app is allowed to set.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field, asdict
from pathlib import Path

CONFIG_PATH = Path(os.getenv("CONFIG_PATH", "config.json"))

# Where the self-hosted audio lives (adhans + spoken intros).
RAW_BASE = "https://raw.githubusercontent.com/Nooronclouds/salah/main/poc"

# App calc-method names (Flutter enum .name) -> adhanpy CalculationMethod names.
METHOD_MAP = {
    "karachi": "KARACHI",
    "muslimWorldLeague": "MUSLIM_WORLD_LEAGUE",
    "egyptian": "EGYPTIAN",
    "ummAlQura": "UMM_AL_QURA",
    "dubai": "DUBAI",
    "qatar": "QATAR",
    "kuwait": "KUWAIT",
    "singapore": "SINGAPORE",
    "northAmerica": "NORTH_AMERICA",
}

VALID_PRAYERS = {"fajr", "dhuhr", "asr", "maghrib", "isha"}


@dataclass
class CallConfig:
    """Everything needed to place the right calls for one user."""

    enabled: bool = False
    to_number: str = ""
    latitude: float = 13.0073
    longitude: float = 76.0962
    timezone: str = "Asia/Kolkata"
    method: str = "karachi"          # app enum name
    madhab: str = "hanafi"           # hanafi | shafi
    call_prayers: list[str] = field(
        default_factory=lambda: ["fajr", "dhuhr", "asr", "maghrib", "isha"]
    )
    adhan_choice: int = 6
    fajr_speed: float = 1.5

    # ---- derived audio URLs ----------------------------------------------
    def adhan_url(self) -> str:
        return f"{RAW_BASE}/adhans/azan{self.adhan_choice}.mp3"

    def fajr_adhan_url(self) -> str:
        # Only certain sped-up Fajr files are hosted; fall back to 1.5x.
        speed = self.fajr_speed if self.fajr_speed in (1.3, 1.4, 1.5) else 1.5
        return f"{RAW_BASE}/adhans/fajr_{speed}x.mp3"

    def intro_url(self, prayer: str) -> str:
        return f"{RAW_BASE}/intros/{prayer}.mp3"

    def adhanpy_method(self) -> str:
        return METHOD_MAP.get(self.method, "KARACHI")

    def sanitized_prayers(self) -> list[str]:
        return [p for p in self.call_prayers if p in VALID_PRAYERS]

    # ---- persistence ------------------------------------------------------
    def save(self) -> None:
        CONFIG_PATH.write_text(json.dumps(asdict(self), indent=2))

    @classmethod
    def load(cls) -> "CallConfig":
        if not CONFIG_PATH.exists():
            return cls()
        try:
            data = json.loads(CONFIG_PATH.read_text())
            return cls.from_payload(data)
        except (json.JSONDecodeError, TypeError, ValueError):
            return cls()

    @classmethod
    def from_payload(cls, data: dict) -> "CallConfig":
        """Build from an app payload, validating/ignoring unknown fields."""
        cfg = cls()
        cfg.enabled = bool(data.get("enabled", cfg.enabled))
        cfg.to_number = str(data.get("to_number", cfg.to_number)).strip()
        cfg.latitude = float(data.get("latitude", cfg.latitude))
        cfg.longitude = float(data.get("longitude", cfg.longitude))
        cfg.timezone = str(data.get("timezone", cfg.timezone))
        cfg.method = str(data.get("method", cfg.method))
        cfg.madhab = str(data.get("madhab", cfg.madhab)).lower()
        prayers = data.get("call_prayers", cfg.call_prayers)
        if isinstance(prayers, list):
            cfg.call_prayers = [str(p).lower() for p in prayers]
        cfg.adhan_choice = int(data.get("adhan_choice", cfg.adhan_choice))
        cfg.fajr_speed = float(data.get("fajr_speed", cfg.fajr_speed))
        return cfg

    def public_dict(self) -> dict:
        """Config as returned by GET /config (no secrets held here anyway)."""
        base = asdict(self)
        base["adhan_url"] = self.adhan_url()
        base["fajr_adhan_url"] = self.fajr_adhan_url()
        return base
