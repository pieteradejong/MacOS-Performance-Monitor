import SwiftUI
import AppKit

/// Overview tab view - user-friendly system health overview
struct OverviewTabView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Drift Score header (hero)
                DriftScoreHeaderView(monitor: monitor)
                
                Divider()
                
                // 2. Uptime & app activity
                UptimeAppActivityView(monitor: monitor)
                
                Divider()
                
                // 3. Memory & swap section
                MemorySwapView(monitor: monitor)
                
                Divider()
                
                // 4. CPU section
                CPUView(monitor: monitor)
                
                Divider()
                
                // 5. Disk & Spotlight section
                DiskSpotlightView(monitor: monitor)
                
                Divider()
                
                // 6. Notifications & actions footer
                NotificationsActionsFooterView()
            }
            .padding()
        }
        .frame(width: 320, height: 500)
    }
}

/// Drift Score header view
struct DriftScoreHeaderView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let driftScore = monitor.driftScore {
                HStack(alignment: .top, spacing: 12) {
                    // Large numeric score
                    Text("\(driftScore.score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(colorForStatus(driftScore.status))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(driftScore.status.label)
                            .font(.headline)
                            .foregroundColor(colorForStatus(driftScore.status))
                        Text(driftScore.status.explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Score breakdown
                if let snapshot = monitor.snapshot {
                    Text(DriftScore.getStarBreakdown(from: snapshot))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Simple guidance for general users
                Text("Use this as a quick health meter: green is fine, yellow means keep an eye on things, red means consider restarting soon.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Calculating...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func colorForStatus(_ status: DriftStatus) -> Color {
        switch status {
        case .stable: return .green
        case .degrading: return .orange
        case .needsRestart: return .red
        }
    }
}

/// Uptime & app activity view
struct UptimeAppActivityView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uptime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(monitor.formattedUptimeDetailed())
                        .font(.system(size: 14, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apps running")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(monitor.formattedAppActivity())
                        .font(.system(size: 14, weight: .medium))
                }
            }
            
            Text("Long sessions and many open apps can slowly make a Mac feel less responsive over time.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Memory & swap view
struct MemorySwapView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory & Swap")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let snapshot = monitor.snapshot {
                // Memory pressure bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(Int(snapshot.memoryPressureLevel == .low ? 30 : snapshot.memoryPressureLevel == .medium ? 60 : 90))%")
                            .font(.system(size: 12, weight: .medium))
                        Text("· \(monitor.formattedMemoryPressure())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                            Rectangle()
                                .fill(colorForPressure(snapshot.memoryPressureLevel))
                                .frame(width: geometry.size.width * (snapshot.memoryPressureLevel == .low ? 0.3 : snapshot.memoryPressureLevel == .medium ? 0.6 : 0.9))
                        }
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                }
                
                // Swap usage row
                HStack {
                    Text("Swap used:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(monitor.formattedSwapUsed())
                        .font(.system(size: 12, weight: .medium))
                    Text("—")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("High memory pressure and growing swap often indicate leaking or heavy apps.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func colorForPressure(_ level: MemoryPressureLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

/// CPU view
struct CPUView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CPU")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let snapshot = monitor.snapshot {
                Text(monitor.formattedCPUBreakdown())
                    .font(.system(size: 12))
                
                if let topProcess = snapshot.topProcessName, snapshot.topProcessCPUPercent > 0 {
                    HStack {
                        Text(topProcess)
                            .font(.system(size: 12, weight: .medium))
                        Text(String(format: "%.0f%%", snapshot.topProcessCPUPercent))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("If your Mac feels hot or fans are loud, this section shows whether the CPU is the cause and which app is most active.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Disk & Spotlight view
struct DiskSpotlightView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Disk & Indexing")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let snapshot = monitor.snapshot {
                // Disk free
                Text(monitor.formattedDiskFree())
                    .font(.system(size: 12))
                    .foregroundColor(snapshot.diskFreePercent < 10 ? .red : .primary)
                
                // Spotlight indexing
                HStack {
                    if snapshot.isSpotlightIndexing {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(monitor.formattedSpotlightStatus())
                        .font(.system(size: 12))
                }
                
                Text("Long-running indexing and low disk space can cause temporary slowdowns.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Notifications & actions footer view
struct NotificationsActionsFooterView: View {
    @State private var performanceWarnings = true
    @State private var diskSpaceWarnings = true
    @State private var uptimeReminders = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Notification toggles
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Performance warnings (memory, swap, CPU)", isOn: $performanceWarnings)
                    .font(.caption)
                Toggle("Disk space warnings", isOn: $diskSpaceWarnings)
                    .font(.caption)
                Toggle("Uptime reminders", isOn: $uptimeReminders)
                    .font(.caption)
            }
            
            Divider()
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Preferences…") {
                    // TODO: Open preferences window
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Open Activity Monitor") {
                    openActivityMonitor()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Restart…") {
                    restartSystem()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Quit") {
                    quitApp()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Last updated footer
            HStack {
                Spacer()
                Text("Last updated: \(formattedLastUpdated())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func openActivityMonitor() {
        let activityMonitorURL = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(activityMonitorURL)
    }
    
    private func restartSystem() {
        let alert = NSAlert()
        alert.messageText = "Restart System"
        alert.informativeText = "Are you sure you want to restart your Mac?"
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.launchPath = "/sbin/shutdown"
            task.arguments = ["-r", "now"]
            do {
                try task.run()
            } catch {
                print("Failed to restart: \(error)")
            }
        }
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func formattedLastUpdated() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
