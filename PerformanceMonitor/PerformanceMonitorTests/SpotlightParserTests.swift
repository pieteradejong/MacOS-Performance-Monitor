import XCTest
@testable import PerformanceMonitor

final class SpotlightParserTests: XCTestCase {
    
    // MARK: - SpotlightStatus Structure Tests
    
    func testSpotlightStatus_structureIsValid() {
        let status = SpotlightParser.SpotlightStatus(
            isIndexing: true,
            indexingPath: "/Users/test/Documents",
            durationMinutes: 30
        )
        
        XCTAssertTrue(status.isIndexing)
        XCTAssertEqual(status.indexingPath, "/Users/test/Documents")
        XCTAssertEqual(status.durationMinutes, 30)
    }
    
    func testSpotlightStatus_nilValues() {
        let status = SpotlightParser.SpotlightStatus(
            isIndexing: false,
            indexingPath: nil,
            durationMinutes: nil
        )
        
        XCTAssertFalse(status.isIndexing)
        XCTAssertNil(status.indexingPath)
        XCTAssertNil(status.durationMinutes)
    }
    
    // MARK: - getSpotlightStatus Tests (Integration)
    
    func testGetSpotlightStatus_returnsValidData() {
        let status = SpotlightParser.getSpotlightStatus()
        
        // Status should be a valid boolean
        // isIndexing can be true or false
        XCTAssertNotNil(status)
        
        // If indexing, path might be set
        if status.isIndexing && status.indexingPath != nil {
            XCTAssertFalse(status.indexingPath!.isEmpty)
        }
        
        // Duration should be nil or positive
        if let duration = status.durationMinutes {
            XCTAssertGreaterThanOrEqual(duration, 0)
        }
    }
}
