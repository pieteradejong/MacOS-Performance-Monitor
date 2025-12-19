import Foundation

/// Protocol for shell command execution
protocol ShellExecutor {
    func runShell(_ executablePath: String, _ args: [String]) -> String
}

/// Default implementation that executes real shell commands
struct RealShellExecutor: ShellExecutor {
    func runShell(_ executablePath: String, _ args: [String] = []) -> String {
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

/// Mock shell executor for testing
class MockShellExecutor: ShellExecutor {
    /// Dictionary mapping (path, args) to mock output
    var mockResponses: [String: String] = [:]
    
    /// Recorded calls for verification
    private(set) var recordedCalls: [(path: String, args: [String])] = []
    
    func runShell(_ executablePath: String, _ args: [String] = []) -> String {
        recordedCalls.append((executablePath, args))
        
        // Try exact match first
        let key = "\(executablePath) \(args.joined(separator: " "))"
        if let response = mockResponses[key] {
            return response
        }
        
        // Try path-only match
        if let response = mockResponses[executablePath] {
            return response
        }
        
        return ""
    }
    
    func reset() {
        mockResponses.removeAll()
        recordedCalls.removeAll()
    }
}

/// Utility for safely executing shell commands using explicit paths
struct Shell {
    /// The current shell executor (can be swapped for testing)
    nonisolated(unsafe) static var executor: ShellExecutor = RealShellExecutor()
    
    /// Execute a shell command using explicit path and return its output as a string
    /// - Parameters:
    ///   - executablePath: Full path to the executable (e.g., "/usr/bin/uptime")
    ///   - args: Array of command arguments
    /// - Returns: The command output as a string, or empty string on error
    static func runShell(_ executablePath: String, _ args: [String] = []) -> String {
        return executor.runShell(executablePath, args)
    }
    
    /// Reset to real shell executor (call in tearDown)
    static func resetToRealExecutor() {
        executor = RealShellExecutor()
    }
}
