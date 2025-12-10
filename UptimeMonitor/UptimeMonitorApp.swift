import SwiftUI

/// Main application entry point
@main
struct UptimeMonitorApp: App {
    @StateObject private var monitor = SystemMonitor()
    
    var body: some Scene {
        MenuBarExtra(monitor.formattedUptime(), systemImage: "chart.line.uptrend.xyaxis") {
            MenuContentView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}




