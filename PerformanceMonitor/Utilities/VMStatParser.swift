import Foundation

/// Parser for vm_stat output to extract system memory information
struct VMStatParser {
    /// Parse swap usage from vm_stat output
    /// - Parameter vmStatOutput: The output string from vm_stat command
    /// - Returns: Swap used in GB, or 0.0 if parsing fails
    static func parseSwapUsed(_ vmStatOutput: String) -> Double {
        // Parse swapins and swapouts from vm_stat
        let lines = vmStatOutput.components(separatedBy: .newlines)
        var swapins: Int64 = 0
        var swapouts: Int64 = 0
        
        for line in lines {
            if line.contains("Swapins:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let intValue = Int64(value) {
                    swapins = intValue
                }
            } else if line.contains("Swapouts:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let intValue = Int64(value) {
                    swapouts = intValue
                }
            }
        }
        
        // Calculate swap used (swapouts - swapins) in pages, then convert to GB
        // macOS page size is typically 4096 bytes (4 KB)
        let pageSize: Int64 = 4096
        let swapPages = max(0, swapouts - swapins)
        let swapBytes = Double(swapPages * pageSize)
        return swapBytes / (1024 * 1024 * 1024) // Convert to GB
    }
    
    /// Alternative: Parse swap usage directly from sysctl
    /// - Returns: Swap used in MB, or 0 if parsing fails
    static func parseSwapUsedMBFromSysctl() -> Int {
        let output = Shell.runShell("/usr/sbin/sysctl", ["-n", "vm.swapusage"])
        // Format: total = 1024.00M  used = 512.00M  free = 512.00M
        let components = output.components(separatedBy: "used = ")
        guard components.count > 1 else { return 0 }
        
        let usedPart = components[1].components(separatedBy: " ").first ?? ""
        // Remove 'M' or 'G' suffix and convert to MB
        if usedPart.hasSuffix("M") {
            return Int(Double(usedPart.replacingOccurrences(of: "M", with: "")) ?? 0.0)
        } else if usedPart.hasSuffix("G") {
            let gb = Double(usedPart.replacingOccurrences(of: "G", with: "")) ?? 0.0
            return Int(gb * 1024.0) // Convert GB to MB
        }
        return 0
    }
    
    /// Parse free memory from vm_stat output
    /// - Parameter vmStatOutput: The output string from vm_stat command
    /// - Returns: Free memory in MB, or 0 if parsing fails
    /// Note: macOS page size is 16,384 bytes (16 KB) as per dev_notes.md
    static func parseFreeMemoryMB(_ vmStatOutput: String) -> Int {
        let lines = vmStatOutput.components(separatedBy: .newlines)
        let pageSize: Int = 16384 // 16 KB as specified in dev_notes.md
        
        for line in lines {
            if line.contains("Pages free:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let pages = Int(value) {
                    // Convert pages to MB: (pages * pageSize) / (1024 * 1024)
                    let bytes = pages * pageSize
                    return bytes / (1024 * 1024)
                }
            }
        }
        
        return 0
    }
    
    /// Parse compression pages from vm_stat output
    /// - Parameter vmStatOutput: The output string from vm_stat command
    /// - Returns: Number of pages stored in compressor, or 0 if parsing fails
    static func parseCompressionPages(_ vmStatOutput: String) -> Int {
        let lines = vmStatOutput.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("Pages stored in compressor:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let intValue = Int(value) {
                    return intValue
                }
            }
        }
        
        return 0
    }
    
    /// Get memory pressure level
    /// - Parameter vmStatOutput: The output string from vm_stat command
    /// - Returns: MemoryPressureLevel based on memory statistics
    static func getMemoryPressureLevel(_ vmStatOutput: String) -> MemoryPressureLevel {
        let lines = vmStatOutput.components(separatedBy: .newlines)
        let pageSize: Int = 16384 // 16 KB
        
        var freePages: Int = 0
        var activePages: Int = 0
        var inactivePages: Int = 0
        var wiredPages: Int = 0
        var compressedPages: Int = 0
        
        for line in lines {
            if line.contains("Pages free:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let pages = Int(value) {
                    freePages = pages
                }
            } else if line.contains("Pages active:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let pages = Int(value) {
                    activePages = pages
                }
            } else if line.contains("Pages inactive:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let pages = Int(value) {
                    inactivePages = pages
                }
            } else if line.contains("Pages wired down:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let pages = Int(value) {
                    wiredPages = pages
                }
            } else if line.contains("Pages stored in compressor:") {
                let components = line.components(separatedBy: .whitespaces)
                if let value = components.last?.replacingOccurrences(of: ".", with: ""),
                   let pages = Int(value) {
                    compressedPages = pages
                }
            }
        }
        
        // Calculate total memory and used memory
        let totalPages = freePages + activePages + inactivePages + wiredPages + compressedPages
        guard totalPages > 0 else { return .medium }
        
        let usedPages = totalPages - freePages
        let usedPercent = Double(usedPages) / Double(totalPages) * 100.0
        
        // Also consider compression ratio
        let compressionRatio = totalPages > 0 ? Double(compressedPages) / Double(totalPages) : 0.0
        
        // Determine pressure level
        if usedPercent > 90 || compressionRatio > 0.3 {
            return .high
        } else if usedPercent > 75 || compressionRatio > 0.15 {
            return .medium
        } else {
            return .low
        }
    }
}




