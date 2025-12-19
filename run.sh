#!/bin/bash
# Build and run Performance Monitor

set -e

PROJECT_NAME="PerformanceMonitor"
SCHEME="PerformanceMonitor"
CONFIGURATION="${1:-Debug}"

echo "Building Performance Monitor ($CONFIGURATION)..."
echo "================================================="

# Check if xcodebuild is available and working
if ! xcodebuild -version &> /dev/null; then
    echo ""
    echo "Error: xcodebuild not available or not configured."
    echo "Please run ./init.sh first to set up your development environment."
    exit 1
fi

# Build the project
xcodebuild \
    -project "${PROJECT_NAME}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath ./build \
    clean build

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
