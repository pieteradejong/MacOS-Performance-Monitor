#!/bin/bash
# Run script for UptimeMonitor
# This script builds and runs the app

set -e

PROJECT_NAME="UptimeMonitor"
CONFIGURATION="${1:-Debug}"

echo "Building and running $PROJECT_NAME..."
echo "====================================="

# First, build the app
./build.sh "$CONFIGURATION"

# Find the built app
APP_PATH="./build/Build/Products/${CONFIGURATION}/UptimeMonitor.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo ""
echo "Launching $PROJECT_NAME..."
echo "=========================="

# Kill any existing instance
pkill -f "UptimeMonitor" || true

# Launch the app
open "$APP_PATH"

echo "App launched! Check your menu bar for the UptimeMonitor icon."
