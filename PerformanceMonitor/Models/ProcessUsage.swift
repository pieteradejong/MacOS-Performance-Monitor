import Foundation

/// A lightweight snapshot of a process' resource usage.
struct ProcessUsage: Identifiable, Hashable {
    let pid: Int
    let name: String
    let cpuPercent: Double
    let memPercent: Double
    
    var id: Int { pid }
    
    /// A simple ranking metric for "what's draining performance right now".
    ///
    /// Notes:
    /// - `%CPU` can exceed 100 on multi-core systems.
    /// - `%MEM` is typically small but indicates pressure risk, so it’s weighted.
    var drainScore: Double {
        cpuPercent + (memPercent * 8.0)
    }
    
    var severity: DrainSeverity {
        if cpuPercent >= 150.0 || memPercent >= 10.0 { return .high }
        if cpuPercent >= 80.0 || memPercent >= 5.0 { return .medium }
        return .low
    }
}

enum DrainSeverity: String {
    case low
    case medium
    case high
}

