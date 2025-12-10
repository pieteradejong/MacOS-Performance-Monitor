#!/bin/bash
# Build script for Performance Monitor
# This script builds the app using xcodebuild

set -e

PROJECT_NAME="PerformanceMonitor"
SCHEME="PerformanceMonitor"
CONFIGURATION="${1:-Debug}"  # Default to Debug, can pass "Release"

echo "Building Performance Monitor ($CONFIGURATION)..."
echo "================================================"

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Please install Xcode from the App Store."
    echo "Note: Command Line Tools alone are not sufficient for building macOS apps."
    exit 1
fi

# Check if developer directory is set correctly
if ! xcodebuild -version &> /dev/null; then
    echo "Error: xcodebuild requires full Xcode installation."
    echo "Please run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

# Build the project
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath ./build \
    clean build

echo ""
echo "Build completed successfully!"
echo "App location: ./build/Build/Products/${CONFIGURATION}/PerformanceMonitor.app"
