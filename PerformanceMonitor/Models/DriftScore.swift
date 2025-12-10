import Foundation

/// Calculates and represents the Drift Score (0-100)
/// Higher scores indicate better system health
struct DriftScore {
    let score: Int // 0-100
    let status: DriftStatus
    
    /// Calculate drift score from system snapshot
    static func calculate(from snapshot: SystemSnapshot) -> DriftScore {
        var componentScores: [Double] = []
        
        // 1. Memory component (0-20 points)
        let memoryScore = calculateMemoryScore(
            pressure: snapshot.memoryPressureLevel,
            swapUsedMB: snapshot.swapUsedMB
        )
        componentScores.append(memoryScore)
        
        // 2. Swap component (0-20 points)
        let swapScore = calculateSwapScore(swapUsedMB: snapshot.swapUsedMB)
        componentScores.append(swapScore)
        
        // 3. CPU component (0-20 points)
        let cpuScore = calculateCPUScore(
            userPercent: snapshot.cpuUserPercent,
            systemPercent: snapshot.cpuSystemPercent,
            idlePercent: snapshot.cpuIdlePercent
        )
        componentScores.append(cpuScore)
        
        // 4. Disk component (0-20 points)
        let diskScore = calculateDiskScore(freePercent: snapshot.diskFreePercent)
        componentScores.append(diskScore)
        
        // 5. Indexing component (0-20 points)
        let indexingScore = calculateIndexingScore(
            isIndexing: snapshot.isSpotlightIndexing,
            durationMinutes: snapshot.spotlightIndexingDurationMinutes
        )
        componentScores.append(indexingScore)
        
        // Total score is sum of components (0-100)
        let totalScore = Int(componentScores.reduce(0, +).rounded())
        let clampedScore = max(0, min(100, totalScore))
        
        // Determine status based on score
        let status: DriftStatus
        if clampedScore >= 80 {
            status = .stable
        } else if clampedScore >= 50 {
            status = .degrading
        } else {
            status = .needsRestart
        }
        
        return DriftScore(score: clampedScore, status: status)
    }
    
    // MARK: - Component Score Calculations
    
    /// Calculate memory score (0-20 points)
    private static func calculateMemoryScore(pressure: MemoryPressureLevel, swapUsedMB: Int) -> Double {
        var score = 20.0
        
        // Deduct based on memory pressure
        switch pressure {
        case .low:
            score -= 0
        case .medium:
            score -= 5
        case .high:
            score -= 15
        }
        
        // Additional deduction if swap is being used heavily
        if swapUsedMB > 2048 { // > 2GB
            score -= 5
        }
        
        return max(0, score)
    }
    
    /// Calculate swap score (0-20 points)
    private static func calculateSwapScore(swapUsedMB: Int) -> Double {
        if swapUsedMB == 0 {
            return 20.0
        } else if swapUsedMB < 512 {
            return 18.0
        } else if swapUsedMB < 1024 {
            return 15.0
        } else if swapUsedMB < 2048 {
            return 10.0
        } else if swapUsedMB < 3072 {
            return 5.0
        } else {
            return 0.0
        }
    }
    
    /// Calculate CPU score (0-20 points)
    private static func calculateCPUScore(userPercent: Double, systemPercent: Double, idlePercent: Double) -> Double {
        // High idle is good
        if idlePercent >= 70 {
            return 20.0
        } else if idlePercent >= 50 {
            return 15.0
        } else if idlePercent >= 30 {
            return 10.0
        } else if idlePercent >= 20 {
            return 5.0
        } else {
            return 0.0
        }
    }
    
    /// Calculate disk score (0-20 points)
    private static func calculateDiskScore(freePercent: Double) -> Double {
        if freePercent >= 20 {
            return 20.0
        } else if freePercent >= 15 {
            return 18.0
        } else if freePercent >= 10 {
            return 12.0
        } else if freePercent >= 5 {
            return 5.0
        } else {
            return 0.0
        }
    }
    
    /// Calculate indexing score (0-20 points)
    private static func calculateIndexingScore(isIndexing: Bool, durationMinutes: Int?) -> Double {
        if !isIndexing {
            return 20.0
        }
        
        // If indexing, deduct based on duration
        let duration = durationMinutes ?? 0
        if duration < 10 {
            return 18.0
        } else if duration < 30 {
            return 12.0
        } else if duration < 60 {
            return 8.0
        } else {
            return 4.0
        }
    }
    
    /// Get star rating breakdown for display (5 stars max per component)
    static func getStarBreakdown(from snapshot: SystemSnapshot) -> String {
        let memoryStars = getStars(for: calculateMemoryScore(pressure: snapshot.memoryPressureLevel, swapUsedMB: snapshot.swapUsedMB), max: 20)
        let swapStars = getStars(for: calculateSwapScore(swapUsedMB: snapshot.swapUsedMB), max: 20)
        let cpuStars = getStars(for: calculateCPUScore(userPercent: snapshot.cpuUserPercent, systemPercent: snapshot.cpuSystemPercent, idlePercent: snapshot.cpuIdlePercent), max: 20)
        let diskStars = getStars(for: calculateDiskScore(freePercent: snapshot.diskFreePercent), max: 20)
        let indexingStars = getStars(for: calculateIndexingScore(isIndexing: snapshot.isSpotlightIndexing, durationMinutes: snapshot.spotlightIndexingDurationMinutes), max: 20)
        
        return "Memory \(memoryStars) · Swap \(swapStars) · CPU \(cpuStars) · Disk \(diskStars) · Indexing \(indexingStars)"
    }
    
    private static func getStars(for score: Double, max: Double) -> String {
        let percentage = score / max
        let fullStars = Int(percentage * 5)
        let hasHalfStar = (percentage * 5) - Double(fullStars) >= 0.5
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        
        var result = String(repeating: "★", count: fullStars)
        if hasHalfStar {
            result += "☆"
        }
        result += String(repeating: "☆", count: emptyStars)
        return result
    }
}

/// Drift status levels
enum DriftStatus {
    case stable
    case degrading
    case needsRestart
    
    var label: String {
        switch self {
        case .stable: return "Stable"
        case .degrading: return "Degrading"
        case .needsRestart: return "Needs Restart"
        }
    }
    
    var explanation: String {
        switch self {
        case .stable: return "System is healthy."
        case .degrading: return "System is under load; monitor and consider restart."
        case .needsRestart: return "Restart recommended to restore responsiveness."
        }
    }
}
