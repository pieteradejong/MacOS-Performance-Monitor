You are my coding pair, helping me build a small macOS menu bar app in Swift and SwiftUI, to monitor system health and gently tell me when it’s time to reboot or kill memory hogs.

### Platform & Constraints

- Target: macOS 13+ (Ventura or later).
- Language: Swift.
- UI: SwiftUI, using `MenuBarExtra`.
- No external dependencies or package managers.
- Minimal, readable code. Prefer clarity over cleverness.
- This app will be edited in Cursor and built with Xcode.

### Core Functionality

I want a persistent menu bar item that:

1. **Collects system metrics every N seconds** (start with 10s):
   - System uptime (seconds since boot).
   - Load averages: 1, 5, and 15 minute.
   - Swap used (MB or GB).
   - Free memory (MB).

2. **How to get these metrics (initial version)**:
   - Call `/usr/bin/uptime` and parse out `load averages: 1 5 15`.
   - Call `/usr/sbin/sysctl vm.swapusage` and parse `used = ...`.
   - Call `/usr/bin/vm_stat` and parse `Pages free:` (page size 16,384 bytes) to get free memory in MB.
   - It’s fine to use `Process` + `Pipe` and simple string parsing.

3. **Represent the metrics** in a type:
   ```swift
   struct SystemSnapshot {
       let timestamp: Date
       let uptimeSeconds: TimeInterval
       let load1: Double
       let load5: Double
       let load15: Double
       let swapUsedMB: Int
       let freeMemoryMB: Int
   }
