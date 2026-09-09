"""Background scheduler: wakes periodically and places the adhan call when a
prayer time arrives. Reads live config, so app updates take effect immediately.
"""

import threading
import time
from datetime import datetime
from zoneinfo import ZoneInfo

from caller import place_call
from config import CallConfig
from prayer import prayer_times

CHECK_INTERVAL_SECONDS = 20
# If we wake more than this long after a prayer time, treat it as passed.
GRACE_SECONDS = 120


class Scheduler:
    def __init__(self, config: CallConfig) -> None:
        self._config = config
        self._lock = threading.Lock()
        self._fired: set[str] = set()
        self._day: str = ""
        self._thread: threading.Thread | None = None
        self._stop = threading.Event()

    @property
    def config(self) -> CallConfig:
        with self._lock:
            return self._config

    def update_config(self, config: CallConfig) -> None:
        with self._lock:
            self._config = config
            # New config → re-evaluate today from scratch.
            self._day = ""

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()

    def _run(self) -> None:
        while not self._stop.is_set():
            try:
                self._tick()
            except Exception as exc:  # keep the loop alive; log and continue
                print(f"[scheduler] tick error: {exc}")
            self._stop.wait(CHECK_INTERVAL_SECONDS)

    def _tick(self) -> None:
        cfg = self.config
        if not cfg.enabled or not cfg.to_number:
            return
        now = datetime.now(ZoneInfo(cfg.timezone))
        today = now.date().isoformat()

        if today != self._day:
            self._day = today
            self._fired = set()
            times = prayer_times(cfg, now)
            # Mark already-passed prayers as done so a mid-day (re)start does
            # not dial for earlier prayers.
            for prayer, when in times.items():
                if (now - when).total_seconds() > GRACE_SECONDS:
                    self._fired.add(prayer)

        times = prayer_times(cfg, now)
        for prayer in cfg.sanitized_prayers():
            when = times.get(prayer)
            if when is None or prayer in self._fired:
                continue
            delta = (now - when).total_seconds()
            if 0 <= delta <= GRACE_SECONDS:
                self._fire(cfg, prayer, now)

    def _fire(self, cfg: CallConfig, prayer: str, now: datetime) -> None:
        stamp = now.strftime("%H:%M:%S")
        try:
            sid = place_call(cfg, prayer)
            print(f"[scheduler] {stamp} called for {prayer} (sid {sid})")
        except Exception as exc:
            print(f"[scheduler] {stamp} call for {prayer} failed: {exc}")
        finally:
            # Mark fired regardless, so a failure doesn't retry-storm.
            self._fired.add(prayer)
