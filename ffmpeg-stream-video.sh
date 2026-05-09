#!/bin/bash
# Stream video from one MP4 and audio from another MP4 to RTMP.
#
# Usage:
#   ./ffmpeg-stream-video.sh [video_mp4] [audio_mp4] [--run]
#
# Examples:
#   # Preview command only (default)
#   ./ffmpeg-stream-video.sh \
#     /path/to/video.mp4 \
#     /path/to/audio.mp4
#
#   # Actually run ffmpeg
#   ./ffmpeg-stream-video.sh \
#     /path/to/video.mp4 \
#     /path/to/audio.mp4 \
#     --run

set -euo pipefail

DEFAULT_VIDEO="/Users/shiningankit/Workspace/Github/chachustudios.com/srv/tv/studios/92129/2026-04-03.mp4"
DEFAULT_AUDIO="/Users/shiningankit/Workspace/Github/chachustudios.com/srv/tv/kirtan/RadheGovinda-RadhikaDas.mp4"
RTMP_URL="${RTMP_URL:-rtmp://localhost/live/livestream}"

VIDEO_FILE="${1:-$DEFAULT_VIDEO}"
AUDIO_FILE="${2:-$DEFAULT_AUDIO}"
RUN_STREAM="${3:-}"

if [ ! -f "$VIDEO_FILE" ]; then
  echo "Error: Video file not found: $VIDEO_FILE"
  exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
  echo "Error: Audio file not found: $AUDIO_FILE"
  exit 1
fi

# Re-encode for stable FLV output and explicit stream mapping.
CMD=(
  ffmpeg
  -re -stream_loop -1 -i "$VIDEO_FILE"
  -re -stream_loop -1 -i "$AUDIO_FILE"
  -map 0:v:0 -map 1:a:0
  -c:v libx264 -preset veryfast -tune zerolatency
  -pix_fmt yuv420p
  -c:a aac -b:a 128k -ar 44100 -ac 2
  -shortest
  -f flv "$RTMP_URL"
)

echo "Video source: $VIDEO_FILE"
echo "Audio source: $AUDIO_FILE"
echo "RTMP target : $RTMP_URL"
echo ""
echo "Generated command:"
printf ' %q' "${CMD[@]}"
echo ""
echo ""

if [ "$RUN_STREAM" = "--run" ]; then
  echo "Starting stream. Press [q] in ffmpeg to stop."
  "${CMD[@]}"
else
  echo "Dry run only. Add --run to execute."
fi



