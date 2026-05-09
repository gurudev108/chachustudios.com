#!/bin/bash
# Simple script to play video files
# Usage: ./play-video.sh [video_file_path]

VIDEO_FILE="${1:-/Users/shiningankit/Workspace/Github/chachustudios.com/static/media/SantaBaby.mp4}"

if [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: Video file not found: $VIDEO_FILE"
    exit 1
fi

echo "Playing: $VIDEO_FILE"
echo ""

# Try different players in order of preference
if command -v ffplay &> /dev/null; then
    echo "Using ffplay..."
    ffplay -autoexit "$VIDEO_FILE"
elif command -v vlc &> /dev/null; then
    echo "Using VLC..."
    vlc "$VIDEO_FILE" 2>/dev/null
elif command -v open &> /dev/null; then
    echo "Using macOS default player..."
    open "$VIDEO_FILE"
elif command -v xdg-open &> /dev/null; then
    echo "Using xdg-open..."
    xdg-open "$VIDEO_FILE"
else
    echo "No video player found. Please install ffplay, VLC, or use your system's default player."
    exit 1
fi



