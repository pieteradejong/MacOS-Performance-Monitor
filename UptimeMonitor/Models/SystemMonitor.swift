import Foundation
import SwiftUI

/// Observable object that monitors system health metrics
/// Holds the latest snapshot and computed HealthStatus
@MainActor
class SystemMonitor: ObservableObject {
    /// Latest system snapshot
    @Published var snapshot: SystemSnapshot?
    
    /// Computed health status based on snapshot data
    @Published var health: HealthStatus = .ok
    
    /// Timer refresh interval in seconds (default: 10s as per dev_notes)
    private let updateInterval: TimeInterval
    
    private var updateTimer: Timer?
    
    init(updateInterval: TimeInterval = 10.0) {
        self.updateInterval = updateInterval
        updateMetrics()
        startTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    /// Start the timer to update metrics every N seconds
    private func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    /// Stop the update timer
    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Update all system metrics and create a new snapshot
    func updateMetrics() {
        // Get uptime in seconds
        let uptimeSeconds = ProcessInfo.processInfo.systemUptime
        
        // Parse load averages from uptime command
        let uptimeOutput = Shell.runShell("/usr/bin/uptime")
        let (load1, load5, load15) = UptimeParser.parseLoadAverages(uptimeOutput)
        
        // Parse swap usage from sysctl
        let swapUsedMB = VMStatParser.parseSwapUsedMBFromSysctl()
        
        // Parse free memory from vm_stat
        let vmStatOutput = Shell.runShell("/usr/bin/vm_stat")
        let freeMemoryMB = VMStatParser.parseFreeMemoryMB(vmStatOutput)
        
        // Create new snapshot
        snapshot = SystemSnapshot(
            timestamp: Date(),
            uptimeSeconds: uptimeSeconds,
            load1: load1,
            load5: load5,
            load15: load15,
            swapUsedMB: swapUsedMB,
            freeMemoryMB: freeMemoryMB
        )
        
        // Update health status based on rules
        updateHealthStatus()
    }
    
    /// Update health status based on snapshot data
    /// Applies severity rules: ok, warning, critical
    private func updateHealthStatus() {
        guard let snapshot = snapshot else {
            health = .ok
            return
        }
        
        let uptimeDays = snapshot.uptimeSeconds / 86400.0
        let swapUsedGB = Double(snapshot.swapUsedMB) / 1024.0
        
        // Health logic:
        // - ok: uptimeDays < 7 and swapGB < 1
        // - warning: uptimeDays >= 7 or swapGB >= 1
        // - critical: uptimeDays >= 14 or swapGB >= 3
        if uptimeDays >= 14 || swapUsedGB >= 3 {
            health = .critical
        } else if uptimeDays >= 7 || swapUsedGB >= 1 {
            health = .warning
        } else {
            health = .ok
        }
    }
    
    // MARK: - Formatted Values for UI
    
    /// Format uptime for display in menu bar (e.g., "3.2d")
    func formattedUptime() -> String {
        guard let snapshot = snapshot else { return "0.0d" }
        let days = snapshot.uptimeSeconds / 86400.0
        return String(format: "%.1fd", days)
    }
    
    /// Format uptime with days and hours for detailed display
    func formattedUptimeDetailed() -> String {
        guard let snapshot = snapshot else { return "0d 0h" }
        let days = Int(snapshot.uptimeSeconds / 86400.0)
        let hours = Int((snapshot.uptimeSeconds.truncatingRemainder(dividingBy: 86400.0)) / 3600.0)
        return "\(days)d \(hours)h"
    }
    
    /// Format swap used for display
    func formattedSwapUsed() -> String {
        guard let snapshot = snapshot else { return "0 MB" }
        if snapshot.swapUsedMB >= 1024 {
            return String(format: "%.2f GB", Double(snapshot.swapUsedMB) / 1024.0)
        } else {
            return "\(snapshot.swapUsedMB) MB"
        }
    }
    
    /// Format free memory for display
    func formattedFreeMemory() -> String {
        guard let snapshot = snapshot else { return "0 MB" }
        if snapshot.freeMemoryMB >= 1024 {
            return String(format: "%.2f GB", Double(snapshot.freeMemoryMB) / 1024.0)
        } else {
            return "\(snapshot.freeMemoryMB) MB"
        }
    }
    
    /// Format load averages for display
    func formattedLoadAverages() -> String {
        guard let snapshot = snapshot else { return "0.00 0.00 0.00" }
        return String(format: "%.2f %.2f %.2f", snapshot.load1, snapshot.load5, snapshot.load15)
    }
}
