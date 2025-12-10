# Quick Start Guide

## Step 1: First Launch Setup (if needed)

Run this command in Terminal (you'll need to enter your password):
```bash
sudo xcodebuild -runFirstLaunch
```

Or simply open Xcode once - it will prompt you to install additional components if needed.

## Step 2: Open Project in Xcode

**Important:** The project file is currently incomplete. You need to open it in Xcode first to properly configure it.

```bash
open UptimeMonitor.xcodeproj
```

## Step 3: Add Missing Files to Project

When Xcode opens, you'll need to add all Swift files:

1. In Xcode's Project Navigator (left sidebar), right-click on the `UptimeMonitor` folder
2. Select **"Add Files to 'UptimeMonitor'..."**
3. Navigate to and select these files/folders:
   - `UptimeMonitor/Models/` (all Swift files)
   - `UptimeMonitor/Views/` (all Swift files)
   - `UptimeMonitor/Utilities/` (all Swift files)
4. Make sure **"Copy items if needed"** is **UNCHECKED**
5. Make sure **"Create groups"** is selected
6. Make sure **"Add to targets: UptimeMonitor"** is **CHECKED**
7. Click **Add**

## Step 4: Verify Build Target

1. Click on the project name in the Project Navigator (top item)
2. Select the **UptimeMonitor** target
3. Go to **Build Phases** tab
4. Expand **Compile Sources**
5. Verify all 9 Swift files are listed:
   - UptimeMonitorApp.swift
   - SystemMonitor.swift
   - SystemSnapshot.swift
   - HealthStatus.swift
   - MenuContentView.swift
   - HealthIndicatorView.swift
   - Shell.swift
   - UptimeParser.swift
   - VMStatParser.swift

## Step 5: Build and Run

### Option A: From Xcode
- Press `⌘B` to build
- Press `⌘R` to run

### Option B: From Terminal/Cursor
After Xcode has properly configured the project, you can use:

```bash
# Build
./build.sh

# Build and run
./run.sh
```

## Troubleshooting

### If build fails with "No such module" errors:
- Make sure all Swift files are added to the target (Step 4)
- Clean build folder: Product > Clean Build Folder (Shift+⌘+K)
- Try building again

### If the app doesn't appear in menu bar:
- Check Console.app for errors
- Verify Info.plist has `LSUIElement = YES`
- Make sure you're running macOS 13.0+
