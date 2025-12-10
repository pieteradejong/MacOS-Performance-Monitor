# UptimeMonitor - Development Roadmap

## Project Name

**UptimeMonitor**

## 1. Project Goal

Create a macOS menu-bar app that displays:

- Days since last reboot (uptime)
- Swap used (GB)
- Memory compression (pages stored in compressor)
- Disk utilization (free space, especially when critically low)
- High-level health indicator ("OK", "Warning", "Restart recommended")

### Menu Bar Display

The app should display something like "3.2d" to show uptime.

### Dropdown Menu (when opened/clicked)

A dropdown menu with:

- Uptime in days, hours
- Swap used
- Memory compression pages
- Disk utilization (free space, used space, percentage)
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

#### Disk utilization

Get disk space information:

```bash
df -h /
```

Or use `statfs` system call to get:
- Total disk space
- Free disk space
- Used disk space
- Percentage used

Parse output to show:
- Free space (GB)
- Used space (GB)
- Percentage used

**Critical thresholds:**
- Warning: < 10% free space
- Critical: < 5% free space

### Health Logic

Define a simple rule:

- `if uptimeDays < 7 and swapGB < 1 and diskFreePercent > 10`: healthy
- `if uptimeDays >= 7 or swapGB >= 1 or diskFreePercent <= 10`: warning
- `if uptimeDays >= 14 or swapGB >= 3 or diskFreePercent <= 5`: restart recommended

**Disk space thresholds:**
- Warning: ≤ 10% free space
- Critical: ≤ 5% free space

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
  │     ├── DiskParser.swift       // parses disk usage (df or statfs)
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
- `diskFreeGB: Double`
- `diskUsedGB: Double`
- `diskFreePercent: Double`
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
- Disk utilization (free space, used space, percentage)
  - Show warning/critical indicators when disk space is low
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

### G. DiskParser.swift

Parser for disk usage information:

```swift
struct DiskInfo {
    let totalGB: Double
    let freeGB: Double
    let usedGB: Double
    let freePercent: Double
}

static func parseDiskUsage() -> DiskInfo
```

Can use:
- `df -h /` command output parsing, or
- `statfs` system call (more efficient, Swift-native)

## 5. Style Guidelines

Cursor should use:

- Clean, modern Swift style
- Short functions
- Clear separation of concerns
- No unnecessary abstractions
- No external dependencies
- Everything Swift-native

## 6. Future Enhancements

### Phase 1: Core Features (Current)
- ✅ Uptime monitoring
- ✅ Swap usage tracking
- ✅ Memory compression monitoring
- ✅ Health status classification

### Phase 2: Disk Monitoring (Next Priority)
- [ ] Add disk utilization tracking
- [ ] Display free/used disk space in dropdown
- [ ] Integrate disk space into health status logic
- [ ] Show critical warnings when disk space is low (< 5%)
- [ ] Add visual indicators (progress bar or color coding) for disk usage

### Phase 3: Additional Features (Future)
- [ ] CPU usage percentage
- [ ] Network activity monitoring
- [ ] Temperature monitoring (if available)
- [ ] Historical data/trends
- [ ] Customizable thresholds
- [ ] Notifications for critical states

## 7. Next Steps

Cursor should now:

1. Generate the files and folder structure
2. Fill in all required Swift/SwiftUI code
3. Add explanations inside comments
4. Ensure the app compiles successfully
5. Confirm the menu bar looks correct
6. Explain how to run + package the app
7. **Next:** Implement disk utilization monitoring (Phase 2)

