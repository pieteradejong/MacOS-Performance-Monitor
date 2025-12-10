import Foundation

/// Represents a snapshot of system metrics at a point in time
struct SystemSnapshot {
    let timestamp: Date
    let uptimeSeconds: TimeInterval
    let load1: Double
    let load5: Double
    let load15: Double
    let swapUsedMB: Int
    let freeMemoryMB: Int
}
