# Building and Running PerformanceMonitor

## Prerequisites

**Important:** Building macOS apps requires **full Xcode** (not just Command Line Tools).

Run the initialization script to set up your development environment:

```bash
./init.sh
```

This will:
- Check for Xcode installation
- Configure xcode-select
- Verify your environment is ready

## Building in Cursor

### Option 1: Using Scripts (Recommended)

```bash
# Build and run the app (Debug configuration)
./run.sh

# Build and run Release configuration
./run.sh Release
```

### Option 2: Using xcodebuild Directly

```bash
# Build Debug
xcodebuild -project PerformanceMonitor/PerformanceMonitor.xcodeproj -scheme PerformanceMonitor -configuration Debug clean build

# Build Release
xcodebuild -project PerformanceMonitor/PerformanceMonitor.xcodeproj -scheme PerformanceMonitor -configuration Release clean build
```

The built app will be in: `./build/Build/Products/Debug/PerformanceMonitor.app` (or `Release`)

### Option 3: Using Xcode GUI

1. Double-click `PerformanceMonitor/PerformanceMonitor.xcodeproj` to open in Xcode
2. Select the scheme: **PerformanceMonitor** (top toolbar)
3. Select configuration: **Debug** or **Release**
4. Build: Press `⌘B` or Product > Build
5. Run: Press `⌘R` or Product > Run

## Running the App

After building, you can run the app in several ways:

### From Terminal/Cursor

```bash
# Launch the built app
open ./build/Build/Products/Debug/UptimeMonitor.app

# Or use the run script
./run.sh
```

### From Finder

Navigate to `./build/Build/Products/Debug/` and double-click `UptimeMonitor.app`

### From Xcode

Press `⌘R` or click the Run button in Xcode

## Deployment

### Creating a Release Build

```bash
./run.sh Release
```

The Release build will be optimized and smaller.

### Distributing the App

1. Build Release version:
   ```bash
   ./run.sh Release
   ```

2. The app bundle is located at:
   ```
   ./build/Build/Products/Release/UptimeMonitor.app
   ```

3. You can:
   - Copy the `.app` bundle to `/Applications` for system-wide installation
   - Zip it for distribution
   - Create a DMG for distribution (requires additional tools)

### Code Signing (Optional)

For distribution outside the App Store, you may want to code sign:

```bash
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" ./build/Build/Products/Release/UptimeMonitor.app
```

## Troubleshooting

### "xcodebuild requires Xcode" Error

- Make sure you have full Xcode installed (not just Command Line Tools)
- Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

### "Scheme not found" Error

- Open the project in Xcode first
- Xcode will auto-generate schemes
- Or manually create a scheme: Product > Scheme > Manage Schemes

### Build Errors

- Make sure all Swift files are added to the Xcode project
- Check that `Info.plist` is properly referenced
- Verify deployment target is macOS 13.0+

### App Doesn't Appear in Menu Bar

- Check Console.app for error messages
- Verify `LSUIElement = YES` is set in Info.plist
- Make sure you're running macOS 13.0 or later

## Development Workflow

1. **Initial setup**: Run `./init.sh` once after cloning
2. **Edit code** in Cursor
3. **Build and run** using `./run.sh` or Xcode
4. **Test** the menu bar app
5. **Iterate**

The app will appear in your menu bar (top right) once running.

