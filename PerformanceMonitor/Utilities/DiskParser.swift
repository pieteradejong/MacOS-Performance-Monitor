import Foundation

/// Parser for disk usage information
struct DiskParser {
    /// Disk information structure
    struct DiskInfo {
        let totalGB: Double
        let freeGB: Double
        let usedGB: Double
        let freePercent: Double
    }
    
    /// Parse disk usage from df command
    /// - Returns: DiskInfo with disk space information, or default values if parsing fails
    static func parseDiskUsage() -> DiskInfo {
        // Use df -h / to get root volume info
        let output = Shell.runShell("/bin/df", ["-h", "/"])
        let lines = output.components(separatedBy: .newlines)
        
        // Skip header line, parse first data line
        guard lines.count >= 2 else {
            return DiskInfo(totalGB: 0, freeGB: 0, usedGB: 0, freePercent: 0)
        }
        
        let dataLine = lines[1]
        let components = dataLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        // Format: Filesystem Size Used Avail Capacity Mounted
        // Example: /dev/disk3s1s1 500Gi 450Gi 50Gi 90% /
        guard components.count >= 5 else {
            return DiskInfo(totalGB: 0, freeGB: 0, usedGB: 0, freePercent: 0)
        }
        
        let totalGB = parseSize(components[1])
        let usedGB = parseSize(components[2])
        let freeGB = parseSize(components[3])
        let capacityStr = components[4].replacingOccurrences(of: "%", with: "")
        let usedPercent = Double(capacityStr) ?? 0.0
        let freePercent = 100.0 - usedPercent
        
        return DiskInfo(
            totalGB: totalGB,
            freeGB: freeGB,
            usedGB: usedGB,
            freePercent: freePercent
        )
    }
    
    /// Parse size string (e.g., "500Gi", "50GB", "1024Mi") to GB
    private static func parseSize(_ sizeStr: String) -> Double {
        let sizeStr = sizeStr.uppercased()
        
        if sizeStr.hasSuffix("TI") || sizeStr.hasSuffix("TB") {
            let value = Double(sizeStr.dropLast(2)) ?? 0.0
            return value * 1024.0 // Convert TB to GB
        } else if sizeStr.hasSuffix("GI") || sizeStr.hasSuffix("GB") {
            let value = Double(sizeStr.dropLast(2)) ?? 0.0
            return value
        } else if sizeStr.hasSuffix("MI") || sizeStr.hasSuffix("MB") {
            let value = Double(sizeStr.dropLast(2)) ?? 0.0
            return value / 1024.0 // Convert MB to GB
        } else if sizeStr.hasSuffix("KI") || sizeStr.hasSuffix("KB") {
            let value = Double(sizeStr.dropLast(2)) ?? 0.0
            return value / (1024.0 * 1024.0) // Convert KB to GB
        }
        
        return 0.0
    }
}
