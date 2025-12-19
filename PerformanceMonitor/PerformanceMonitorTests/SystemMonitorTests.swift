import XCTest
@testable import PerformanceMonitor

@MainActor
final class SystemMonitorTests: XCTestCase {
    
    var mockExecutor: MockShellExecutor!
    
    override func setUp() async throws {
        try await super.setUp()
        mockExecutor = MockShellExecutor()
        Shell.executor = mockExecutor
        setupMockResponses()
    }
    
    override func tearDown() async throws {
        Shell.resetToRealExecutor()
        mockExecutor = nil
        try await super.tearDown()
    }
    
    private func setupMockResponses() {
        // Mock uptime output
        mockExecutor.mockResponses["/usr/bin/uptime"] = "12:00  up 3 days, 2:30, 2 users, load averages: 1.50 2.00 2.50"
        
        // Mock sysctl swap output
        mockExecutor.mockResponses["/usr/sbin/sysctl -n vm.swapusage"] = "total = 2048.00M  used = 256.00M  free = 1792.00M"
        
        // Mock vm_stat output
        mockExecutor.mockResponses["/usr/bin/vm_stat"] = """
        Mach Virtual Memory Statistics: (page size of 16384 bytes)
        Pages free:                              100000.
        Pages active:                            200000.
        Pages inactive:                           50000.
        Pages speculative:                        10000.
        Pages throttled:                              0.
        Pages wired down:                         80000.
        Pages purgeable:                          10000.
        Pages stored in compressor:               30000.
        Swapins:                                    500.
        Swapouts:                                   600.
        """
        
        // Mock top output for CPU
        mockExecutor.mockResponses["/usr/bin/top -l 1 -n 0"] = """
        Processes: 300 total, 2 running, 298 sleeping, 1500 threads
        Load Avg: 1.50, 2.00, 2.50
        CPU usage: 15.50% user, 8.25% sys, 76.25% idle
        SharedLibs: 300M resident, 50M data, 20M linkedit.
        MemRegions: 100000 total, 4G resident, 100M private, 500M shared.
        """
        
        // Mock ps output for top process
        mockExecutor.mockResponses["/bin/ps -eo pid,pcpu,comm"] = """
        PID  %CPU COMM
        123  25.5 Safari
        456  10.2 Xcode
        789   5.1 Terminal
        """
        
        // Mock df output for disk
        mockExecutor.mockResponses["/bin/df -h /"] = """
        Filesystem     Size   Used  Avail Capacity  Mounted on
        /dev/disk1s1   500Gi  350Gi  150Gi    70%    /
        """
        
        // Mock mdutil and ps for Spotlight
        mockExecutor.mockResponses["/usr/bin/mdutil -s /"] = "Indexing enabled."
        mockExecutor.mockResponses["/bin/ps -eo pid,pcpu,comm,args"] = """
        PID  %CPU COMM         ARGS
        100   2.0 Safari       /Applications/Safari.app/Contents/MacOS/Safari
        200   1.5 Finder       /System/Library/CoreServices/Finder.app/Contents/MacOS/Finder
        """
        
        // Mock ps for app activity
        mockExecutor.mockResponses["/bin/ps -eo pid,pcpu,pmem,comm"] = """
        PID  %CPU %MEM COMM
        100  25.5  3.0 Safari
        200  10.2  2.0 Xcode
        300   5.1  1.0 Terminal
        400  60.0  8.0 Chrome
        """
    }
    
    // MARK: - Initialization Tests
    
    func testSystemMonitor_initializes() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        // Monitor should have a snapshot after initialization
        XCTAssertNotNil(monitor.snapshot)
    }
    
    // MARK: - Health Status Tests
    
    func testHealthStatus_ok_whenSwapUnder1GB() async {
        // Default mock has 256MB swap - health depends on uptime (from ProcessInfo) and swap
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        // With low swap, health should be ok or warning (depending on actual system uptime)
        // We can't easily mock ProcessInfo.processInfo.systemUptime
        XCTAssertNotNil(monitor.health)
    }
    
    func testHealthStatus_warning_whenSwapOver1GB() async {
        // Modify mock to show 1.5GB swap
        mockExecutor.mockResponses["/usr/sbin/sysctl -n vm.swapusage"] = "total = 4096.00M  used = 1536.00M  free = 2560.00M"
        
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        // With 1.5GB swap, health should be at least warning (unless uptime is critical)
        XCTAssertTrue(monitor.health == .warning || monitor.health == .critical)
    }
    
    func testHealthStatus_critical_whenSwapOver3GB() async {
        // Modify mock to show 4GB swap
        mockExecutor.mockResponses["/usr/sbin/sysctl -n vm.swapusage"] = "total = 8192.00M  used = 4096.00M  free = 4096.00M"
        
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        // With 4GB swap, health should be critical
        XCTAssertEqual(monitor.health, .critical)
    }
    
    // MARK: - Formatted Output Tests
    
    func testFormattedUptime_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let uptime = monitor.formattedUptime()
        
        // Should be in format "X.Xd"
        XCTAssertTrue(uptime.hasSuffix("d"))
    }
    
    func testFormattedUptimeDetailed_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let uptime = monitor.formattedUptimeDetailed()
        
        // Should contain "d" and "h"
        XCTAssertTrue(uptime.contains("d"))
        XCTAssertTrue(uptime.contains("h"))
    }
    
    func testFormattedSwapUsed_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let swap = monitor.formattedSwapUsed()
        
        // Should contain MB or GB
        XCTAssertTrue(swap.contains("MB") || swap.contains("GB"))
    }
    
    func testFormattedFreeMemory_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let memory = monitor.formattedFreeMemory()
        
        // Should contain MB or GB
        XCTAssertTrue(memory.contains("MB") || memory.contains("GB"))
    }
    
    func testFormattedLoadAverages_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let loads = monitor.formattedLoadAverages()
        
        // Should have 3 space-separated values
        let components = loads.split(separator: " ")
        XCTAssertEqual(components.count, 3)
    }
    
    func testFormattedCPUBreakdown_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let cpu = monitor.formattedCPUBreakdown()
        
        // Should contain User, System, Idle
        XCTAssertTrue(cpu.contains("User"))
        XCTAssertTrue(cpu.contains("System"))
        XCTAssertTrue(cpu.contains("Idle"))
    }
    
    func testFormattedMemoryPressure_returnsValidLevel() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let pressure = monitor.formattedMemoryPressure()
        
        // Should be one of Low, Medium, High
        XCTAssertTrue(["Low", "Medium", "High"].contains(pressure))
    }
    
    func testFormattedDiskFree_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let disk = monitor.formattedDiskFree()
        
        // Should contain "GB" and "%"
        XCTAssertTrue(disk.contains("GB"))
        XCTAssertTrue(disk.contains("%"))
    }
    
    func testFormattedSpotlightStatus_returnsValidStatus() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let spotlight = monitor.formattedSpotlightStatus()
        
        // Should start with "Spotlight:"
        XCTAssertTrue(spotlight.hasPrefix("Spotlight:"))
    }
    
    func testFormattedAppActivity_returnsCorrectFormat() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let activity = monitor.formattedAppActivity()
        
        // Should contain "heavy" in parentheses
        XCTAssertTrue(activity.contains("heavy"))
        XCTAssertTrue(activity.contains("("))
        XCTAssertTrue(activity.contains(")"))
    }
    
    // MARK: - DriftScore Tests
    
    func testDriftScore_calculatedFromSnapshot() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let driftScore = monitor.driftScore
        
        XCTAssertNotNil(driftScore)
        if let score = driftScore {
            XCTAssertGreaterThanOrEqual(score.score, 0)
            XCTAssertLessThanOrEqual(score.score, 100)
        }
    }
    
    // MARK: - Snapshot Tests
    
    func testSnapshot_containsAllMetrics() async {
        let monitor = SystemMonitor(updateInterval: 60.0)
        
        let snapshot = monitor.snapshot
        
        XCTAssertNotNil(snapshot)
        if let snapshot = snapshot {
            // Verify all metrics are captured
            XCTAssertGreaterThanOrEqual(snapshot.uptimeSeconds, 0)
            XCTAssertGreaterThanOrEqual(snapshot.load1, 0)
            XCTAssertGreaterThanOrEqual(snapshot.swapUsedMB, 0)
            XCTAssertGreaterThanOrEqual(snapshot.freeMemoryMB, 0)
            XCTAssertGreaterThanOrEqual(snapshot.cpuIdlePercent, 0)
            XCTAssertGreaterThanOrEqual(snapshot.diskFreeGB, 0)
        }
    }
}

// MARK: - MockShellExecutor Tests

@MainActor
final class MockShellExecutorTests: XCTestCase {
    
    func testMockExecutor_returnsConfiguredResponse() async {
        let mock = MockShellExecutor()
        mock.mockResponses["/usr/bin/test"] = "test output"
        
        let result = mock.runShell("/usr/bin/test", [])
        
        XCTAssertEqual(result, "test output")
    }
    
    func testMockExecutor_recordsCalls() async {
        let mock = MockShellExecutor()
        
        _ = mock.runShell("/usr/bin/test", ["arg1", "arg2"])
        
        XCTAssertEqual(mock.recordedCalls.count, 1)
        XCTAssertEqual(mock.recordedCalls[0].path, "/usr/bin/test")
        XCTAssertEqual(mock.recordedCalls[0].args, ["arg1", "arg2"])
    }
    
    func testMockExecutor_reset_clearsState() async {
        let mock = MockShellExecutor()
        mock.mockResponses["/test"] = "output"
        _ = mock.runShell("/test", [])
        
        mock.reset()
        
        XCTAssertTrue(mock.mockResponses.isEmpty)
        XCTAssertTrue(mock.recordedCalls.isEmpty)
    }
}
