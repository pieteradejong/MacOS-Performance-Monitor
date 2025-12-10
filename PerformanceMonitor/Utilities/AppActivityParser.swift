import Foundation

/// Parser for app activity information
struct AppActivityParser {
    /// App activity information
    struct AppActivity {
        let activeAppsCount: Int
        let heavyAppsCount: Int
    }
    
    /// Get app activity statistics
    /// - Returns: AppActivity with counts of active and heavy apps
    static func getAppActivity() -> AppActivity {
        // Use ps to count running applications
        // Count processes that are user applications (not system processes)
        let psOutput = Shell.runShell("/bin/ps", ["-eo", "pid,pcpu,pmem,comm"])
        let lines = psOutput.components(separatedBy: .newlines)
        
        var activeApps = Set<String>()
        var heavyApps = 0
        
        // Skip header line
        for line in lines.dropFirst() {
            let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
            guard components.count >= 4 else { continue }
            
            guard let cpuPercent = Double(components[1]),
                  let memPercent = Double(components[2]) else {
                continue
            }
            
            let processName = components[3]
            
            // Filter out system processes (kernel, launchd, etc.)
            if isUserApp(processName) {
                activeApps.insert(processName)
                
                // Consider app "heavy" if CPU > 50% or memory > 5%
                if cpuPercent > 50.0 || memPercent > 5.0 {
                    heavyApps += 1
                }
            }
        }
        
        return AppActivity(
            activeAppsCount: activeApps.count,
            heavyAppsCount: heavyApps
        )
    }
    
    /// Check if a process name represents a user application
    private static func isUserApp(_ processName: String) -> Bool {
        // Filter out system processes
        let systemProcesses = [
            "kernel_task", "launchd", "mds", "mdworker", "WindowServer",
            "com.apple", "kernel", "kextd", "fseventsd", "distnoted"
        ]
        
        let lowerName = processName.lowercased()
        for sysProc in systemProcesses {
            if lowerName.contains(sysProc.lowercased()) {
                return false
            }
        }
        
        // If it's an .app bundle name or common user apps
        return true
    }
}
