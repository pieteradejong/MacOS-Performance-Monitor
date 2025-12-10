#!/bin/bash
# Run script for Performance Monitor
# This script builds and runs the app

set -e

PROJECT_NAME="PerformanceMonitor"
CONFIGURATION="${1:-Debug}"

echo "Building and running Performance Monitor..."
echo "=========================================="

# First, build the app
./build.sh "$CONFIGURATION"

# Find the built app
APP_PATH="./build/Build/Products/${CONFIGURATION}/PerformanceMonitor.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo ""
echo "Launching Performance Monitor..."
echo "================================="

# Kill any existing instance
pkill -f "PerformanceMonitor" || true

# Launch the app
open "$APP_PATH"

echo "App launched! Check your menu bar for the Performance Monitor icon."
