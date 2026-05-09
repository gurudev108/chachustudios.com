#!/bin/bash
# Quick start script for streaming setup
# This starts a simple HTTP server to serve HLS files
# Note: You still need an RTMP server (nginx-rtmp or SRS) for RTMP->HLS conversion

echo "Starting HTTP server on port 8000 to serve HLS files..."
echo "Access the stream at: http://localhost:8000/tv/index.html"
echo ""
echo "IMPORTANT: Make sure your RTMP server (nginx-rtmp or SRS) is running!"
echo "Press Ctrl+C to stop"
echo ""

cd /Users/shiningankit/Workspace/Github/chachustudios.com/srv
python3 -m http.server 8000



