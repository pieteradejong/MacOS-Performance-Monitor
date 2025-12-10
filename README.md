# UptimeMonitor

MacOS Performance Monitor is a lightweight, menu-bar utility that continuously tracks system uptime, CPU load averages, memory pressure, and swap usage, then classifies overall system health into OK, Warning, or Critical. It provides a simple colored indicator in the menu bar and a clean dropdown with actionable insights, telling you when your Mac is behaving normally and when it’s headed toward sluggishness or instability due to long uptime, memory pressure, or runaway background tasks.



A macOS menu bar app that displays system uptime and health indicators.

## Features

Features

Real-time system monitoring (updates every 10 seconds)

Uptime

Load averages (1/5/15 min)

Swap memory usage

Free memory

Automatic health classification

OK → System healthy

Warning → Early signs of pressure (uptime, load, swap)

Critical → High likelihood of slowdown; reboot or close apps recommended

Clean macOS menu-bar integration

Color-coded indicator (green/yellow/red)

SF Symbol reflecting severity

Tooltip with quick status

Detailed dropdown panel

Health indicator + label

Formatted uptime display

Load averages

Swap usage

Free RAM

Brief, human-readable advice

Lightweight, no dependencies

Shell-based metric collection

SwiftUI interface

Minimal CPU/memory footprint
## Setup Instructions

### Option 1: Create Xcode Project Manually (Recommended)

1. Open Xcode
2. File > New > Project
3. Choose **macOS** > **App**
4. Configure:
   - Product Name: `UptimeMonitor`
   - Team: (your team or None)
   - Organization Identifier: `com.yourname` (or any identifier)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests" (optional)
5. Save in: `/Users/pieterdejong/dev/projects/MacOS-Performance-Monitor`
6. Delete the default `ContentView.swift` and `UptimeMonitorApp.swift` files that Xcode creates
7. In Xcode, right-click on the project > Add Files to "UptimeMonitor"...
8. Select the entire `UptimeMonitor` folder (make sure "Create groups" is selected)
9. In the project settings:
   - Go to the target's **Info** tab
   - Add `LSUIElement` key with value `YES` (or edit Info.plist directly)
   - Set **Minimum Deployments** to macOS 13.0 or later
10. Build and run (⌘R)

### Option 2: Use Existing Project File

If an `UptimeMonitor.xcodeproj` file exists, simply:
1. Double-click `UptimeMonitor.xcodeproj` to open in Xcode
2. Build and run (⌘R)

## Project Structure

```
UptimeMonitor/
├── UptimeMonitorApp.swift       # App entry point with MenuBarExtra
├── Info.plist                   # LSUIElement = YES configuration
├── Models/
│   ├── SystemMonitor.swift      # Observable object for system metrics
│   └── HealthStatus.swift       # Health status enum
├── Views/
│   ├── MenuContentView.swift    # Main menu UI
│   └── HealthIndicatorView.swift # Health indicator component
└── Utilities/
    ├── VMStatParser.swift       # Parses vm_stat output
    └── Shell.swift              # Shell command execution
```

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Building and Running

### Quick Start (from Cursor)

**Yes, you can work entirely in Cursor!** See [CURSOR_WORKFLOW.md](./CURSOR_WORKFLOW.md) for the complete guide.

```bash
# Build the app
./build.sh

# Build and run
./run.sh
```

**Note:** Building requires full Xcode (not just Command Line Tools). See [BUILD.md](./BUILD.md) for detailed instructions.

### Using Xcode

1. Double-click `UptimeMonitor.xcodeproj` to open in Xcode
2. Build the project (⌘B)
3. Run the app (⌘R)
4. The app will appear in your menu bar showing uptime
5. Click the menu bar icon to see detailed system information

**Important:** If the project file is incomplete, you may need to:
- Open the project in Xcode
- Add all Swift files from the `UptimeMonitor/` folder to the project
- Ensure all files are included in the build target

For more details, see [BUILD.md](./BUILD.md).

## How It Works

- **Uptime**: Retrieved from `ProcessInfo.processInfo.systemUptime`
- **Swap Usage**: Parsed from `sysctl vm.swapusage`
- **Memory Compression**: Parsed from `vm_stat` output
- **Health Status**: Calculated based on uptime and swap usage thresholds

## Health Status Logic

- **Healthy** (Green): Uptime < 7 days AND swap < 1 GB
- **Warning** (Yellow): Uptime ≥ 7 days OR swap ≥ 1 GB
- **Critical** (Red): Uptime ≥ 14 days OR swap ≥ 3 GB

## Notes

- The app runs as a menu bar-only app (no Dock icon) due to `LSUIElement = YES`
- Metrics update every 10 seconds automatically (configurable in `SystemMonitor.swift`)
- The app requires appropriate permissions to read system information




