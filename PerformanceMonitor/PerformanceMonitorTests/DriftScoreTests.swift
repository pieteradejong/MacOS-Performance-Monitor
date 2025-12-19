import XCTest
@testable import PerformanceMonitor

final class DriftScoreTests: XCTestCase {
    
    // MARK: - Helper to create SystemSnapshot
    
    private func makeSnapshot(
        memoryPressure: MemoryPressureLevel = .low,
        swapUsedMB: Int = 0,
        cpuUserPercent: Double = 10.0,
        cpuSystemPercent: Double = 5.0,
        cpuIdlePercent: Double = 85.0,
        diskFreePercent: Double = 50.0,
        isSpotlightIndexing: Bool = false,
        spotlightDurationMinutes: Int? = nil
    ) -> SystemSnapshot {
        return SystemSnapshot(
            timestamp: Date(),
            uptimeSeconds: 86400, // 1 day
            load1: 1.0,
            load5: 1.0,
            load15: 1.0,
            swapUsedMB: swapUsedMB,
            freeMemoryMB: 4096,
            cpuUserPercent: cpuUserPercent,
            cpuSystemPercent: cpuSystemPercent,
            cpuIdlePercent: cpuIdlePercent,
            topProcessName: "Safari",
            topProcessCPUPercent: 5.0,
            memoryPressureLevel: memoryPressure,
            diskFreeGB: 100.0,
            diskUsedGB: 400.0,
            diskFreePercent: diskFreePercent,
            isSpotlightIndexing: isSpotlightIndexing,
            spotlightIndexingPath: nil,
            spotlightIndexingDurationMinutes: spotlightDurationMinutes,
            activeAppsCount: 10,
            heavyAppsCount: 2
        )
    }
    
    // MARK: - Memory Component Tests (0-20 points)
    
    func testMemoryScore_lowPressure_noSwap_returns20() {
        let snapshot = makeSnapshot(memoryPressure: .low, swapUsedMB: 0)
        let driftScore = DriftScore.calculate(from: snapshot)
        
        // Memory: 20 (low pressure, no heavy swap)
        // Total should be high
        XCTAssertGreaterThanOrEqual(driftScore.score, 80)
    }
    
    func testMemoryScore_mediumPressure_deducts5() {
        let snapshotLow = makeSnapshot(memoryPressure: .low, swapUsedMB: 0)
        let snapshotMedium = makeSnapshot(memoryPressure: .medium, swapUsedMB: 0)
        
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        let scoreMedium = DriftScore.calculate(from: snapshotMedium)
        
        // Medium pressure should deduct 5 points from memory component
        XCTAssertEqual(scoreLow.score - scoreMedium.score, 5)
    }
    
    func testMemoryScore_highPressure_deducts15() {
        let snapshotLow = makeSnapshot(memoryPressure: .low, swapUsedMB: 0)
        let snapshotHigh = makeSnapshot(memoryPressure: .high, swapUsedMB: 0)
        
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        
        // High pressure should deduct 15 points from memory component
        XCTAssertEqual(scoreLow.score - scoreHigh.score, 15)
    }
    
    func testMemoryScore_heavySwap_additionalDeduction() {
        let snapshotNoSwap = makeSnapshot(memoryPressure: .low, swapUsedMB: 0)
        let snapshotHeavySwap = makeSnapshot(memoryPressure: .low, swapUsedMB: 3000) // > 2GB
        
        let scoreNoSwap = DriftScore.calculate(from: snapshotNoSwap)
        let scoreHeavySwap = DriftScore.calculate(from: snapshotHeavySwap)
        
        // Heavy swap (>2GB) should deduct additional 5 points from memory component
        // Plus swap component itself is affected
        XCTAssertLessThan(scoreHeavySwap.score, scoreNoSwap.score)
    }
    
    // MARK: - Swap Component Tests (0-20 points)
    
    func testSwapScore_noSwap_returns20() {
        let snapshot = makeSnapshot(swapUsedMB: 0)
        let driftScore = DriftScore.calculate(from: snapshot)
        
        // With no swap and ideal conditions, score should be 100
        XCTAssertEqual(driftScore.score, 100)
    }
    
    func testSwapScore_under512MB_returns18() {
        let snapshotNoSwap = makeSnapshot(swapUsedMB: 0)
        let snapshotLowSwap = makeSnapshot(swapUsedMB: 256)
        
        let scoreNoSwap = DriftScore.calculate(from: snapshotNoSwap)
        let scoreLowSwap = DriftScore.calculate(from: snapshotLowSwap)
        
        // 256MB swap should be 18 points (vs 20 for no swap)
        XCTAssertEqual(scoreNoSwap.score - scoreLowSwap.score, 2)
    }
    
    func testSwapScore_under1GB_returns15() {
        let snapshotNoSwap = makeSnapshot(swapUsedMB: 0)
        let snapshotSwap = makeSnapshot(swapUsedMB: 768)
        
        let scoreNoSwap = DriftScore.calculate(from: snapshotNoSwap)
        let scoreSwap = DriftScore.calculate(from: snapshotSwap)
        
        // 768MB swap should be 15 points (vs 20 for no swap)
        XCTAssertEqual(scoreNoSwap.score - scoreSwap.score, 5)
    }
    
    func testSwapScore_under2GB_returns10() {
        let snapshotNoSwap = makeSnapshot(swapUsedMB: 0)
        let snapshotSwap = makeSnapshot(swapUsedMB: 1500)
        
        let scoreNoSwap = DriftScore.calculate(from: snapshotNoSwap)
        let scoreSwap = DriftScore.calculate(from: snapshotSwap)
        
        // 1500MB swap should be 10 points (vs 20 for no swap)
        XCTAssertEqual(scoreNoSwap.score - scoreSwap.score, 10)
    }
    
    func testSwapScore_under3GB_returns5() {
        let snapshotNoSwap = makeSnapshot(swapUsedMB: 0)
        let snapshotSwap = makeSnapshot(swapUsedMB: 2500)
        
        let scoreNoSwap = DriftScore.calculate(from: snapshotNoSwap)
        let scoreSwap = DriftScore.calculate(from: snapshotSwap)
        
        // 2500MB swap should be 5 points (vs 20 for no swap)
        // But also memory component deducts 5 for heavy swap (>2GB)
        XCTAssertEqual(scoreNoSwap.score - scoreSwap.score, 20) // 15 swap + 5 memory
    }
    
    func testSwapScore_over3GB_returns0() {
        let snapshotNoSwap = makeSnapshot(swapUsedMB: 0)
        let snapshotSwap = makeSnapshot(swapUsedMB: 4000)
        
        let scoreNoSwap = DriftScore.calculate(from: snapshotNoSwap)
        let scoreSwap = DriftScore.calculate(from: snapshotSwap)
        
        // 4000MB swap should be 0 points (vs 20 for no swap)
        // Plus 5 memory deduction for heavy swap
        XCTAssertEqual(scoreNoSwap.score - scoreSwap.score, 25) // 20 swap + 5 memory
    }
    
    // MARK: - CPU Component Tests (0-20 points)
    
    func testCPUScore_idle70Plus_returns20() {
        let snapshot = makeSnapshot(cpuIdlePercent: 85.0)
        let driftScore = DriftScore.calculate(from: snapshot)
        
        XCTAssertEqual(driftScore.score, 100)
    }
    
    func testCPUScore_idle50to70_returns15() {
        let snapshotHigh = makeSnapshot(cpuIdlePercent: 85.0)
        let snapshotMid = makeSnapshot(cpuIdlePercent: 60.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreMid = DriftScore.calculate(from: snapshotMid)
        
        XCTAssertEqual(scoreHigh.score - scoreMid.score, 5)
    }
    
    func testCPUScore_idle30to50_returns10() {
        let snapshotHigh = makeSnapshot(cpuIdlePercent: 85.0)
        let snapshotLow = makeSnapshot(cpuIdlePercent: 40.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        
        XCTAssertEqual(scoreHigh.score - scoreLow.score, 10)
    }
    
    func testCPUScore_idle20to30_returns5() {
        let snapshotHigh = makeSnapshot(cpuIdlePercent: 85.0)
        let snapshotLow = makeSnapshot(cpuIdlePercent: 25.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        
        XCTAssertEqual(scoreHigh.score - scoreLow.score, 15)
    }
    
    func testCPUScore_idleUnder20_returns0() {
        let snapshotHigh = makeSnapshot(cpuIdlePercent: 85.0)
        let snapshotVeryLow = makeSnapshot(cpuIdlePercent: 10.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreVeryLow = DriftScore.calculate(from: snapshotVeryLow)
        
        XCTAssertEqual(scoreHigh.score - scoreVeryLow.score, 20)
    }
    
    // MARK: - Disk Component Tests (0-20 points)
    
    func testDiskScore_20PercentFree_returns20() {
        let snapshot = makeSnapshot(diskFreePercent: 50.0)
        let driftScore = DriftScore.calculate(from: snapshot)
        
        XCTAssertEqual(driftScore.score, 100)
    }
    
    func testDiskScore_15to20PercentFree_returns18() {
        let snapshotHigh = makeSnapshot(diskFreePercent: 50.0)
        let snapshotLow = makeSnapshot(diskFreePercent: 17.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        
        XCTAssertEqual(scoreHigh.score - scoreLow.score, 2)
    }
    
    func testDiskScore_10to15PercentFree_returns12() {
        let snapshotHigh = makeSnapshot(diskFreePercent: 50.0)
        let snapshotLow = makeSnapshot(diskFreePercent: 12.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        
        XCTAssertEqual(scoreHigh.score - scoreLow.score, 8)
    }
    
    func testDiskScore_5to10PercentFree_returns5() {
        let snapshotHigh = makeSnapshot(diskFreePercent: 50.0)
        let snapshotLow = makeSnapshot(diskFreePercent: 7.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreLow = DriftScore.calculate(from: snapshotLow)
        
        XCTAssertEqual(scoreHigh.score - scoreLow.score, 15)
    }
    
    func testDiskScore_under5PercentFree_returns0() {
        let snapshotHigh = makeSnapshot(diskFreePercent: 50.0)
        let snapshotCritical = makeSnapshot(diskFreePercent: 3.0)
        
        let scoreHigh = DriftScore.calculate(from: snapshotHigh)
        let scoreCritical = DriftScore.calculate(from: snapshotCritical)
        
        XCTAssertEqual(scoreHigh.score - scoreCritical.score, 20)
    }
    
    // MARK: - Indexing Component Tests (0-20 points)
    
    func testIndexingScore_notIndexing_returns20() {
        let snapshot = makeSnapshot(isSpotlightIndexing: false)
        let driftScore = DriftScore.calculate(from: snapshot)
        
        XCTAssertEqual(driftScore.score, 100)
    }
    
    func testIndexingScore_indexingUnder10Min_returns18() {
        let snapshotNotIndexing = makeSnapshot(isSpotlightIndexing: false)
        let snapshotIndexing = makeSnapshot(isSpotlightIndexing: true, spotlightDurationMinutes: 5)
        
        let scoreNotIndexing = DriftScore.calculate(from: snapshotNotIndexing)
        let scoreIndexing = DriftScore.calculate(from: snapshotIndexing)
        
        XCTAssertEqual(scoreNotIndexing.score - scoreIndexing.score, 2)
    }
    
    func testIndexingScore_indexing10to30Min_returns12() {
        let snapshotNotIndexing = makeSnapshot(isSpotlightIndexing: false)
        let snapshotIndexing = makeSnapshot(isSpotlightIndexing: true, spotlightDurationMinutes: 20)
        
        let scoreNotIndexing = DriftScore.calculate(from: snapshotNotIndexing)
        let scoreIndexing = DriftScore.calculate(from: snapshotIndexing)
        
        XCTAssertEqual(scoreNotIndexing.score - scoreIndexing.score, 8)
    }
    
    func testIndexingScore_indexing30to60Min_returns8() {
        let snapshotNotIndexing = makeSnapshot(isSpotlightIndexing: false)
        let snapshotIndexing = makeSnapshot(isSpotlightIndexing: true, spotlightDurationMinutes: 45)
        
        let scoreNotIndexing = DriftScore.calculate(from: snapshotNotIndexing)
        let scoreIndexing = DriftScore.calculate(from: snapshotIndexing)
        
        XCTAssertEqual(scoreNotIndexing.score - scoreIndexing.score, 12)
    }
    
    func testIndexingScore_indexingOver60Min_returns4() {
        let snapshotNotIndexing = makeSnapshot(isSpotlightIndexing: false)
        let snapshotIndexing = makeSnapshot(isSpotlightIndexing: true, spotlightDurationMinutes: 120)
        
        let scoreNotIndexing = DriftScore.calculate(from: snapshotNotIndexing)
        let scoreIndexing = DriftScore.calculate(from: snapshotIndexing)
        
        XCTAssertEqual(scoreNotIndexing.score - scoreIndexing.score, 16)
    }
    
    // MARK: - Status Mapping Tests
    
    func testStatus_scoreOver80_isStable() {
        let snapshot = makeSnapshot() // Perfect conditions = 100
        let driftScore = DriftScore.calculate(from: snapshot)
        
        XCTAssertEqual(driftScore.status, .stable)
        XCTAssertEqual(driftScore.status.label, "Stable")
    }
    
    func testStatus_score50to80_isDegrading() {
        // Create conditions for ~60 score
        let snapshot = makeSnapshot(
            memoryPressure: .medium, // -5
            swapUsedMB: 1500, // -10
            cpuIdlePercent: 45.0, // -10
            diskFreePercent: 50.0, // 0
            isSpotlightIndexing: true,
            spotlightDurationMinutes: 25 // -8
        )
        let driftScore = DriftScore.calculate(from: snapshot)
        
        // Score should be around 67
        XCTAssertEqual(driftScore.status, .degrading)
        XCTAssertEqual(driftScore.status.label, "Degrading")
    }
    
    func testStatus_scoreUnder50_needsRestart() {
        // Create very poor conditions
        let snapshot = makeSnapshot(
            memoryPressure: .high, // -15
            swapUsedMB: 4000, // -20 swap, -5 memory
            cpuIdlePercent: 10.0, // -20
            diskFreePercent: 3.0, // -20
            isSpotlightIndexing: true,
            spotlightDurationMinutes: 120 // -16
        )
        let driftScore = DriftScore.calculate(from: snapshot)
        
        // Score should be very low: 100 - (15+5) - 20 - 20 - 20 - 16 = 4
        XCTAssertEqual(driftScore.status, .needsRestart)
        XCTAssertEqual(driftScore.status.label, "Needs Restart")
    }
    
    // MARK: - Score Clamping Tests
    
    func testScore_isClamped0to100() {
        let perfectSnapshot = makeSnapshot()
        let perfectScore = DriftScore.calculate(from: perfectSnapshot)
        
        XCTAssertGreaterThanOrEqual(perfectScore.score, 0)
        XCTAssertLessThanOrEqual(perfectScore.score, 100)
        
        let terribleSnapshot = makeSnapshot(
            memoryPressure: .high,
            swapUsedMB: 5000,
            cpuIdlePercent: 5.0,
            diskFreePercent: 1.0,
            isSpotlightIndexing: true,
            spotlightDurationMinutes: 200
        )
        let terribleScore = DriftScore.calculate(from: terribleSnapshot)
        
        XCTAssertGreaterThanOrEqual(terribleScore.score, 0)
        XCTAssertLessThanOrEqual(terribleScore.score, 100)
    }
    
    // MARK: - Star Breakdown Tests
    
    func testGetStarBreakdown_returnsFormattedString() {
        let snapshot = makeSnapshot()
        let breakdown = DriftScore.getStarBreakdown(from: snapshot)
        
        XCTAssertTrue(breakdown.contains("Memory"))
        XCTAssertTrue(breakdown.contains("Swap"))
        XCTAssertTrue(breakdown.contains("CPU"))
        XCTAssertTrue(breakdown.contains("Disk"))
        XCTAssertTrue(breakdown.contains("Indexing"))
        XCTAssertTrue(breakdown.contains("★") || breakdown.contains("☆"))
    }
}
