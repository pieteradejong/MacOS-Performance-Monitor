import XCTest
@testable import PerformanceMonitor

final class UptimeParserTests: XCTestCase {
    
    // MARK: - Valid Input Tests
    
    func testParseLoadAverages_validOutput_returnsCorrectValues() {
        // Typical macOS uptime output
        let input = "10:30  up 5 days,  3:45, 2 users, load averages: 1.23 2.45 3.67"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 1.23, accuracy: 0.001)
        XCTAssertEqual(result.load5, 2.45, accuracy: 0.001)
        XCTAssertEqual(result.load15, 3.67, accuracy: 0.001)
    }
    
    func testParseLoadAverages_minimalValidOutput_returnsCorrectValues() {
        let input = "load averages: 0.50 1.00 1.50"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 0.50, accuracy: 0.001)
        XCTAssertEqual(result.load5, 1.00, accuracy: 0.001)
        XCTAssertEqual(result.load15, 1.50, accuracy: 0.001)
    }
    
    func testParseLoadAverages_highLoadValues_returnsCorrectValues() {
        let input = "load averages: 12.50 15.75 20.00"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 12.50, accuracy: 0.001)
        XCTAssertEqual(result.load5, 15.75, accuracy: 0.001)
        XCTAssertEqual(result.load15, 20.00, accuracy: 0.001)
    }
    
    func testParseLoadAverages_zeroValues_returnsZeros() {
        let input = "load averages: 0.00 0.00 0.00"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 0.00, accuracy: 0.001)
        XCTAssertEqual(result.load5, 0.00, accuracy: 0.001)
        XCTAssertEqual(result.load15, 0.00, accuracy: 0.001)
    }
    
    // MARK: - Invalid Input Tests
    
    func testParseLoadAverages_emptyString_returnsZeros() {
        let input = ""
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 0.0)
        XCTAssertEqual(result.load5, 0.0)
        XCTAssertEqual(result.load15, 0.0)
    }
    
    func testParseLoadAverages_noLoadAveragesLabel_returnsZeros() {
        let input = "10:30  up 5 days,  3:45, 2 users"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 0.0)
        XCTAssertEqual(result.load5, 0.0)
        XCTAssertEqual(result.load15, 0.0)
    }
    
    func testParseLoadAverages_incompleteLoadValues_returnsZeros() {
        // Only two values instead of three
        let input = "load averages: 1.23 2.45"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 0.0)
        XCTAssertEqual(result.load5, 0.0)
        XCTAssertEqual(result.load15, 0.0)
    }
    
    func testParseLoadAverages_malformedValues_returnsZeros() {
        let input = "load averages: abc def ghi"
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 0.0)
        XCTAssertEqual(result.load5, 0.0)
        XCTAssertEqual(result.load15, 0.0)
    }
    
    func testParseLoadAverages_extraWhitespace_returnsCorrectValues() {
        let input = "load averages:   1.23   2.45   3.67  "
        
        let result = UptimeParser.parseLoadAverages(input)
        
        XCTAssertEqual(result.load1, 1.23, accuracy: 0.001)
        XCTAssertEqual(result.load5, 2.45, accuracy: 0.001)
        XCTAssertEqual(result.load15, 3.67, accuracy: 0.001)
    }
}
