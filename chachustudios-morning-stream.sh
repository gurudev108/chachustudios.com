#!/bin/bash
# ChachuStudios morning stream utility:
# - Auto-detects Logitech BRIO (video) and RODECaster Pro Stereo (audio)
# - Builds ffmpeg command for RTMP live stream
# - Dry-run by default; pass --run to start streaming
#
# Usage:
#   ./chachustudios-morning-stream.sh
#   ./chachustudios-morning-stream.sh --run
#   ./chachustudios-morning-stream.sh --list
#   ./chachustudios-morning-stream.sh --run --video-size 1920x1080 --fps 30
#
# Optional env overrides:
#   VIDEO_DEVICE_NAME="Logitech BRIO"
#   AUDIO_DEVICE_NAME="RODECaster Pro Stereo"
#   RTMP_URL="rtmp://localhost/live/livestream"

set -euo pipefail

VIDEO_DEVICE_NAME="${VIDEO_DEVICE_NAME:-Logitech BRIO}"
AUDIO_DEVICE_NAME="${AUDIO_DEVICE_NAME:-RODECaster Pro Stereo}"
RTMP_URL="${RTMP_URL:-rtmp://localhost/live/livestream}"
VIDEO_SIZE="1280x720"
FPS="30"
RUN_STREAM=false

usage() {
  echo "Usage: $0 [--run] [--list] [--video-size WxH] [--fps N] [--rtmp URL]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --run)
      RUN_STREAM=true
      shift
      ;;
    --list)
      ffmpeg -f avfoundation -list_devices true -i "" 2>&1 || true
      exit 0
      ;;
    --video-size)
      VIDEO_SIZE="${2:-}"
      shift 2
      ;;
    --fps)
      FPS="${2:-}"
      shift 2
      ;;
    --rtmp)
      RTMP_URL="${2:-}"
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

AVFOUNDATION_LIST="$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1 || true)"

extract_device_index() {
  local section="$1"
  local target_name="$2"
  local mode=""
  local line=""
  local target_lc=""
  local idx=""
  local name=""
  local name_lc=""

  target_lc="$(printf '%s' "$target_name" | tr '[:upper:]' '[:lower:]')"

  while IFS= read -r line; do
    case "$line" in
      *"AVFoundation video devices:"*)
        mode="video"
        continue
        ;;
      *"AVFoundation audio devices:"*)
        mode="audio"
        continue
        ;;
    esac

    [ "$mode" = "$section" ] || continue

    if [[ "$line" =~ \[([0-9]+)\][[:space:]](.*)$ ]]; then
      idx="${BASH_REMATCH[1]}"
      name="${BASH_REMATCH[2]}"
      name_lc="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

      case "$name_lc" in
        *"$target_lc"*)
          echo "$idx"
          return 0
          ;;
      esac
    fi
  done <<< "$AVFOUNDATION_LIST"

  return 1
}

VIDEO_INDEX="$(extract_device_index "video" "$VIDEO_DEVICE_NAME" || true)"
AUDIO_INDEX="$(extract_device_index "audio" "$AUDIO_DEVICE_NAME" || true)"

if [ -z "$VIDEO_INDEX" ]; then
  echo "Error: Could not find video device matching '$VIDEO_DEVICE_NAME'."
  echo "Run: $0 --list"
  exit 1
fi

if [ -z "$AUDIO_INDEX" ]; then
  echo "Error: Could not find audio device matching '$AUDIO_DEVICE_NAME'."
  echo "Run: $0 --list"
  exit 1
fi

CMD=(
  ffmpeg
  -f avfoundation
  -framerate "$FPS"
  -video_size "$VIDEO_SIZE"
  -i "${VIDEO_INDEX}:${AUDIO_INDEX}"
  -vcodec libx264
  -preset veryfast
  -tune zerolatency
  -pix_fmt yuv420p
  -acodec aac
  -b:a 128k
  -ar 48000
  -ac 2
  -f flv
  "$RTMP_URL"
)

echo "Camera match : $VIDEO_DEVICE_NAME -> index $VIDEO_INDEX"
echo "Audio match  : $AUDIO_DEVICE_NAME -> index $AUDIO_INDEX"
echo "Video size   : $VIDEO_SIZE"
echo "FPS          : $FPS"
echo "RTMP target  : $RTMP_URL"
echo ""
echo "Generated command:"
printf ' %q' "${CMD[@]}"
echo ""
echo ""

if [ "$RUN_STREAM" = true ]; then
  echo "Starting stream now. Press [q] in ffmpeg to stop."
  "${CMD[@]}"
else
  echo "Dry run only. Add --run to start streaming."
fi
