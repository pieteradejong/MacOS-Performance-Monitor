import Foundation

/// Utility for safely executing shell commands using explicit paths
struct Shell {
    /// Execute a shell command using explicit path and return its output as a string
    /// - Parameters:
    ///   - executablePath: Full path to the executable (e.g., "/usr/bin/uptime")
    ///   - args: Array of command arguments
    /// - Returns: The command output as a string, or empty string on error
    static func runShell(_ executablePath: String, _ args: [String] = []) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}




