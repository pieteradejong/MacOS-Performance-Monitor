import XCTest
@testable import PerformanceMonitor

final class VMStatParserTests: XCTestCase {
    
    // MARK: - Sample vm_stat Output
    
    let sampleVMStatOutput = """
    Mach Virtual Memory Statistics: (page size of 16384 bytes)
    Pages free:                               12345.
    Pages active:                            234567.
    Pages inactive:                          123456.
    Pages speculative:                         5678.
    Pages throttled:                              0.
    Pages wired down:                         98765.
    Pages purgeable:                          12345.
    "Translation faults":                 123456789.
    Pages copy-on-write:                   12345678.
    Pages zero filled:                     98765432.
    Pages reactivated:                      1234567.
    Pages purged:                            123456.
    File-backed pages:                       234567.
    Anonymous pages:                         345678.
    Pages stored in compressor:               50000.
    Pages occupied by compressor:             25000.
    Decompressions:                          123456.
    Compressions:                            234567.
    Pageins:                                 345678.
    Pageouts:                                    12.
    Swapins:                                   1000.
    Swapouts:                                  2000.
    """
    
    // MARK: - parseFreeMemoryMB Tests
    
    func testParseFreeMemoryMB_validOutput_returnsCorrectValue() {
        let result = VMStatParser.parseFreeMemoryMB(sampleVMStatOutput)
        
        // 12345 pages * 16384 bytes / (1024 * 1024) = 192.89 MB ≈ 192 MB
        XCTAssertEqual(result, 192)
    }
    
    func testParseFreeMemoryMB_emptyString_returnsZero() {
        let result = VMStatParser.parseFreeMemoryMB("")
        
        XCTAssertEqual(result, 0)
    }
    
    func testParseFreeMemoryMB_noFreePages_returnsZero() {
        let input = "Mach Virtual Memory Statistics:\nPages active: 12345."
        
        let result = VMStatParser.parseFreeMemoryMB(input)
        
        XCTAssertEqual(result, 0)
    }
    
    func testParseFreeMemoryMB_largeFreePages_returnsCorrectValue() {
        let input = "Pages free:                             1000000."
        
        let result = VMStatParser.parseFreeMemoryMB(input)
        
        // 1000000 pages * 16384 bytes / (1024 * 1024) = 15625 MB
        XCTAssertEqual(result, 15625)
    }
    
    // MARK: - parseSwapUsed Tests
    
    func testParseSwapUsed_validOutput_returnsCorrectValue() {
        let result = VMStatParser.parseSwapUsed(sampleVMStatOutput)
        
        // (2000 - 1000) pages * 4096 bytes / (1024^3) = 0.00381... GB
        XCTAssertEqual(result, 0.00381, accuracy: 0.001)
    }
    
    func testParseSwapUsed_noSwap_returnsZero() {
        let input = """
        Swapins:                                      0.
        Swapouts:                                     0.
        """
        
        let result = VMStatParser.parseSwapUsed(input)
        
        XCTAssertEqual(result, 0.0)
    }
    
    func testParseSwapUsed_moreSwapinsThanSwapouts_returnsZero() {
        let input = """
        Swapins:                                   5000.
        Swapouts:                                  1000.
        """
        
        let result = VMStatParser.parseSwapUsed(input)
        
        // max(0, swapouts - swapins) = max(0, -4000) = 0
        XCTAssertEqual(result, 0.0)
    }
    
    // MARK: - getMemoryPressureLevel Tests
    
    func testGetMemoryPressureLevel_lowUsage_returnsLow() {
        // Create output with lots of free pages relative to total
        let input = """
        Pages free:                              500000.
        Pages active:                            100000.
        Pages inactive:                          100000.
        Pages wired down:                         50000.
        Pages stored in compressor:               10000.
        """
        
        let result = VMStatParser.getMemoryPressureLevel(input)
        
        // Total: 760000, Used: 260000, UsedPercent: ~34%, Compression: ~1.3%
        XCTAssertEqual(result, .low)
    }
    
    func testGetMemoryPressureLevel_mediumUsage_returnsMedium() {
        // Create output with moderate memory pressure
        let input = """
        Pages free:                              100000.
        Pages active:                            300000.
        Pages inactive:                          100000.
        Pages wired down:                        100000.
        Pages stored in compressor:               50000.
        """
        
        let result = VMStatParser.getMemoryPressureLevel(input)
        
        // Total: 650000, Free: 100000, Used: 550000, UsedPercent: ~84.6%
        XCTAssertEqual(result, .medium)
    }
    
    func testGetMemoryPressureLevel_highUsage_returnsHigh() {
        // Create output with high memory pressure
        let input = """
        Pages free:                               10000.
        Pages active:                            400000.
        Pages inactive:                          100000.
        Pages wired down:                        200000.
        Pages stored in compressor:              200000.
        """
        
        let result = VMStatParser.getMemoryPressureLevel(input)
        
        // Total: 910000, Free: 10000, Used: 900000, UsedPercent: ~98.9%
        // Compression ratio: 200000/910000 = ~22%
        XCTAssertEqual(result, .high)
    }
    
    func testGetMemoryPressureLevel_highCompressionRatio_returnsHigh() {
        // High compression even with some free memory
        let input = """
        Pages free:                              100000.
        Pages active:                            200000.
        Pages inactive:                           50000.
        Pages wired down:                        100000.
        Pages stored in compressor:              200000.
        """
        
        let result = VMStatParser.getMemoryPressureLevel(input)
        
        // Total: 650000, Compression ratio: 200000/650000 = ~30.7% (> 0.3)
        XCTAssertEqual(result, .high)
    }
    
    func testGetMemoryPressureLevel_emptyInput_returnsMedium() {
        let result = VMStatParser.getMemoryPressureLevel("")
        
        // Default when parsing fails
        XCTAssertEqual(result, .medium)
    }
    
    // MARK: - parseCompressionPages Tests
    
    func testParseCompressionPages_validOutput_returnsCorrectValue() {
        let result = VMStatParser.parseCompressionPages(sampleVMStatOutput)
        
        XCTAssertEqual(result, 50000)
    }
    
    func testParseCompressionPages_noCompression_returnsZero() {
        let input = "Pages free: 12345."
        
        let result = VMStatParser.parseCompressionPages(input)
        
        XCTAssertEqual(result, 0)
    }
}
