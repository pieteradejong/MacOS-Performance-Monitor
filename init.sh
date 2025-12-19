#!/bin/bash
# Initialize development environment for Performance Monitor
# Run this once after cloning the repository

set -e

echo "Performance Monitor - Development Setup"
echo "========================================"
echo ""

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This project requires macOS"
    exit 1
fi
echo "✅ macOS detected"

# Check for Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "⏳ Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    echo "Please complete the installation dialog, then run this script again."
    exit 0
fi
echo "✅ Xcode Command Line Tools installed"

# Check for full Xcode installation
if ! [ -d "/Applications/Xcode.app" ]; then
    echo ""
    echo "❌ Full Xcode installation not found"
    echo ""
    echo "This project requires Xcode (not just Command Line Tools) to build macOS apps."
    echo ""
    echo "Please install Xcode from the App Store:"
    echo "  https://apps.apple.com/app/xcode/id497799835"
    echo ""
    echo "Then run this script again."
    exit 1
fi
echo "✅ Xcode.app found"

# Check if xcode-select points to full Xcode
CURRENT_DEVELOPER_DIR=$(xcode-select -p)
EXPECTED_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

if [[ "$CURRENT_DEVELOPER_DIR" != "$EXPECTED_DEVELOPER_DIR" ]]; then
    echo ""
    echo "⚠️  xcode-select is pointing to: $CURRENT_DEVELOPER_DIR"
    echo "   It should point to: $EXPECTED_DEVELOPER_DIR"
    echo ""
    echo "Attempting to fix (requires sudo)..."
    sudo xcode-select --switch "$EXPECTED_DEVELOPER_DIR"
    echo "✅ xcode-select configured"
else
    echo "✅ xcode-select configured correctly"
fi

# Verify xcodebuild works
if ! xcodebuild -version &> /dev/null; then
    echo ""
    echo "❌ xcodebuild failed to run"
    echo ""
    echo "You may need to accept the Xcode license. Run:"
    echo "  sudo xcodebuild -license accept"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
echo "✅ $XCODE_VERSION"

# Check Xcode project exists
if ! [ -d "PerformanceMonitor/PerformanceMonitor.xcodeproj" ]; then
    echo ""
    echo "❌ Xcode project not found at PerformanceMonitor/PerformanceMonitor.xcodeproj"
    echo "   Please ensure you're running this from the repository root."
    exit 1
fi
echo "✅ Xcode project found"

# Make scripts executable
chmod +x run.sh 2>/dev/null || true
chmod +x init.sh 2>/dev/null || true
echo "✅ Scripts made executable"

echo ""
echo "========================================"
echo "✅ Setup complete!"
echo ""
echo "To build and run the app:"
echo "  ./run.sh"
echo ""
echo "The app will appear in your menu bar."
echo "========================================"
