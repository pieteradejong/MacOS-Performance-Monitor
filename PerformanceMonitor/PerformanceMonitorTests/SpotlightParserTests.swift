import XCTest
@testable import PerformanceMonitor

final class SpotlightParserTests: XCTestCase {
    
    // MARK: - SpotlightActivityLevel Tests
    
    func testActivityLevel_idleWhenNoWorkersAndLowCPU() {
        let level = SpotlightActivityLevel.from(workerCount: 0, cpuPercent: 0.0)
        XCTAssertEqual(level, .idle)
    }
    
    func testActivityLevel_idleWhenLowCPU() {
        let level = SpotlightActivityLevel.from(workerCount: 0, cpuPercent: 4.9)
        XCTAssertEqual(level, .idle)
    }
    
    func testActivityLevel_lightWhenSomeWorkers() {
        let level = SpotlightActivityLevel.from(workerCount: 2, cpuPercent: 10.0)
        XCTAssertEqual(level, .light)
    }
    
    func testActivityLevel_lightWhenModerateCPU() {
        let level = SpotlightActivityLevel.from(workerCount: 0, cpuPercent: 15.0)
        XCTAssertEqual(level, .light)
    }
    
    func testActivityLevel_heavyWhenManyWorkers() {
        let level = SpotlightActivityLevel.from(workerCount: 4, cpuPercent: 10.0)
        XCTAssertEqual(level, .heavy)
    }
    
    func testActivityLevel_heavyWhenHighCPU() {
        let level = SpotlightActivityLevel.from(workerCount: 2, cpuPercent: 30.0)
        XCTAssertEqual(level, .heavy)
    }
    
    func testActivityLevel_heavyWhenVeryHighCPU() {
        let level = SpotlightActivityLevel.from(workerCount: 0, cpuPercent: 50.0)
        XCTAssertEqual(level, .heavy)
    }
    
    func testActivityLevel_rawValues() {
        XCTAssertEqual(SpotlightActivityLevel.idle.rawValue, "Idle")
        XCTAssertEqual(SpotlightActivityLevel.light.rawValue, "Light")
        XCTAssertEqual(SpotlightActivityLevel.heavy.rawValue, "Heavy")
    }
    
    // MARK: - SpotlightStatus Structure Tests
    
    func testSpotlightStatus_structureIsValid() {
        let status = SpotlightParser.SpotlightStatus(
            isIndexing: true,
            indexingPath: "/Users/test/Documents",
            durationMinutes: 30,
            activeWorkerCount: 4,
            totalCPUPercent: 45.5,
            indexedItemCount: 374933,
            activityLevel: .heavy
        )
        
        XCTAssertTrue(status.isIndexing)
        XCTAssertEqual(status.indexingPath, "/Users/test/Documents")
        XCTAssertEqual(status.durationMinutes, 30)
        XCTAssertEqual(status.activeWorkerCount, 4)
        XCTAssertEqual(status.totalCPUPercent, 45.5, accuracy: 0.01)
        XCTAssertEqual(status.indexedItemCount, 374933)
        XCTAssertEqual(status.activityLevel, .heavy)
    }
    
    func testSpotlightStatus_idleState() {
        let status = SpotlightParser.SpotlightStatus(
            isIndexing: false,
            indexingPath: nil,
            durationMinutes: nil,
            activeWorkerCount: 0,
            totalCPUPercent: 0.0,
            indexedItemCount: 500000,
            activityLevel: .idle
        )
        
        XCTAssertFalse(status.isIndexing)
        XCTAssertNil(status.indexingPath)
        XCTAssertNil(status.durationMinutes)
        XCTAssertEqual(status.activeWorkerCount, 0)
        XCTAssertEqual(status.totalCPUPercent, 0.0, accuracy: 0.01)
        XCTAssertEqual(status.indexedItemCount, 500000)
        XCTAssertEqual(status.activityLevel, .idle)
    }
    
    func testSpotlightStatus_lightActivityState() {
        let status = SpotlightParser.SpotlightStatus(
            isIndexing: true,
            indexingPath: nil,
            durationMinutes: nil,
            activeWorkerCount: 2,
            totalCPUPercent: 8.5,
            indexedItemCount: nil,
            activityLevel: .light
        )
        
        XCTAssertTrue(status.isIndexing)
        XCTAssertEqual(status.activeWorkerCount, 2)
        XCTAssertEqual(status.totalCPUPercent, 8.5, accuracy: 0.01)
        XCTAssertNil(status.indexedItemCount)
        XCTAssertEqual(status.activityLevel, .light)
    }
    
    // MARK: - getSpotlightStatus Tests (Integration)
    
    func testGetSpotlightStatus_returnsValidData() {
        let status = SpotlightParser.getSpotlightStatus()
        
        // Status should be a valid object
        XCTAssertNotNil(status)
        
        // Worker count should be non-negative
        XCTAssertGreaterThanOrEqual(status.activeWorkerCount, 0)
        
        // CPU percent should be non-negative
        XCTAssertGreaterThanOrEqual(status.totalCPUPercent, 0.0)
        
        // Activity level should be valid
        XCTAssertTrue([.idle, .light, .heavy].contains(status.activityLevel))
        
        // Indexed item count should be nil or positive
        if let count = status.indexedItemCount {
            XCTAssertGreaterThan(count, 0)
        }
        
        // If indexing path is set, it should not be empty
        if let path = status.indexingPath {
            XCTAssertFalse(path.isEmpty)
        }
        
        // Duration should be nil or positive
        if let duration = status.durationMinutes {
            XCTAssertGreaterThanOrEqual(duration, 0)
        }
    }
    
    func testGetSpotlightStatus_activityLevelConsistency() {
        let status = SpotlightParser.getSpotlightStatus()
        
        // Verify activity level is consistent with metrics
        let expectedLevel = SpotlightActivityLevel.from(
            workerCount: status.activeWorkerCount,
            cpuPercent: status.totalCPUPercent
        )
        XCTAssertEqual(status.activityLevel, expectedLevel)
    }
}
