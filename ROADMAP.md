# PerformanceMonitor - Development Roadmap

## Project Name

**PerformanceMonitor**

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
PerformanceMonitor/
  ├── PerformanceMonitorApp.swift  // entry point, MenuBarExtra
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

### A. PerformanceMonitorApp.swift

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

## 6. UI / UX

The app uses a tabbed popover interface with two main views: **Overview** (default) and **Dev** (developer-focused). Both tabs are accessible via a segmented control at the top of the popover.

### Overview Tab

The Overview tab is the default view when the user clicks the menu bar icon. It provides a comprehensive, user-friendly view of system health.

**General layout**

- The Overview tab is the default view when the user clicks the menu bar icon.
- It uses a vertical stacked layout with clearly separated sections (using subtle separators or cards).
- The popover is sized to fit comfortably on a 13–16" Mac display without scrolling in common cases. Assume a rough layout of:

  1. Drift Score header
  2. Uptime & app activity
  3. Memory & swap
  4. CPU
  5. Disk & Spotlight
  6. Notifications / actions footer

- At the very top of the popover there is a tab/segmented control:
  - `Overview | Dev`
  - "Overview" is selected by default.

**1. Drift Score header (hero)**

- Large numeric Drift Score (0–100) in the center-left, with a label on the right:
  - Status text: "Stable", "Degrading", or "Needs Restart".
  - One-line explanation below, e.g.:
    - Stable: "System is healthy."
    - Degrading: "System is under load; monitor and consider restart."
    - Needs Restart: "Restart recommended to restore responsiveness."
- Background accent or text color reflects state:
  - Stable: green
  - Degrading: yellow/orange
  - Needs Restart: red
- Beneath the status, a small "score breakdown" line, e.g.:
  - "Memory ★★★★☆ · Swap ★★★☆☆ · CPU ★★☆☆☆ · Disk ★☆☆☆☆ · Indexing ★★☆☆☆"
- This section should be visually the most prominent.

**2. Uptime & app activity**

- A compact row under the header:

  - **Uptime**:
    - Label: "Uptime"
    - Value: formatted like `3d 4h` or `0d 12h`.
  - **Active apps**:
    - Label: "Apps running"
    - Value: e.g. `18 (4 heavy)` where "heavy" means apps currently contributing significantly to CPU or memory.
  - Optionally show a tiny 7-day "uptime trend" sparkline later, but note it is non-critical.

- The goal here is to answer: "How long has this session been running?" and "How busy is it in terms of running apps?"

**3. Memory & swap section**

- Label: "Memory & Swap".
- Show:
  - **Memory pressure bar**:
    - Visual bar with percentage text, e.g. `68% · Medium`.
    - Color based on level: low (green), medium (yellow), high (red).
  - **Swap usage row**:
    - "Swap used": human-readable (e.g. `512 MB`).
    - "Trend": small arrow or text like `↑ 64 MB last 10 min` if growing quickly, or `—` if stable.
- Below rows, include a one-line helper text:
  - Example: "High memory pressure and growing swap often indicate leaking or heavy apps."
- This section should clearly show whether drift is memory-related.

**4. CPU section**

- Label: "CPU".
- Show:
  - **User/System/Idle breakdown**:
    - Example line: `User 32% · System 8% · Idle 60%`.
  - **Top CPU process**:
    - One row showing:
      - process name, e.g. "node"
      - CPU percentage, e.g. "145%"
      - Short label, e.g. "dev server" if recognized as a likely dev process.
- If CPU is in a normal range, the section communicates "CPU is fine."
- If CPU is high, this section makes it obvious which app is a likely culprit, without needing Activity Monitor.

**5. Disk & Spotlight section**

- Label: "Disk & Indexing".
- Show:
  - **Disk free**:
    - Text: e.g. "22 GB free (11%) on system volume".
    - If below 10–15%, emphasize with warning color.
  - **Spotlight indexing**:
    - If not indexing:
      - "Spotlight: Idle".
    - If indexing:
      - "Spotlight: Indexing /Users/… for 12 min".
      - Use a spinner or subtle animated indicator when indexing is active.
- Include a one-line helper:
  - "Long-running indexing and low disk space can cause temporary slowdowns."

**6. Notifications & actions footer**

- At the bottom, place a compact area with:
  - Toggle switches for key notification categories (labels only, actual thresholds defined in code/JSON):
    - "[✓] Performance warnings (memory, swap, CPU)"
    - "[✓] Disk space warnings"
    - "[✓] Uptime reminders"
  - A row of buttons:
    - "Preferences…" → opens full settings window.
    - "Open Activity Monitor" → opens macOS Activity Monitor.
    - "Restart…" → optional shortcut that calls the standard restart dialog.
    - "Quit" → quits the app.
- Also show a very small "Last updated: <timestamp>" line at the very bottom, right-aligned.

### Dev Tab

The Dev tab is a power-user / developer-focused view intended for users running IDEs, language servers, Docker, node/python processes, etc.

**General layout**

- Same popover, but tab selector has "Dev" active: `Overview | Dev`.
- Intended for users running IDEs, language servers, Docker, node/python processes, etc.
- Focus on **process-level information** and **Dev-specific alerts**.

**1. Dev Hotspots (top section)**

- Section title: "Dev Hotspots".
- A small explanatory subtitle: "Top processes impacting performance right now."
- Table-style list (top 3–5 items) with columns:
  - Process name (e.g. `node`, `Google Chrome`, `Docker Desktop`).
  - CPU % (e.g. `145%`).
  - Memory usage (e.g. `2.6 GB`).
  - Optional label:
    - "Dev tool" if name matches known dev processes (node, python, xcodebuild, clang, docker, kubectl, java, gradle, etc.).
- Each row can have a small icon or badge to indicate:
  - dev-related
  - background
  - foreground app

**2. Top memory consumers**

- Section title: "Top Memory".
- Short list (3–5 items) sorted by memory usage.
- Fields for each row:
  - Process name
  - Memory used
  - Optional note if also in the "Dev process" known list.
- The purpose is to spot Chrome, Xcode, Docker, etc. consuming multiple GB.

**3. Dev Insights (derived signals)**

- Section title: "Dev Insights".
- Show a concise bullet list (static, not interactive) summarizing the current dev-related state, for example:

  - "Spotlight indexing your project folder: /Users/pieter/projects/foo"
  - "Swap started 15 min ago while dev tools were running."
  - "Uptime > 5d — language servers may be degraded."
  - "node (pid 12345) using > 250% CPU for 3 min."

- These insights are derived from metrics + rules, not raw data.
- The idea is: a developer reads this list and instantly understands "what's weird right now."

**4. Dev alerts configuration**

- Section title: "Dev Alerts".
- List of toggle switches for Dev-only notifications such as:

  - "[✓] Runaway dev process (single dev process > 250% CPU for 2+ min)"
  - "[✓] Swap > 1 GB while dev tools running"
  - "[✓] Long-running Spotlight indexing in project folders (> 20 min)"

- These map directly to rules in the notification engine but are presented in human language.
- Optionally show the current status beneath each toggle (e.g. "Inactive recently", "Triggered 1 time today").

**5. Debug / tools footer**

- At the bottom of Dev tab, include one or two buttons:

  - "Open Logs…" → opens a simple log view or text file where internal metrics/alerts are appended.
  - "Settings…" → jumps to a Dev-specific area in the app's Preferences.

- Optionally display a tiny line of meta-info, e.g.:
  - "Sampling every 10s · Data retention: 2h."

### Style & Accessibility Notes

- Use a clean, system-aligned style (SF Pro font, standard macOS controls).
- Prefer text clarity over dense charts.
- Use color primarily to encode state (green/yellow/red) but ensure icons/labels also communicate meaning for colorblind users.
- Keep sections visually differentiated using spacing and subtle separators, not heavy borders.
- Avoid overcrowding: prioritize Drift Score, current problems, and obvious next actions.

## 7. Future Enhancements

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
- [ ] Prominent \"What you can do now\" action panel in the Overview tab that suggests concrete next steps (e.g. close heavy apps, free disk space, restart) based on current bottlenecks.

## 8. Next Steps

Cursor should now:

1. Generate the files and folder structure
2. Fill in all required Swift/SwiftUI code
3. Add explanations inside comments
4. Ensure the app compiles successfully
5. Confirm the menu bar looks correct
6. Explain how to run + package the app
7. **Next:** Implement disk utilization monitoring (Phase 2)


