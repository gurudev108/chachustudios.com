#!/bin/bash
# Diagnostic script to check streaming setup
# Usage: ./check-streaming.sh

echo "=== Streaming Diagnostics ==="
echo ""

# Check if RTMP server is running
echo "1. Checking RTMP server processes..."
if pgrep -f "nginx.*rtmp" > /dev/null || pgrep -f "srs" > /dev/null || pgrep -f "rtmp" > /dev/null; then
    echo "   ✓ RTMP server process found"
    pgrep -fl "nginx.*rtmp|srs|rtmp" | head -3
else
    echo "   ✗ No RTMP server process found"
    echo "   → You may need to start nginx-rtmp or SRS server"
fi
echo ""

# Check if FFmpeg is streaming
echo "2. Checking FFmpeg streaming process..."
if pgrep -f "ffmpeg.*rtmp.*livestream" > /dev/null; then
    echo "   ✓ FFmpeg is streaming"
    pgrep -fl "ffmpeg.*rtmp.*livestream" | head -1
else
    echo "   ✗ FFmpeg is not streaming"
    echo "   → Run ./ffmpeg-screen-share.sh to start streaming"
fi
echo ""

# Check HLS files
echo "3. Checking HLS files in srv/tv/live/..."
if [ -d "srv/tv/live" ]; then
    echo "   ✓ Directory exists"
    echo "   Latest files:"
    ls -lth srv/tv/live/*.ts 2>/dev/null | head -5
    echo ""
    if [ -f "srv/tv/live/livestream.m3u8" ]; then
        echo "   ✓ M3U8 playlist exists"
        echo "   Last modified: $(stat -f "%Sm" srv/tv/live/livestream.m3u8)"
        echo "   Content preview:"
        head -10 srv/tv/live/livestream.m3u8 | sed 's/^/      /'
    else
        echo "   ✗ M3U8 playlist not found"
    fi
else
    echo "   ✗ Directory srv/tv/live/ does not exist"
fi
echo ""

# Check web server
echo "4. Checking web server..."
if pgrep -f "nginx|httpd|python.*http.server|python.*SimpleHTTPServer" > /dev/null; then
    echo "   ✓ Web server process found"
    pgrep -fl "nginx|httpd|python.*http.server|python.*SimpleHTTPServer" | head -3
else
    echo "   ⚠ No web server process found"
    echo "   → You may need to start a web server to serve HLS files"
    echo "   → Try: cd srv && python3 -m http.server 8000"
fi
echo ""

# Test M3U8 accessibility
echo "5. Testing M3U8 file accessibility..."
if [ -f "srv/tv/live/livestream.m3u8" ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/live/livestream.m3u8 2>/dev/null | grep -q "200"; then
        echo "   ✓ M3U8 accessible via HTTP (port 8000)"
    elif curl -s -o /dev/null -w "%{http_code}" http://localhost/live/livestream.m3u8 2>/dev/null | grep -q "200"; then
        echo "   ✓ M3U8 accessible via HTTP (port 80)"
    else
        echo "   ⚠ M3U8 file exists but may not be accessible via HTTP"
        echo "   → Make sure web server is configured to serve /live/ directory"
    fi
else
    echo "   ✗ M3U8 file not found"
fi
echo ""

echo "=== Summary ==="
echo "If streaming isn't working:"
echo "1. Ensure RTMP server (nginx-rtmp or SRS) is running"
echo "2. Ensure FFmpeg is streaming to rtmp://localhost/live/livestream"
echo "3. Ensure web server is serving files from srv/tv/live/"
echo "4. Check browser console for HLS.js errors"
echo "5. Verify URL: http://localhost:8000/live/livestream.m3u8 (or your server URL)"



