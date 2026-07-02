#!/bin/bash
# Write live slot metadata to srv/tv/schedule.json for tv.chachustudios.com wall-clock sync.
#
# Usage:
#   ./cs-update-tv-schedule.sh --start --hour 16 --video path/to/video.mp4
#   ./cs-update-tv-schedule.sh --clear

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEDULE_FILE="$SCRIPT_DIR/srv/tv/schedule.json"
DEFAULT_CUES="/kriya/default.json"
DEFAULT_TZ="America/Los_Angeles"

ACTION=""
HOUR=""
VIDEO_FILE=""
CUES=""
SUBJECT=""

usage() {
  echo "Usage: $0 --start --hour HH --video FILE [--cues PATH] [--subject TEXT]"
  echo "       $0 --clear"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --start) ACTION="start"; shift ;;
    --clear) ACTION="clear"; shift ;;
    --hour) HOUR="${2:-}"; shift 2 ;;
    --video) VIDEO_FILE="${2:-}"; shift 2 ;;
    --cues) CUES="${2:-}"; shift 2 ;;
    --subject) SUBJECT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ "$ACTION" = "start" ]; then
  if [ -z "$HOUR" ] || [ -z "$VIDEO_FILE" ]; then
    echo "Error: --start requires --hour and --video"
    exit 1
  fi
  if [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: Video file not found: $VIDEO_FILE"
    exit 1
  fi

  DURATION="$(
    ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO_FILE" 2>/dev/null \
      | awk '{printf "%.0f", $1}'
  )"
  if [ -z "$DURATION" ] || [ "$DURATION" = "0" ]; then
    DURATION=2462
  fi

  CUES="${CUES:-$DEFAULT_CUES}"
  SUBJECT="${SUBJECT:-Stimulate Kundalini — guided kriya practice}"
  SLOT_EPOCH="$(date +%s)"

  python3 - "$ACTION" "$SCHEDULE_FILE" "$SLOT_EPOCH" "$HOUR" "$DURATION" "$CUES" "$SUBJECT" "$DEFAULT_TZ" <<'PY'
import json
import sys
from pathlib import Path

action, path, slot_epoch, hour, duration, cues, subject, tz = sys.argv[1:9]
p = Path(path)
base = {
    "timezone": tz,
    "slot": "hourly",
    "durationSeconds": int(duration),
    "title": "ChaChu TV",
    "subject": subject,
    "cues": cues,
    "note": "Streams at the top of every hour while cs-hourly-live.sh is running on the server.",
    "hourSlots": {},
}

if p.exists():
    try:
        base.update(json.loads(p.read_text()))
    except json.JSONDecodeError:
        pass

base["slotStartEpoch"] = int(slot_epoch)
base["activeHour"] = hour.zfill(2)
base["durationSeconds"] = int(duration)
base["cues"] = cues
base["subject"] = subject
slots = base.setdefault("hourSlots", {})
key = hour.zfill(2)
slot_entry = slots.get(key, {})
slot_entry["cues"] = cues
slot_entry["subject"] = subject
slots[key] = slot_entry

p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(base, indent=2) + "\n")
print(f"Updated {p}")
PY

elif [ "$ACTION" = "clear" ]; then
  python3 - "$SCHEDULE_FILE" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
base = {}
if p.exists():
    try:
        base = json.loads(p.read_text())
    except json.JSONDecodeError:
        pass
base["slotStartEpoch"] = None
base["activeHour"] = None
p.write_text(json.dumps(base, indent=2) + "\n")
print(f"Cleared active slot in {p}")
PY
else
  echo "Error: use --start or --clear"
  usage
  exit 1
fi
