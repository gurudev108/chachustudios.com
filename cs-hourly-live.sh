#!/bin/bash
# Stream one recording at the top of every hour.
# Default behavior:
# - wait until next full hour (e.g., 08:23 -> starts 09:00)
# - stream once using configured video+audio files
# - when stream ends, wait for next full hour and repeat
#
# Usage:
#   ./cs-hourly-live.sh
#   ./cs-hourly-live.sh --test --once
#   ./cs-hourly-live.sh --now
#   ./cs-hourly-live.sh --config ./cs-hourly-live.conf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/cs-hourly-live.conf"
RUN_STREAM=true
WAIT_FOR_NEXT_HOUR=true
RUN_ONCE=false

usage() {
  echo "Usage: $0 [--test] [--once] [--now] [--config FILE]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --test)
      RUN_STREAM=false
      shift
      ;;
    --once)
      RUN_ONCE=true
      shift
      ;;
    --now)
      WAIT_FOR_NEXT_HOUR=false
      shift
      ;;
    --config)
      CONFIG_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [ -z "${DEFAULT_VIDEO:-}" ] || [ -z "${DEFAULT_AUDIO:-}" ]; then
  echo "Error: DEFAULT_VIDEO and DEFAULT_AUDIO must be set in $CONFIG_FILE"
  exit 1
fi

RTMP_URL="${RTMP_URL:-rtmp://localhost/live/livestream}"

resolve_path() {
  local input_path="$1"
  if [[ "$input_path" = /* ]]; then
    echo "$input_path"
  else
    echo "$SCRIPT_DIR/$input_path"
  fi
}

sleep_until_next_hour() {
  local now_epoch next_hour_epoch sleep_seconds
  now_epoch="$(date +%s)"
  next_hour_epoch="$(( (now_epoch / 3600 + 1) * 3600 ))"
  sleep_seconds="$(( next_hour_epoch - now_epoch ))"

  echo "Waiting ${sleep_seconds}s until next hourly slot at $(date -r "$next_hour_epoch" '+%Y-%m-%d %H:%M:%S')"
  sleep "$sleep_seconds"
}

slot_value_or_default() {
  local hour="$1"
  local kind="$2"
  local default_value="$3"
  local var_name="SLOT_${hour}_${kind}"
  local slot_value="${!var_name:-}"

  if [ -n "$slot_value" ]; then
    echo "$slot_value"
  else
    echo "$default_value"
  fi
}

run_slot() {
  local hour video_rel audio_rel video_file audio_file
  hour="$(date +%H)"

  video_rel="$(slot_value_or_default "$hour" "VIDEO" "$DEFAULT_VIDEO")"
  audio_rel="$(slot_value_or_default "$hour" "AUDIO" "$DEFAULT_AUDIO")"

  video_file="$(resolve_path "$video_rel")"
  audio_file="$(resolve_path "$audio_rel")"

  if [ ! -f "$video_file" ]; then
    echo "Error: Video file not found: $video_file"
    return 1
  fi

  if [ ! -f "$audio_file" ]; then
    echo "Error: Audio file not found: $audio_file"
    return 1
  fi

  CMD=(
    ffmpeg
    -re -i "$video_file"
    -re -i "$audio_file"
    -map 0:v:0 -map 1:a:0
    -vcodec libx264 -preset veryfast -tune zerolatency
    -pix_fmt yuv420p
    -acodec aac -b:a 128k -ar 44100 -ac 2
    -shortest
    -f flv "$RTMP_URL"
  )

  echo ""
  echo "=== Hourly Slot $(date '+%Y-%m-%d %H:00') ==="
  echo "Video: $video_rel"
  echo "Audio: $audio_rel"
  echo "Target: $RTMP_URL"
  echo "Command:"
  printf ' %q' "${CMD[@]}"
  echo ""
  echo ""

  if [ "$RUN_STREAM" = true ]; then
    "${CMD[@]}"
  else
    echo "[test] Dry run only (not executing ffmpeg)."
  fi
}

if [ "$WAIT_FOR_NEXT_HOUR" = true ]; then
  sleep_until_next_hour
fi

while true; do
  if ! run_slot; then
    echo "Slot failed. Retrying at next hour."
  fi

  if [ "$RUN_ONCE" = true ]; then
    break
  fi

  sleep_until_next_hour
done
