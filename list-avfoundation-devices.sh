#!/bin/bash
# List all available AVFoundation devices (cameras and microphones)
# Usage: ./list-avfoundation-devices.sh

echo "=== Available AVFoundation Devices ==="
echo ""
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -A 100 "AVFoundation"



