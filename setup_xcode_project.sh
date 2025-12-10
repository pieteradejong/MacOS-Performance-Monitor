#!/bin/bash
# Setup script for UptimeMonitor Xcode project

set -e

PROJECT_NAME="UptimeMonitor"
CURRENT_DIR=$(pwd)

echo "UptimeMonitor - Xcode Project Setup"
echo "===================================="
echo ""
echo "This script will help you set up the Xcode project."
echo ""
echo "Option 1: Manual Setup (Recommended)"
echo "1. Open Xcode"
echo "2. File > New > Project"
echo "3. Choose macOS > App"
echo "4. Product Name: $PROJECT_NAME"
echo "5. Interface: SwiftUI, Language: Swift"
echo "6. Save location: $CURRENT_DIR"
echo "7. After creation, delete the default ContentView.swift"
echo "8. Add all files from the $PROJECT_NAME/ folder to your project"
echo "9. In project settings > Info tab, add LSUIElement = YES"
echo ""
echo "Option 2: Use xcodegen (if installed)"
if command -v xcodegen &> /dev/null; then
    echo "xcodegen is installed. Creating project.yml..."
    cat > project.yml << 'YAML'
name: UptimeMonitor
options:
  bundleIdPrefix: com.uptimemonitor
  deploymentTarget:
    macOS: "13.0"
targets:
  UptimeMonitor:
    type: application
    platform: macOS
    sources:
      - path: UptimeMonitor
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.uptimemonitor.UptimeMonitor
      MACOSX_DEPLOYMENT_TARGET: "13.0"
      INFOPLIST_FILE: UptimeMonitor/Info.plist
      INFOPLIST_KEY_LSUIElement: YES
YAML
    echo "Running xcodegen..."
    xcodegen generate
    echo "Project created! Open UptimeMonitor.xcodeproj in Xcode"
else
    echo "xcodegen is not installed. Install with: brew install xcodegen"
    echo "Or use Option 1 (Manual Setup) above"
fi

echo ""
echo "After setup, build and run the project in Xcode (⌘R)"




