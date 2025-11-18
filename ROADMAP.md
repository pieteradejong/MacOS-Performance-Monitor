# UptimeMonitor - Development Roadmap

## Project Name

**UptimeMonitor**

## 1. Project Goal

Create a macOS menu-bar app that displays:

- Days since last reboot (uptime)
- Swap used (GB)
- Memory compression (pages stored in compressor)
- High-level health indicator ("OK", "Warning", "Restart recommended")

### Menu Bar Display

The app should display something like "3.2d" to show uptime.

### Dropdown Menu (when opened/clicked)

A dropdown menu with:

- Uptime in days, hours
- Swap used
- Memory compression pages
- A color-coded health indicator
- Buttons:
  - "Open Activity Monitor"
  - "Restart…"
  - "Quit"

This should be a SwiftUI + Swift macOS app using MenuBarExtra (macOS 13+) with no Dock icon.

## 2. Tech Requirements

### Menu Bar App Requirements

- Use SwiftUI App Lifecycle
- Use MenuBarExtra (macOS 13 or later)
- Must hide Dock icon and main window by setting `LSUIElement = YES`

### System Info Requirements

Implement functions that retrieve:

#### Uptime

```swift
let seconds = ProcessInfo.processInfo.systemUptime
```

#### Swap used (GB)

Run `vm_stat` and parse output of:
- Swapins
- Swapouts

Or more directly:

```bash
sysctl vm.swapusage
```

Example command you can wrap:

```bash
sysctl -n vm.swapusage
```

#### Pages stored in compressor

From `vm_stat` output:

```
Pages stored in compressor: <number>
```

Parse that to an integer.

### Health Logic

Define a simple rule:

- `if uptimeDays < 7 and swapGB < 1`: healthy
- `if uptimeDays >= 7 or swapGB >= 1`: warning
- `if uptimeDays >= 14 or swapGB >= 3`: restart recommended

Return an enum:

```swift
enum HealthStatus { 
    case healthy, warning, critical 
}
```

Each should map to:
- color (green / yellow / red)
- short label
- explanation

## 3. Project File Structure

Have Cursor generate the following clean structure:

```
UptimeMonitor/
  ├── UptimeMonitorApp.swift       // entry point, MenuBarExtra
  ├── Info.plist                   // LSUIElement = YES
  ├── Models/
  │     ├── SystemMonitor.swift    // uptime, swap, compression, refresh timer
  │     └── HealthStatus.swift
  ├── Views/
  │     ├── MenuContentView.swift  // menu UI
  │     └── HealthIndicatorView.swift
  ├── Utilities/
  │     ├── VMStatParser.swift     // parses vm_stat output
  │     └── Shell.swift            // run shell commands safely
```

## 4. Implementation Instructions

### A. UptimeMonitorApp.swift

- Create a shared `SystemMonitor` as a `@StateObject`
- Menu bar title should display uptime like "3.2d"
- The menu shows `MenuContentView()`

### B. SystemMonitor.swift

A class `SystemMonitor: ObservableObject`

Published fields:
- `uptimeDays: Double`
- `swapUsedGB: Double`
- `compressionPages: Int`
- `health: HealthStatus`

A timer that updates every 60 seconds

Use Shell utilities to read `vm_stat` and `sysctl` output

Parse compression pages from `vm_stat`

### C. HealthStatus.swift

Enum with `.healthy`, `.warning`, `.critical`

Computed properties:
- `color: Color`
- `label: String`
- `explanation: String`

### D. MenuContentView.swift

UI shows:
- Uptime
- Swap used
- Compression pages
- Health indicator view

Buttons for:
- Open Activity Monitor
- Restart
- Quit

### E. HealthIndicatorView.swift

Colored dot + label.

### F. Shell utilities

Safe wrapper:

```swift
func runShell(_ command: String, _ args: [String]) -> String
```

And parser for `vm_stat` output.

## 5. Style Guidelines

Cursor should use:

- Clean, modern Swift style
- Short functions
- Clear separation of concerns
- No unnecessary abstractions
- No external dependencies
- Everything Swift-native

## 6. Next Steps

Cursor should now:

1. Generate the files and folder structure
2. Fill in all required Swift/SwiftUI code
3. Add explanations inside comments
4. Ensure the app compiles successfully
5. Confirm the menu bar looks correct
6. Explain how to run + package the app

