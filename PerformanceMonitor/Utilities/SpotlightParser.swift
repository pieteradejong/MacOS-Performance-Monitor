import Foundation

/// Spotlight activity level based on worker count and CPU usage
enum SpotlightActivityLevel: String {
    case idle = "Idle"
    case light = "Light"
    case heavy = "Heavy"
    
    /// Determine activity level based on worker count and CPU usage
    static func from(workerCount: Int, cpuPercent: Double) -> SpotlightActivityLevel {
        // Heavy: 4+ workers OR 30%+ CPU
        if workerCount >= 4 || cpuPercent >= 30.0 {
            return .heavy
        }
        // Light: any workers active OR noticeable CPU
        if workerCount > 0 || cpuPercent >= 5.0 {
            return .light
        }
        return .idle
    }
}

/// Parser for Spotlight indexing status
struct SpotlightParser {
    /// Spotlight indexing information
    struct SpotlightStatus {
        let isIndexing: Bool
        let indexingPath: String?
        let durationMinutes: Int?
        
        // Enhanced metrics
        let activeWorkerCount: Int
        let totalCPUPercent: Double
        let indexedItemCount: Int?
        let activityLevel: SpotlightActivityLevel
    }
    
    /// Cache for indexed item count (expensive to compute)
    private static var cachedIndexedItemCount: Int?
    private static var lastIndexedItemCountUpdate: Date?
    private static let indexedItemCountCacheInterval: TimeInterval = 60 // 60 seconds
    
    /// Check if Spotlight is currently indexing
    /// - Returns: SpotlightStatus with indexing information
    static func getSpotlightStatus() -> SpotlightStatus {
        // Get worker count and CPU usage from ps
        let (workerCount, totalCPU) = getSpotlightProcessMetrics()
        
        // Check mdutil for indexing status
        let mdutilOutput = Shell.runShell("/usr/bin/mdutil", ["-s", "/"])
        let mdutilIndicatesIndexing = mdutilOutput.contains("Indexing")
        
        // Determine if indexing based on activity or mdutil
        let isIndexing = workerCount > 0 || totalCPU > 5.0 || mdutilIndicatesIndexing
        
        // Get activity level
        let activityLevel = SpotlightActivityLevel.from(workerCount: workerCount, cpuPercent: totalCPU)
        
        // Get indexed item count (cached)
        let indexedItemCount = getIndexedItemCount()
        
        return SpotlightStatus(
            isIndexing: isIndexing,
            indexingPath: nil, // Removed - not reliably obtainable
            durationMinutes: nil, // Removed - not reliably obtainable
            activeWorkerCount: workerCount,
            totalCPUPercent: totalCPU,
            indexedItemCount: indexedItemCount,
            activityLevel: activityLevel
        )
    }
    
    /// Get the number of active mdworker processes and their total CPU usage
    /// - Returns: Tuple of (worker count, total CPU percent)
    private static func getSpotlightProcessMetrics() -> (Int, Double) {
        let psOutput = Shell.runShell("/bin/ps", ["-eo", "pcpu,comm"])
        let lines = psOutput.components(separatedBy: .newlines)
        
        var workerCount = 0
        var totalCPU: Double = 0.0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Match mdworker processes (the actual indexing workers)
            if trimmed.contains("mdworker") {
                workerCount += 1
                // Extract CPU percentage (first column)
                let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if let cpuStr = components.first, let cpu = Double(cpuStr) {
                    totalCPU += cpu
                }
            }
            // Also include mds and mds_stores CPU in total
            else if trimmed.contains("mds_stores") || trimmed.hasSuffix("mds") {
                let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if let cpuStr = components.first, let cpu = Double(cpuStr) {
                    totalCPU += cpu
                }
            }
        }
        
        return (workerCount, totalCPU)
    }
    
    /// Get the total number of indexed items (cached for performance)
    /// - Returns: Number of indexed items, or nil if unavailable
    private static func getIndexedItemCount() -> Int? {
        // Check cache validity
        if let cached = cachedIndexedItemCount,
           let lastUpdate = lastIndexedItemCountUpdate,
           Date().timeIntervalSince(lastUpdate) < indexedItemCountCacheInterval {
            return cached
        }
        
        // Run mdfind -count (this can be slow)
        let output = Shell.runShell("/usr/bin/mdfind", ["-onlyin", "/", "-count", "*"])
        
        // Parse the count from output (last line contains the number)
        let lines = output.components(separatedBy: .newlines)
        for line in lines.reversed() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let count = Int(trimmed) {
                cachedIndexedItemCount = count
                lastIndexedItemCountUpdate = Date()
                return count
            }
        }
        
        return cachedIndexedItemCount // Return stale cache if parsing fails
    }
    
    /// Force refresh the indexed item count cache
    static func refreshIndexedItemCount() {
        lastIndexedItemCountUpdate = nil
        _ = getIndexedItemCount()
    }
}
