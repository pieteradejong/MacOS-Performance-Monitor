# Learnings & Troubleshooting Guide

This document captures all the issues we encountered while building this macOS Performance Monitor app and how we fixed them. Useful for future reference and for others learning Swift/SwiftUI/macOS development.

## Table of Contents

1. [Xcode Project File Corruption](#xcode-project-file-corruption)
2. [ObservableObject Conformance Error](#observableobject-conformance-error)
3. [Menu Bar App Not Visible](#menu-bar-app-not-visible)
4. [Build Target Membership](#build-target-membership)
5. [Swift 6 Concurrency & MainActor](#swift-6-concurrency--mainactor)
6. [Project Structure & Naming](#project-structure--naming)
7. [General Swift/SwiftUI Learnings](#general-swiftswiftui-learnings)

---

## Xcode Project File Corruption

### Problem
When trying to open `UptimeMonitor.xcodeproj`, Xcode showed:
> "The project 'UptimeMonitor' is damaged and cannot be opened."

**Error Details:**
- Exception: `-[XCConfigurationList _setSavedArchiveVersion:]: unrecognized selector sent to instance`
- This indicated the `project.pbxproj` file was corrupted or incomplete

### Root Cause
The project file was manually generated and only included 1 of 9 Swift files. Xcode couldn't properly parse the incomplete project structure.

### Solution
**Create a fresh Xcode project:**
1. Open Xcode → File > New > Project
2. Choose macOS > App
3. Configure with proper settings
4. Add all Swift files to the project manually
5. Ensure all files are added to the build target

**Key Lesson:** Always create Xcode projects through Xcode itself, or use tools like `xcodegen` for programmatic project generation. Manual `project.pbxproj` editing is error-prone.

---

## ObservableObject Conformance Error

### Problem
Build error:
```
Type 'SystemMonitor' does not conform to protocol 'ObservableObject'
```

The `SystemMonitor` class was correctly defined as:
```swift
class SystemMonitor: ObservableObject {
    @Published var snapshot: SystemSnapshot?
    @Published var health: HealthStatus = .ok
    // ...
}
```

But Xcode still complained it didn't conform.

### Root Cause
**Missing `import Combine`**

`ObservableObject` is part of the Combine framework, not SwiftUI. While SwiftUI imports Combine transitively, Swift 6's strict concurrency checking requires explicit imports.

### Solution
Add explicit Combine import:
```swift
import Foundation
import SwiftUI
import Combine  // ← This was the fix!

class SystemMonitor: ObservableObject {
    // ...
}
```

### Diagnostic Commands Used
```bash
# Check build errors
xcodebuild -project PerformanceMonitor.xcodeproj -scheme PerformanceMonitor build 2>&1 | grep error

# Verify file is being compiled
xcodebuild -project PerformanceMonitor.xcodeproj -scheme PerformanceMonitor build 2>&1 | grep SystemMonitor

# Check Swift version
swift --version
```

**Key Lesson:** 
- `ObservableObject` is from Combine, not SwiftUI
- Swift 6 requires explicit imports for protocol conformance checking
- Always import frameworks explicitly, don't rely on transitive imports

---

## Menu Bar App Not Visible

### Problem
App builds successfully and runs (process visible in Activity Monitor), but doesn't appear in the menu bar. No icon shows up.

**Symptoms:**
- `ps aux | grep PerformanceMonitor` shows process running
- No menu bar icon visible
- No Dock icon (which is correct for menu bar apps)

### Root Cause
`LSUIElement` was not set in the app's Info.plist. When Xcode auto-generates Info.plist (`GENERATE_INFOPLIST_FILE = YES`), it doesn't include `LSUIElement` by default.

### Solution

**Method 1: Configure in Xcode Info Tab (Easiest)**
1. Open Xcode project
2. Click project name → Select target → **Info** tab
3. Under "Custom macOS Application Target Properties", click **"+"** button
4. Add key: `Application is agent (UIElement)` → Set to **YES** (Boolean)
5. Also add: `CFBundleDisplayName` → Set to **"Performance Monitor"** (String)
6. Clean build folder (`Shift+⌘+K`)
7. Rebuild and run (`⌘+B`, `⌘+R`)

**Method 2: Use Info.plist File**
1. Create `Info.plist` file with `LSUIElement = YES`
2. Add file to Xcode project
3. In Build Settings, set:
   - `Generate Info.plist File` = **NO**
   - `Info.plist File` = `PerformanceMonitor/Info.plist`

### Verification
After setting `LSUIElement = YES`:
- ✅ App appears in menu bar (top right)
- ✅ No Dock icon appears
- ✅ Clicking menu bar icon shows dropdown
- ✅ Process runs in background

### Diagnostic Commands
```bash
# Check if app is running
ps aux | grep PerformanceMonitor

# Check Info.plist in built app
cat ~/Library/Developer/Xcode/DerivedData/PerformanceMonitor-*/Build/Products/Debug/PerformanceMonitor.app/Contents/Info.plist | grep LSUIElement

# Should show: <key>LSUIElement</key><true/>
```

**Key Lesson:**
- Menu bar-only apps require `LSUIElement = YES` in Info.plist
- Xcode's auto-generated Info.plist doesn't include this by default
- Configure in Xcode's Info tab or use custom Info.plist file
- Always verify the setting in the built app's Info.plist

---

## Build Target Membership

### Problem
Files exist in the project but aren't being compiled, causing "Cannot find type" errors.

### Root Cause
Files were added to the Xcode project but not included in the build target's "Compile Sources" phase.

### Solution
**Method 1: File Inspector**
1. Select file in Project Navigator
2. Open File Inspector (right sidebar, `⌘Option1`)
3. Under "Target Membership", check the target checkbox

**Method 2: Build Phases**
1. Select project name → Select target
2. Go to "Build Phases" tab
3. Expand "Compile Sources"
4. Click "+" to add missing files
5. Verify all Swift files are listed

**Key Lesson:** Adding files to Xcode project ≠ Adding files to build target. Always verify target membership.

---

## Swift 6 Concurrency & MainActor

### Problem
Experienced issues with `@MainActor` attribute on classes conforming to `ObservableObject`.

### What We Learned

**MainActor on Classes:**
- `@MainActor` on a class makes all methods and properties MainActor-isolated
- Can cause issues with `ObservableObject` conformance in Swift 6
- Better to use `@MainActor` on individual methods when needed

**Best Practice:**
```swift
// ❌ Avoid: MainActor on entire class
@MainActor
class SystemMonitor: ObservableObject { }

// ✅ Better: MainActor on specific methods
class SystemMonitor: ObservableObject {
    @MainActor
    func updateMetrics() { }
    
    @MainActor
    func formattedUptime() -> String { }
}
```

**Key Lesson:** 
- Use `@MainActor` selectively on methods, not entire classes
- Swift 6 has stricter concurrency checking
- `ObservableObject` works better without class-level `@MainActor`

---

## Project Structure & Naming

### Problem
Confusion between:
- **Bundle Name** (file system): `PerformanceMonitor` (no spaces)
- **Display Name** (shown to users): `Performance Monitor` (with space)

### Solution

**In Xcode Project Settings:**
- **Product Name:** `PerformanceMonitor` (no spaces - required for file system)
- **Info.plist:** Add `CFBundleDisplayName` = `Performance Monitor` (with space)

**Info.plist entry:**
```xml
<key>CFBundleDisplayName</key>
<string>Performance Monitor</string>
```

**Key Lesson:**
- Bundle names cannot have spaces (file system limitation)
- Use `CFBundleDisplayName` for user-facing names with spaces
- Appears in menu bar, Dock (if shown), Finder

---

## General Swift/SwiftUI Learnings

### 1. Menu Bar Apps (LSUIElement)

**Requirement:** Hide Dock icon for menu bar-only apps

**Solution:** Add to `Info.plist`:
```xml
<key>LSUIElement</key>
<true/>
```

**Or in Xcode:** Target → Info tab → Add `LSUIElement` = `YES`

### 2. MenuBarExtra (macOS 13+)

**Usage:**
```swift
MenuBarExtra("Title", systemImage: "icon.name") {
    MenuContentView()
}
.menuBarExtraStyle(.window)  // Dropdown window style
```

**Key Points:**
- Requires macOS 13.0+
- `.window` style shows a dropdown panel
- `.menu` style shows a traditional menu

### 3. @StateObject vs @ObservedObject

**@StateObject:**
- Owns the object
- Use in views that create the object
- Lifecycle tied to view

**@ObservedObject:**
- Observes an object owned elsewhere
- Use when object is passed in
- Doesn't own the object

**Example:**
```swift
// App creates it
@StateObject private var monitor = SystemMonitor()

// View receives it
@ObservedObject var monitor: SystemMonitor
```

### 4. Shell Command Execution

**Safe way to run shell commands:**
```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/uptime")
process.arguments = []
let pipe = Pipe()
process.standardOutput = pipe
try process.run()
process.waitUntilExit()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""
```

**Key Points:**
- Use explicit paths (not just `uptime`)
- Handle errors gracefully
- Parse output carefully

### 5. System Metrics Collection

**Uptime:**
```swift
ProcessInfo.processInfo.systemUptime  // Returns TimeInterval
```

**Swap Usage:**
```bash
sysctl -n vm.swapusage  # Returns: total = X.XXM  used = Y.YYM  free = Z.ZZM
```

**Memory Stats:**
```bash
vm_stat  # Returns pages free, pages active, etc.
# Page size: 16,384 bytes (16 KB) on macOS
```

**Load Averages:**
```bash
uptime  # Returns: load averages: 1.23 2.45 3.67
```

### 6. Health Status Logic

**Pattern:**
```swift
enum HealthStatus {
    case ok, warning, critical
    
    var color: Color {
        switch self {
        case .ok: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}
```

**Thresholds:**
- OK: Normal conditions
- Warning: Early signs of issues
- Critical: Action required

### 7. Build Scripts

**Useful commands:**
```bash
# Build
xcodebuild -project Project.xcodeproj -scheme SchemeName -configuration Debug build

# Clean build
xcodebuild clean build

# List schemes
xcodebuild -list -project Project.xcodeproj

# Show build settings
xcodebuild -showBuildSettings -project Project.xcodeproj -scheme SchemeName
```

### 8. Debugging Tips

**Check if files are compiled:**
```bash
xcodebuild build 2>&1 | grep "Compiling"
```

**View detailed build errors:**
```bash
xcodebuild build 2>&1 | grep -A 10 "error:"
```

**Check target membership:**
- Xcode → Project → Target → Build Phases → Compile Sources

**View app logs:**
```bash
log stream --predicate 'process == "PerformanceMonitor"'
# Or use Console.app
```

### 9. Common Pitfalls

**❌ Don't:**
- Manually edit `project.pbxproj` files
- Rely on transitive imports in Swift 6
- Forget to add files to build target
- Use spaces in bundle names

**✅ Do:**
- Create projects through Xcode
- Import frameworks explicitly
- Verify target membership
- Use `CFBundleDisplayName` for user-facing names
- Clean build folder when things go wrong (`Shift+⌘+K`)

---

## Useful Resources

- [Apple's Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

---

## Quick Reference: Fixes Applied

1. ✅ Added `import Combine` to fix ObservableObject conformance
2. ✅ Created fresh Xcode project to fix corruption
3. ✅ Added all Swift files to build target
4. ✅ Set `LSUIElement = YES` in Xcode Info tab for menu bar app visibility
5. ✅ Added `CFBundleDisplayName` for display name with space
6. ✅ Moved `@MainActor` from class to individual methods
7. ✅ Used explicit shell command paths for security
8. ✅ Configured app as menu bar-only (no Dock icon)

---

*Last updated: December 2024*
