#!/bin/bash
# FFmpeg screen sharing command with aspect ratio preservation
# Usage: ./ffmpeg-screen-share-preserve-aspect.sh

ffmpeg -f avfoundation \
  -framerate 30 \
  -video_size 1280x720 \
  -i "3:1" \
  -vf "scale='1280:-2',pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,format=yuv420p" \
  -vcodec libx264 \
  -preset veryfast \
  -tune zerolatency \
  -pix_fmt yuv420p \
  -g 60 \
  -b:v 2500k \
  -maxrate 2500k \
  -bufsize 5000k \
  -f flv \
  rtmp://localhost/live/livestream



