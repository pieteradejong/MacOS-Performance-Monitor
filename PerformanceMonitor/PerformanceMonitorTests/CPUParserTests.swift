import XCTest
@testable import PerformanceMonitor

final class CPUParserTests: XCTestCase {
    
    // MARK: - extractPercentage Tests (tested indirectly through parseCPUUsage)
    
    // Note: parseCPUUsage calls Shell.runShell, so we test the actual system values
    // For more granular testing, we would need to make the regex extraction public or testable
    
    func testParseCPUUsage_returnsValidPercentages() {
        let result = CPUParser.parseCPUUsage()
        
        // User, system, and idle should be in valid ranges
        XCTAssertGreaterThanOrEqual(result.user, 0.0)
        XCTAssertLessThanOrEqual(result.user, 100.0)
        
        XCTAssertGreaterThanOrEqual(result.system, 0.0)
        XCTAssertLessThanOrEqual(result.system, 100.0)
        
        XCTAssertGreaterThanOrEqual(result.idle, 0.0)
        XCTAssertLessThanOrEqual(result.idle, 100.0)
    }
    
    func testParseCPUUsage_percentagesSumToApproximately100() {
        let result = CPUParser.parseCPUUsage()
        
        let total = result.user + result.system + result.idle
        
        // Total should be approximately 100 (allowing for rounding)
        // Some systems may have additional categories, so we allow a range
        XCTAssertGreaterThan(total, 95.0, "CPU percentages should sum to approximately 100")
        XCTAssertLessThanOrEqual(total, 100.5, "CPU percentages should not exceed 100")
    }
    
    // MARK: - getTopProcess Tests
    
    func testGetTopProcess_returnsValidData() {
        let result = CPUParser.getTopProcess()
        
        // CPU percent should be valid
        XCTAssertGreaterThanOrEqual(result.cpuPercent, 0.0)
        
        // If we have a process, the name should be non-empty
        if let name = result.name {
            XCTAssertFalse(name.isEmpty, "Process name should not be empty")
        }
    }
    
    func testGetTopProcess_cpuPercentIsReasonable() {
        let result = CPUParser.getTopProcess()
        
        // Top process CPU should be reasonable (not more than 800% for 8 cores)
        XCTAssertLessThan(result.cpuPercent, 1000.0, "Top process CPU should be reasonable")
    }
}

// MARK: - CPUParser Regex Pattern Tests

/// These tests verify the regex pattern behavior by testing extracted values
extension CPUParserTests {
    
    func testCPUUsagePatternMatching() {
        // Testing the pattern that parseCPUUsage uses internally
        // Pattern: "([0-9]+\\.[0-9]+)%\\s+<keyword>"
        
        // Test pattern with different keywords
        let testLine = "CPU usage: 12.34% user, 5.67% sys, 81.99% idle"
        
        // Extract user
        let userPattern = try! NSRegularExpression(pattern: "([0-9]+\\.[0-9]+)%\\s+user", options: [])
        let userRange = NSRange(location: 0, length: testLine.utf16.count)
        
        if let match = userPattern.firstMatch(in: testLine, options: [], range: userRange),
           match.numberOfRanges > 1,
           let percentRange = Range(match.range(at: 1), in: testLine),
           let value = Double(String(testLine[percentRange])) {
            XCTAssertEqual(value, 12.34, accuracy: 0.01)
        } else {
            XCTFail("Should match user percentage pattern")
        }
        
        // Extract sys
        let sysPattern = try! NSRegularExpression(pattern: "([0-9]+\\.[0-9]+)%\\s+sys", options: [])
        if let match = sysPattern.firstMatch(in: testLine, options: [], range: userRange),
           match.numberOfRanges > 1,
           let percentRange = Range(match.range(at: 1), in: testLine),
           let value = Double(String(testLine[percentRange])) {
            XCTAssertEqual(value, 5.67, accuracy: 0.01)
        } else {
            XCTFail("Should match sys percentage pattern")
        }
        
        // Extract idle
        let idlePattern = try! NSRegularExpression(pattern: "([0-9]+\\.[0-9]+)%\\s+idle", options: [])
        if let match = idlePattern.firstMatch(in: testLine, options: [], range: userRange),
           match.numberOfRanges > 1,
           let percentRange = Range(match.range(at: 1), in: testLine),
           let value = Double(String(testLine[percentRange])) {
            XCTAssertEqual(value, 81.99, accuracy: 0.01)
        } else {
            XCTFail("Should match idle percentage pattern")
        }
    }
    
    func testCPUUsagePatternMatching_edgeCases() {
        // Test with 0% values
        let zeroLine = "CPU usage: 0.00% user, 0.00% sys, 100.00% idle"
        
        let idlePattern = try! NSRegularExpression(pattern: "([0-9]+\\.[0-9]+)%\\s+idle", options: [])
        let range = NSRange(location: 0, length: zeroLine.utf16.count)
        
        if let match = idlePattern.firstMatch(in: zeroLine, options: [], range: range),
           match.numberOfRanges > 1,
           let percentRange = Range(match.range(at: 1), in: zeroLine),
           let value = Double(String(zeroLine[percentRange])) {
            XCTAssertEqual(value, 100.00, accuracy: 0.01)
        } else {
            XCTFail("Should match 100% idle pattern")
        }
    }
    
    func testCPUUsagePatternMatching_noMatch() {
        let invalidLine = "Some random text without CPU info"
        
        let userPattern = try! NSRegularExpression(pattern: "([0-9]+\\.[0-9]+)%\\s+user", options: [])
        let range = NSRange(location: 0, length: invalidLine.utf16.count)
        
        let match = userPattern.firstMatch(in: invalidLine, options: [], range: range)
        XCTAssertNil(match, "Should not match invalid input")
    }
}
