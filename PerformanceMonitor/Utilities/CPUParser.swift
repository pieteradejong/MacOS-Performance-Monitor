import Foundation

/// Parser for CPU usage information
struct CPUParser {
    /// Parse CPU usage breakdown from top command
    /// - Returns: Tuple of (user%, system%, idle%), or (0, 0, 100) if parsing fails
    static func parseCPUUsage() -> (user: Double, system: Double, idle: Double) {
        // Use top command with -l 1 (single sample) and -n 0 (no processes)
        // Then grep for "CPU usage"
        let output = Shell.runShell("/usr/bin/top", ["-l", "1", "-n", "0"])
        
        // Look for line like: "CPU usage: 12.34% user, 5.67% sys, 81.99% idle"
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("CPU usage:") {
                // Parse percentages
                let userMatch = extractPercentage(from: line, pattern: "user")
                let sysMatch = extractPercentage(from: line, pattern: "sys")
                let idleMatch = extractPercentage(from: line, pattern: "idle")
                
                return (userMatch, sysMatch, idleMatch)
            }
        }
        
        return (0, 0, 100)
    }
    
    /// Extract percentage value from a line containing a pattern
    private static func extractPercentage(from line: String, pattern: String) -> Double {
        // Look for pattern like "12.34% user" or "5.67% sys"
        // Escape special regex characters in pattern
        let escapedPattern = NSRegularExpression.escapedPattern(for: pattern)
        guard let regex = try? NSRegularExpression(pattern: "([0-9]+\\.[0-9]+)%\\s+\(escapedPattern)", options: []) else {
            return 0.0
        }
        
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex.firstMatch(in: line, options: [], range: range),
           match.numberOfRanges > 1,
           let percentRange = Range(match.range(at: 1), in: line),
           let value = Double(String(line[percentRange])) {
            return value
        }
        
        return 0.0
    }
    
    /// Get top CPU-consuming process
    /// - Returns: Tuple of (process name, CPU percentage), or (nil, 0) if not found
    static func getTopProcess() -> (name: String?, cpuPercent: Double) {
        // Use ps command to get top CPU process
        // ps -eo pid,pcpu,comm | sort -rnk 2 | head -2 | tail -1
        let psOutput = Shell.runShell("/bin/ps", ["-eo", "pid,pcpu,comm"])
        let lines = psOutput.components(separatedBy: .newlines)
        
        // Skip header line, find highest CPU process
        var maxCPU: Double = 0
        var topProcess: String?
        
        for line in lines.dropFirst() {
            let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
            guard components.count >= 3,
                  let cpuPercent = Double(components[1]),
                  cpuPercent > maxCPU else {
                continue
            }
            
            maxCPU = cpuPercent
            topProcess = components[2]
        }
        
        return (topProcess, maxCPU)
    }
}
