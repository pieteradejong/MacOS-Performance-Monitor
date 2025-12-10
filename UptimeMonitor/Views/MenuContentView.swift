import SwiftUI
import AppKit

/// Main content view displayed in the menu bar dropdown
struct MenuContentView: View {
    @ObservedObject var monitor: SystemMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Uptime section
            VStack(alignment: .leading, spacing: 4) {
                Text("Uptime")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(monitor.formattedUptimeDetailed())
                    .font(.system(size: 14, weight: .medium))
            }
            
            Divider()
            
            // Load averages section
            VStack(alignment: .leading, spacing: 4) {
                Text("Load Averages")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(monitor.formattedLoadAverages())
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
            }
            
            Divider()
            
            // Swap used section
            VStack(alignment: .leading, spacing: 4) {
                Text("Swap Used")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(monitor.formattedSwapUsed())
                    .font(.system(size: 14, weight: .medium))
            }
            
            Divider()
            
            // Free memory section
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Memory")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(monitor.formattedFreeMemory())
                    .font(.system(size: 14, weight: .medium))
            }
            
            Divider()
            
            // Health indicator section
            VStack(alignment: .leading, spacing: 4) {
                Text("System Health")
                    .font(.headline)
                    .foregroundColor(.secondary)
                HealthIndicatorView(status: monitor.health)
                Text(monitor.health.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // Action buttons
            VStack(spacing: 8) {
                Button(action: openActivityMonitor) {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Open Activity Monitor")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: restartSystem) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restart…")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: quitApp) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 280)
    }
    
    /// Open Activity Monitor application
    private func openActivityMonitor() {
        let activityMonitorURL = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(activityMonitorURL)
    }
    
    /// Show restart confirmation and restart the system
    private func restartSystem() {
        let alert = NSAlert()
        alert.messageText = "Restart System"
        alert.informativeText = "Are you sure you want to restart your Mac?"
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Restart the system
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
    
    /// Quit the application
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}




