#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["icalendar>=6", "recurring-ical-events>=3"]
# ///
"""Print upcoming events from iCal feeds as JSON for the desktop calendar widget.

Feeds are read from ~/.local/share/hyrule-bar/calendars.txt (one URL per line,
# for comments). That file lives outside the dotfiles repo because Google's
"secret address in iCal format" grants read access to the whole calendar.
Each feed is cached so the widget still has events while offline.
"""

import datetime as dt
import hashlib
import json
import pathlib
import sys
import urllib.request

import icalendar
import recurring_ical_events

FEEDS = pathlib.Path.home() / ".local/share/hyrule-bar/calendars.txt"
CACHE = pathlib.Path.home() / ".cache/hyrule-bar/calendars"
DAYS_AHEAD = 45


def read_feed(url: str) -> tuple[bytes | None, str | None]:
    cached = CACHE / (hashlib.sha256(url.encode()).hexdigest()[:16] + ".ics")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "hyrule-bar"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read()
        CACHE.mkdir(parents=True, exist_ok=True)
        cached.write_bytes(data)
        return data, None
    except Exception as exc:  # offline or bad link: fall back to the last copy
        if cached.exists():
            return cached.read_bytes(), None
        return None, f"{type(exc).__name__}: {exc}"


def as_local(value: dt.date | dt.datetime) -> dt.datetime:
    if isinstance(value, dt.datetime):
        return value.astimezone() if value.tzinfo else value.astimezone()
    return dt.datetime.combine(value, dt.time()).astimezone()


def main() -> None:
    if not FEEDS.exists():
        print(json.dumps({"events": [], "errors": [], "configured": False}))
        return

    urls = [
        line.strip()
        for line in FEEDS.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    today = dt.date.today()
    start = today.replace(day=1)
    end = today + dt.timedelta(days=DAYS_AHEAD)

    events, errors = [], []
    for index, url in enumerate(urls):
        data, error = read_feed(url)
        if error:
            errors.append(f"calendar {index + 1}: {error}")
            continue
        cal = icalendar.Calendar.from_ical(data)
        name = str(cal.get("X-WR-CALNAME", f"Calendar {index + 1}"))
        for ev in recurring_ical_events.of(cal).between(start, end):
            begin = ev.get("DTSTART").dt
            finish = ev.get("DTEND").dt if ev.get("DTEND") else begin
            all_day = not isinstance(begin, dt.datetime)
            events.append({
                "title": str(ev.get("SUMMARY", "(no title)")),
                "start": as_local(begin).isoformat(),
                "end": as_local(finish).isoformat(),
                "allDay": all_day,
                "calendar": name,
                "feed": index,
            })

    events.sort(key=lambda e: (e["start"], not e["allDay"]))
    print(json.dumps({"events": events, "errors": errors, "configured": bool(urls)}))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(json.dumps({"events": [], "errors": [f"{type(exc).__name__}: {exc}"], "configured": True}))
        sys.exit(0)
