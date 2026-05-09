#!/bin/bash
# FFmpeg audio-only streaming command
# Usage: ./ffmpeg-audio-only.sh [audio_device_index]
# To find audio devices: ffmpeg -f avfoundation -list_devices true -i ""

AUDIO_DEVICE="${1:-2}"

echo "Streaming audio from device $AUDIO_DEVICE"
echo "Press [q] to stop"
echo ""

ffmpeg -f avfoundation \
  -i ":$AUDIO_DEVICE" \
  -vn \
  -acodec aac \
  -b:a 128k \
  -ar 44100 \
  -ac 2 \
  -f flv \
  rtmp://localhost/live/livestream

