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
    
    // CPU metrics
    let cpuUserPercent: Double
    let cpuSystemPercent: Double
    let cpuIdlePercent: Double
    let topProcessName: String?
    let topProcessCPUPercent: Double
    
    // Memory pressure
    let memoryPressureLevel: MemoryPressureLevel
    
    // Disk metrics
    let diskFreeGB: Double
    let diskUsedGB: Double
    let diskFreePercent: Double
    
    // Spotlight indexing
    let isSpotlightIndexing: Bool
    let spotlightIndexingPath: String?
    let spotlightIndexingDurationMinutes: Int?
    
    // App activity
    let activeAppsCount: Int
    let heavyAppsCount: Int
}

/// Memory pressure levels
enum MemoryPressureLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}
