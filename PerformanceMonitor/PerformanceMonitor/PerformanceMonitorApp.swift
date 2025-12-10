import SwiftUI

/// Main application entry point
@main
struct PerformanceMonitorApp: App {
    @StateObject private var monitor = SystemMonitor()
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor)
        } label: {
            HStack(spacing: 4) {
                // Subtle colored health dot for quick glance
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(monitor.health.color)
                Text(monitor.formattedUptime())
            }
        }
        .menuBarExtraStyle(.window)
    }
}

