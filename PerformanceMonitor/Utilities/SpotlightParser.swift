import Foundation

/// Parser for Spotlight indexing status
struct SpotlightParser {
    /// Spotlight indexing information
    struct SpotlightStatus {
        let isIndexing: Bool
        let indexingPath: String?
        let durationMinutes: Int?
    }
    
    /// Check if Spotlight is currently indexing
    /// - Returns: SpotlightStatus with indexing information
    static func getSpotlightStatus() -> SpotlightStatus {
        // Use mdfind to check if indexing is active
        // Check mds process activity or use mdutil status
        let mdutilOutput = Shell.runShell("/usr/bin/mdutil", ["-s", "/"])
        
        // If indexing, mdutil might show status
        // Alternative: check mds process CPU usage (if high, likely indexing)
        let mdsOutput = Shell.runShell("/bin/ps", ["-eo", "pid,pcpu,comm,args"])
        let lines = mdsOutput.components(separatedBy: .newlines)
        
        var isIndexing = false
        var indexingPath: String?
        var highCPUProcess: String?
        var maxCPU: Double = 0
        
        // Look for mds process with high CPU (likely indexing)
        for line in lines {
            if line.contains("mds") && line.contains("mdworker") {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
                if components.count >= 3,
                   let cpuPercent = Double(components[1]),
                   cpuPercent > 10.0 { // If mds/mdworker using >10% CPU, likely indexing
                    isIndexing = true
                    // Try to extract path from args
                    if let pathRange = line.range(of: "/Users/") {
                        let pathPart = String(line[pathRange.lowerBound...])
                        let pathComponents = pathPart.components(separatedBy: .whitespaces)
                        indexingPath = pathComponents.first
                    }
                    break
                }
            }
        }
        
        // If not found via mds, check mdutil output
        if !isIndexing && mdutilOutput.contains("Indexing") {
            isIndexing = true
        }
        
        // Duration is harder to determine without historical tracking
        // For now, return nil (can be enhanced later)
        return SpotlightStatus(
            isIndexing: isIndexing,
            indexingPath: indexingPath,
            durationMinutes: nil
        )
    }
}
