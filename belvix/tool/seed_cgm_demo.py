#!/usr/bin/env python3
"""Seed the CGM backend with a realistic demo dataset.

The app gets glucose from a paired BLE sensor (not available on web / a
simulator) or from history already synced to the backend. With neither, the
dashboard stays empty / "loading". This populates the backend via the public
API so the dashboard, timeline chart and interpretation cards have real data.

Usage:
    TOKEN=<jwt> python3 tool/seed_cgm_demo.py            # 14 days @ 15 min
    TOKEN=<jwt> DAYS=7 INTERVAL_MIN=5 python3 tool/seed_cgm_demo.py

Get a token by logging in:
    curl -s -X POST https://cgm-app.duckdns.org/api/auth/login \
      -H 'Content-Type: application/json' \
      -d '{"email":"you@example.com","password":"..."}'
"""
import json
import math
import os
import random
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone

BASE = os.environ.get("BASE_URL", "https://cgm-app.duckdns.org/api")
TOKEN = os.environ.get("TOKEN")
DAYS = int(os.environ.get("DAYS", "14"))
INTERVAL_MIN = int(os.environ.get("INTERVAL_MIN", "15"))

if not TOKEN:
    sys.exit("Set TOKEN=<jwt> (see the docstring for how to get one).")

HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}


def post(path, body):
    req = urllib.request.Request(
        f"{BASE}{path}", data=json.dumps(body).encode(), headers=HEADERS, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return {"success": False, "message": e.read().decode()[:120]}
    except Exception as e:  # noqa: BLE001
        return {"success": False, "message": str(e)}


def trend_for(delta):
    if delta > 12:
        return "rising fast"
    if delta > 4:
        return "rising"
    if delta < -12:
        return "falling fast"
    if delta < -4:
        return "falling"
    return "stable"


def generate():
    """A believable curve: circadian baseline, dawn rise, three meal spikes,
    gentle noise, and occasional highs/lows."""
    now = datetime.now(timezone.utc)
    start = now - timedelta(days=DAYS)
    n = int((DAYS * 24 * 60) / INTERVAL_MIN)

    readings = []
    prev = 105.0
    # active meal "bumps": (start_minute_of_day, peak_add, duration_min)
    for i in range(n):
        t = start + timedelta(minutes=i * INTERVAL_MIN)
        local_h = (t.hour + t.minute / 60.0)

        base = 100.0
        # Dawn phenomenon ~4–8am.
        base += 18 * math.exp(-((local_h - 6.0) ** 2) / 3.0)

        # Meals at ~8:00, 13:00, 20:00 — rise then decay over ~150 min.
        for meal_h, amp in ((8.0, 55), (13.0, 65), (20.0, 70)):
            dt = (local_h - meal_h) * 60.0  # minutes since meal
            if 0 <= dt <= 180:
                base += amp * math.exp(-((dt - 45) ** 2) / 1600.0)

        # Day-to-day variation + noise.
        base += 8 * math.sin(i / 37.0)
        base += random.gauss(0, 6)

        # Rare excursions.
        roll = random.random()
        if roll > 0.992:
            base += random.uniform(30, 70)   # a high
        elif roll < 0.004:
            base -= random.uniform(35, 55)   # a low

        val = max(55, min(245, round(base)))
        readings.append(
            {
                "glucoseValue": float(val),
                "trend": trend_for(val - prev),
                "readingAt": t.isoformat().replace("+00:00", "Z"),
            }
        )
        prev = val
    return readings


def main():
    print(f"Ensuring a device exists on {BASE} ...")
    dev = post(
        "/cgm-device/connect",
        {"serialNumber": "DEMO-0001", "deviceName": "Demo CGM", "manufacturer": "Eaglenos"},
    )
    print("  device:", dev.get("message"))

    readings = generate()
    print(f"Uploading {len(readings)} readings ({DAYS} days @ {INTERVAL_MIN} min) ...")

    ok = 0
    fail = 0

    def upload(r):
        nonlocal ok, fail
        # Gentle: this backend is a small instance — a heavy concurrent burst
        # knocks it over. Keep workers low + a tiny pause between requests.
        import time

        res = post("/cgm-reading/add", r)
        if res.get("success"):
            ok += 1
        else:
            fail += 1
        done = ok + fail
        if done % 100 == 0:
            print(f"  {done}/{len(readings)} (ok={ok} fail={fail})")
        time.sleep(0.05)

    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(upload, readings))

    print(f"Done. uploaded={ok} failed={fail}")
    print("Tip: open the app on this account — the dashboard should populate.")


if __name__ == "__main__":
    main()
