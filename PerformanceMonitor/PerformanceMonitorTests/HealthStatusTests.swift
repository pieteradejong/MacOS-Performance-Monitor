import XCTest
import SwiftUI
@testable import PerformanceMonitor

final class HealthStatusTests: XCTestCase {
    
    // MARK: - Color Tests
    
    func testColor_ok_isGreen() {
        XCTAssertEqual(HealthStatus.ok.color, Color.green)
    }
    
    func testColor_warning_isYellow() {
        XCTAssertEqual(HealthStatus.warning.color, Color.yellow)
    }
    
    func testColor_critical_isRed() {
        XCTAssertEqual(HealthStatus.critical.color, Color.red)
    }
    
    // MARK: - SF Symbol Tests
    
    func testSfSymbol_ok_isCheckmarkCircleFill() {
        XCTAssertEqual(HealthStatus.ok.sfSymbol, "checkmark.circle.fill")
    }
    
    func testSfSymbol_warning_isExclamationTriangleFill() {
        XCTAssertEqual(HealthStatus.warning.sfSymbol, "exclamationmark.triangle.fill")
    }
    
    func testSfSymbol_critical_isXmarkCircleFill() {
        XCTAssertEqual(HealthStatus.critical.sfSymbol, "xmark.circle.fill")
    }
    
    // MARK: - Label Tests
    
    func testLabel_ok_isOK() {
        XCTAssertEqual(HealthStatus.ok.label, "OK")
    }
    
    func testLabel_warning_isWarning() {
        XCTAssertEqual(HealthStatus.warning.label, "Warning")
    }
    
    func testLabel_critical_isRestartRecommended() {
        XCTAssertEqual(HealthStatus.critical.label, "Restart Recommended")
    }
    
    // MARK: - Explanation Tests
    
    func testExplanation_ok_describesNormalOperation() {
        XCTAssertEqual(HealthStatus.ok.explanation, "System is running normally")
    }
    
    func testExplanation_warning_advisesMonitoring() {
        XCTAssertEqual(HealthStatus.warning.explanation, "Consider monitoring system resources")
    }
    
    func testExplanation_critical_recommendsRestart() {
        XCTAssertEqual(HealthStatus.critical.explanation, "System restart recommended for optimal performance")
    }
    
    // MARK: - Enum Case Completeness
    
    func testAllCases_haveUniqueColors() {
        let colors = [HealthStatus.ok.color, HealthStatus.warning.color, HealthStatus.critical.color]
        let uniqueColors = Set(colors.map { $0.description })
        
        XCTAssertEqual(uniqueColors.count, 3, "Each health status should have a unique color")
    }
    
    func testAllCases_haveUniqueSymbols() {
        let symbols = [HealthStatus.ok.sfSymbol, HealthStatus.warning.sfSymbol, HealthStatus.critical.sfSymbol]
        let uniqueSymbols = Set(symbols)
        
        XCTAssertEqual(uniqueSymbols.count, 3, "Each health status should have a unique SF Symbol")
    }
    
    func testAllCases_haveUniqueLabels() {
        let labels = [HealthStatus.ok.label, HealthStatus.warning.label, HealthStatus.critical.label]
        let uniqueLabels = Set(labels)
        
        XCTAssertEqual(uniqueLabels.count, 3, "Each health status should have a unique label")
    }
}
