import Foundation

/// Parser for uptime command output to extract load averages
struct UptimeParser {
    /// Parse load averages from uptime command output
    /// - Parameter uptimeOutput: The output string from /usr/bin/uptime
    /// - Returns: Tuple of (load1, load5, load15), or (0, 0, 0) if parsing fails
    /// Example output: "load averages: 1.23 2.45 3.67"
    static func parseLoadAverages(_ uptimeOutput: String) -> (load1: Double, load5: Double, load15: Double) {
        // Look for "load averages:" pattern
        guard let range = uptimeOutput.range(of: "load averages:") else {
            return (0, 0, 0)
        }
        
        let afterLabel = String(uptimeOutput[range.upperBound...])
        let components = afterLabel.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .compactMap { Double($0) }
        
        guard components.count >= 3 else {
            return (0, 0, 0)
        }
        
        return (components[0], components[1], components[2])
    }
}
