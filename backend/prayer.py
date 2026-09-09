"""Offline prayer-time computation for the backend (adhanpy), from CallConfig."""

from datetime import datetime
from zoneinfo import ZoneInfo

from adhanpy.PrayerTimes import PrayerTimes
from adhanpy.calculation.CalculationMethod import CalculationMethod
from adhanpy.calculation.CalculationParameters import CalculationParameters
from adhanpy.calculation.Madhab import Madhab

from config import CallConfig

_PRAYERS = ["fajr", "dhuhr", "asr", "maghrib", "isha"]


def prayer_times(cfg: CallConfig, now_local: datetime) -> dict[str, datetime]:
    """Return {prayer: local datetime} for the five daily prayers on the date
    of ``now_local``."""
    method = getattr(CalculationMethod, cfg.adhanpy_method())
    params = CalculationParameters(method=method)
    params.madhab = Madhab.HANAFI if cfg.madhab == "hanafi" else Madhab.SHAFI
    times = PrayerTimes(
        (cfg.latitude, cfg.longitude),
        now_local,
        calculation_parameters=params,
    )
    tz = ZoneInfo(cfg.timezone)
    return {p: getattr(times, p).astimezone(tz) for p in _PRAYERS}
