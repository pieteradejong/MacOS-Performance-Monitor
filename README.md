# Performance Monitor

A lightweight macOS menu-bar app that watches system health in the background and
surfaces it as a single colored indicator plus a two-tab dropdown (**Overview** for
general users, **Dev** for developers). It samples uptime, CPU, memory/swap, disk,
Spotlight indexing activity, and per-process resource usage every 10 seconds, and
turns that into a 0–100 "Drift Score" so you can tell at a glance whether your Mac is
fine or about to get sluggish.

No external dependencies — everything is SwiftUI + shell-command parsing.

## Features

- **Menu bar indicator**: a small colored dot (green/yellow/red) plus formatted
  uptime (e.g. `3.2d`) always visible in the menu bar (`LSUIElement = YES`, no Dock
  icon).
- **Drift Score (0–100)**: a weighted composite of memory, swap, CPU, disk, and
  Spotlight-indexing sub-scores (20 points each), shown as a big number, a status
  label (Stable / Degrading / Needs Restart), and a star-rating breakdown per
  component.
- **Overview tab** (general audience): Drift Score hero, uptime + running-app count,
  memory/swap bar, CPU breakdown with top drainers, disk free space, Spotlight
  status, notification toggles, "Start at login" control, and action buttons
  (Preferences, Open Activity Monitor, Restart, Quit).
- **Dev tab** (developer audience): "Dev Hotspots" (top CPU/memory processes), free
  memory / swap summary, derived "Dev Insights" (e.g. swap > 1 GB, uptime > 5 days,
  a process pinned above 250% CPU), configurable dev alert toggles, and a footer
  showing the sampling interval.
- **Top App Drainers**: a ranked list of the heaviest processes (see below), reused
  by both tabs.
- **Spotlight activity awareness**: distinguishes idle / light / heavy indexing
  based on `mdworker`/`mds` process count and CPU usage, and reports the indexed
  item count (`mdfind -count`, cached for 60s since it's expensive).
- **Start at login**: uses `SMAppService` (macOS 13+) with status reporting
  (Enabled / Needs approval / Off) and a shortcut to System Settings → Login Items.

## How it works

`SystemMonitor` (`Models/SystemMonitor.swift`) is an `ObservableObject` that fires a
`Timer` every 10 seconds (configurable via its initializer), shells out to a handful
of macOS system commands, parses their output, and republishes a fresh
`SystemSnapshot`. All shell calls go through `Shell.runShell(_:_:)`
(`Utilities/Shell.swift`), which uses explicit absolute paths (`/usr/bin/...`) and is
backed by a swappable `ShellExecutor` protocol — `RealShellExecutor` in the app,
`MockShellExecutor` in tests.

| Metric | Source command | Parser |
|---|---|---|
| Uptime | `ProcessInfo.processInfo.systemUptime` | — |
| Load averages (1/5/15 min) | `/usr/bin/uptime` | `UptimeParser` |
| Swap used | `/usr/sbin/sysctl -n vm.swapusage` | `VMStatParser.parseSwapUsedMBFromSysctl` |
| Free memory / memory pressure | `/usr/bin/vm_stat` | `VMStatParser` |
| CPU user/system/idle % | `/usr/bin/top -l 1 -n 0` | `CPUParser.parseCPUUsage` |
| Top CPU process | `/bin/ps -eo pid,pcpu,comm` | `CPUParser.getTopProcess` |
| Disk free/used/% | `/bin/df -h /` | `DiskParser` |
| Spotlight worker count & CPU | `/bin/ps -eo pcpu,comm` (filtered for `mdworker`/`mds`) | `SpotlightParser` |
| Spotlight indexing flag | `/usr/bin/mdutil -s /` | `SpotlightParser` |
| Indexed item count (cached 60s) | `/usr/bin/mdfind -onlyin / -count *` | `SpotlightParser` |
| Active/heavy app counts & top drainers | `/bin/ps -eo pid,pcpu,pmem,comm` | `AppActivityParser` |

### Health Status (menu bar dot)

Simple two-threshold rule evaluated on every update in `SystemMonitor.updateHealthStatus()`:

- **OK** (green): uptime < 7 days **and** swap < 1 GB
- **Warning** (yellow): uptime ≥ 7 days **or** swap ≥ 1 GB
- **Critical** (red, "Restart Recommended"): uptime ≥ 14 days **or** swap ≥ 3 GB

### Drift Score (Overview tab hero number)

`DriftScore.calculate(from:)` (`Models/DriftScore.swift`) sums five independent
0–20 point components into a 0–100 score:

1. **Memory** — starts at 20, −5 for medium pressure / −15 for high pressure, −5
   more if swap > 2 GB.
2. **Swap** — 20 at 0 MB, stepping down to 0 at ≥ 3 GB used.
3. **CPU** — scored off idle %: 20 pts at ≥70% idle down to 0 pts below 20% idle.
4. **Disk** — scored off free %: 20 pts at ≥20% free down to 0 pts below 5% free.
5. **Spotlight indexing** — 20 pts if idle, otherwise decreasing with indexing
   duration (currently duration is not populated — see Known Gaps).

The total is clamped to 0–100 and mapped to a status:
**Stable** (≥80), **Degrading** (50–79), **Needs Restart** (<50). A star-rating
string (`★★★☆☆`-style, 5 stars per component) is also generated for display.

### Top App Drainers (`ProcessUsage`)

`AppActivityParser.getAppActivity(topLimit:)` (`Utilities/AppActivityParser.swift`)
runs `ps -eo pid,pcpu,pmem,comm`, filters out system processes (kernel, launchd,
mds/mdworker, WindowServer, etc.) by substring match, and wraps each remaining
process in a `ProcessUsage` (`Models/ProcessUsage.swift`):

- `drainScore = cpuPercent + (memPercent * 8.0)` — a simple heuristic that weights
  memory usage more heavily than raw CPU%, since CPU% can exceed 100 on multi-core
  systems while memory% is a much smaller, scarcer number.
- `severity`: **high** if CPU ≥150% or MEM ≥10%; **medium** if CPU ≥80% or MEM ≥5%;
  otherwise **low**. Drives a colored dot in the Overview "Top drainers" list.

The top `topLimit` processes by `drainScore` (default 6, ties broken by CPU% then
MEM%) are exposed as `SystemSnapshot.topAppDrainers` and consumed by both
`OverviewTabView`'s "Top drainers" section and `DevTabView`'s "Dev Hotspots"
section.

## Project structure

```
PerformanceMonitor/
├── PerformanceMonitor/                    # App target
│   ├── PerformanceMonitorApp.swift        # @main entry point, MenuBarExtra scene
│   ├── Info.plist                         # LSUIElement = YES (menu-bar-only app)
│   └── Assets.xcassets/
├── Models/
│   ├── SystemSnapshot.swift               # Point-in-time metrics struct + MemoryPressureLevel
│   ├── SystemMonitor.swift                # ObservableObject: timer loop, snapshot assembly, formatters
│   ├── HealthStatus.swift                 # OK/Warning/Critical enum (color, SF Symbol, label)
│   ├── DriftScore.swift                   # 0-100 composite score + DriftStatus enum
│   └── ProcessUsage.swift                 # Per-process CPU/MEM usage, drainScore, severity
├── Utilities/
│   ├── Shell.swift                        # ShellExecutor protocol, Real/Mock implementations
│   ├── UptimeParser.swift                 # Parses `uptime` load averages
│   ├── VMStatParser.swift                 # Parses `vm_stat` / `sysctl vm.swapusage`
│   ├── CPUParser.swift                    # Parses `top` CPU breakdown + `ps` top process
│   ├── DiskParser.swift                   # Parses `df -h /`
│   ├── SpotlightParser.swift              # Parses `ps`/`mdutil`/`mdfind` for indexing status
│   ├── AppActivityParser.swift            # Parses `ps` for active/heavy apps + top drainers
│   └── LaunchAtLoginManager.swift         # SMAppService wrapper (macOS 13+)
├── Views/
│   ├── MenuContentView.swift              # Segmented Overview/Dev tab picker
│   ├── OverviewTabView.swift              # Drift score, uptime, memory, CPU, disk, footer
│   ├── DevTabView.swift                   # Dev hotspots, top memory, insights, alerts, footer
│   └── HealthIndicatorView.swift          # Reusable colored-dot + label component
├── PerformanceMonitorTests/               # XCTest suite (see Testing below)
└── PerformanceMonitor.xcodeproj/

init.sh     # One-time dev environment setup (checks Xcode, xcode-select, license)
run.sh      # xcodebuild clean build + launch the .app (Debug by default, or `./run.sh Release`)
test.sh     # xcodebuild test with a phased/colorized report (--compact | --verbose)
```

## Requirements

- macOS 13.0+ (Sonoma-era `SMAppService` API for Start at Login; app declares
  macOS 13.0 as its minimum deployment target)
- Full Xcode (not just Command Line Tools) — `xcodebuild` needs it
- Swift 5.7+

## Building & running

```bash
./init.sh        # once, after cloning: verifies/configures Xcode + xcode-select
./run.sh          # xcodebuild clean build (Debug) + launch the app
./run.sh Release  # Release configuration
```

Or open `PerformanceMonitor/PerformanceMonitor.xcodeproj` in Xcode and use ⌘B / ⌘R.
The built app lands at `./build/Build/Products/<Debug|Release>/PerformanceMonitor.app`.

## Testing

```bash
./test.sh             # full phased report
./test.sh --compact   # pass/fail counts only
./test.sh --verbose   # + every individual test case
```

`test.sh` runs `xcodebuild test` and organizes results into four phases:

1. **Parser Unit Tests** — `UptimeParserTests`, `VMStatParserTests`, `DiskParserTests`
2. **Business Logic Tests** — `DriftScoreTests`, `HealthStatusTests`
3. **Complex Parser Tests** — `CPUParserTests`, `SpotlightParserTests`, `AppActivityParserTests`
4. **Integration Tests** — `SystemMonitorTests`, `MockShellExecutorTests`

Shell-dependent parsers are tested against canned command output via
`MockShellExecutor` (swapped in for `Shell.executor`), so the suite doesn't depend
on live system state.

## Known gaps / in-progress work

- `SpotlightStatus.indexingPath` and `.durationMinutes` are hardcoded to `nil` in
  `SpotlightParser` ("not reliably obtainable") but `DriftScore`'s indexing
  component and `DevInsightsView` still branch on `durationMinutes`, so that part
  of the score/insight is currently inert.
- `DevTabView`'s "Top Memory" section says "(Full process list coming soon)" —
  it shows only free memory and swap, not a real per-process memory list.
- Several buttons are stubs: `OverviewTabView`'s "Preferences…" and
  `DevTabView`'s "Open Logs…" / "Settings…" have `// TODO` bodies.
- Notification toggles (Overview) and dev alert toggles (Dev tab) are local
  `@State` only — they don't persist or actually gate any notifications yet.
- **Uncommitted at time of writing**: `ProcessUsage.swift` is untracked, and the
  "Top App Drainers" feature (`AppActivityParser.getAppActivity(topLimit:)`,
  `SystemSnapshot.topAppDrainers`, and its rendering in both tabs) is modified but
  not yet committed.
