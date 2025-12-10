import SwiftUI

/// Dev tab view - developer-focused process monitoring
struct DevTabView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Dev Hotspots
                DevHotspotsView(monitor: monitor)
                
                Divider()
                
                // 2. Top memory consumers
                TopMemoryView(monitor: monitor)
                
                Divider()
                
                // 3. Dev Insights
                DevInsightsView(monitor: monitor)
                
                Divider()
                
                // 4. Dev alerts configuration
                DevAlertsView()
                
                Divider()
                
                // 5. Debug / tools footer
                DevToolsFooterView()
            }
            .padding()
        }
        .frame(width: 320, height: 500)
    }
}

/// Dev Hotspots view - top processes impacting performance
struct DevHotspotsView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dev Hotspots")
                .font(.headline)
            Text("Top processes impacting performance right now.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let snapshot = monitor.snapshot, snapshot.topProcessCPUPercent > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(snapshot.topProcessName ?? "Unknown")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text(String(format: "%.0f%%", snapshot.topProcessCPUPercent))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("CPU")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    // TODO: Add memory usage and dev tool badge when process list is implemented
                }
            } else {
                Text("No high-CPU processes detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Top memory consumers view
struct TopMemoryView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Memory")
                .font(.headline)
            
            if let snapshot = monitor.snapshot {
                Text("Free: \(monitor.formattedFreeMemory())")
                    .font(.system(size: 12))
                Text("Used: \(monitor.formattedSwapUsed()) swap")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("(Full process list coming soon)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

/// Dev Insights view - derived signals
struct DevInsightsView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dev Insights")
                .font(.headline)
            
            if let snapshot = monitor.snapshot {
                VStack(alignment: .leading, spacing: 4) {
                    if snapshot.isSpotlightIndexing, let path = snapshot.spotlightIndexingPath {
                        Text("• Spotlight indexing your project folder: \(path)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if snapshot.swapUsedMB > 1024 {
                        Text("• Swap > 1 GB — dev tools may be causing memory pressure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    let uptimeDays = snapshot.uptimeSeconds / 86400.0
                    if uptimeDays > 5 {
                        Text("• Uptime > \(Int(uptimeDays))d — language servers may be degraded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if snapshot.topProcessCPUPercent > 250 {
                        Text("• \(snapshot.topProcessName ?? "Process") using > 250% CPU")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No insights available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Dev Alerts configuration view
struct DevAlertsView: View {
    @State private var runawayDevProcess = true
    @State private var swapWithDevTools = true
    @State private var longIndexing = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dev Alerts")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Runaway dev process (> 250% CPU for 2+ min)", isOn: $runawayDevProcess)
                    .font(.caption)
                Toggle("Swap > 1 GB while dev tools running", isOn: $swapWithDevTools)
                    .font(.caption)
                Toggle("Long-running Spotlight indexing in project folders (> 20 min)", isOn: $longIndexing)
                    .font(.caption)
            }
        }
    }
}

/// Dev Tools footer view
struct DevToolsFooterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button("Open Logs…") {
                    // TODO: Open logs view
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Settings…") {
                    // TODO: Open dev-specific settings
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text("Sampling every 10s · Data retention: 2h")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
