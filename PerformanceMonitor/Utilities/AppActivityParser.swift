import Foundation

/// Parser for app activity information
struct AppActivityParser {
    /// App activity information
    struct AppActivity {
        let activeAppsCount: Int
        let heavyAppsCount: Int
        let topDrainers: [ProcessUsage]
        
        init(activeAppsCount: Int, heavyAppsCount: Int, topDrainers: [ProcessUsage] = []) {
            self.activeAppsCount = activeAppsCount
            self.heavyAppsCount = heavyAppsCount
            self.topDrainers = topDrainers
        }
    }
    
    /// Get app activity statistics
    /// - Returns: AppActivity with counts of active and heavy apps
    static func getAppActivity(topLimit: Int = 6) -> AppActivity {
        // Use ps to count running applications
        // Count processes that are user applications (not system processes)
        let psOutput = Shell.runShell("/bin/ps", ["-eo", "pid,pcpu,pmem,comm"])
        let lines = psOutput.components(separatedBy: .newlines)
        
        var activeApps = Set<String>()
        var heavyApps = Set<String>()
        var drainers: [ProcessUsage] = []
        
        // Skip header line
        for line in lines.dropFirst() {
            let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
            guard components.count >= 4 else { continue }
            
            guard let pid = Int(components[0]),
                  let cpuPercent = Double(components[1]),
                  let memPercent = Double(components[2]) else {
                continue
            }
            
            let processName = components[3]
            
            // Filter out system processes (kernel, launchd, etc.)
            if isUserApp(processName) {
                activeApps.insert(processName)
                
                // Consider app "heavy" if CPU > 50% or memory > 5%
                if cpuPercent > 50.0 || memPercent > 5.0 {
                    heavyApps.insert(processName)
                }
                
                drainers.append(
                    ProcessUsage(
                        pid: pid,
                        name: processName,
                        cpuPercent: cpuPercent,
                        memPercent: memPercent
                    )
                )
            }
        }
        
        let topDrainers = drainers
            .sorted { lhs, rhs in
                if lhs.drainScore != rhs.drainScore { return lhs.drainScore > rhs.drainScore }
                if lhs.cpuPercent != rhs.cpuPercent { return lhs.cpuPercent > rhs.cpuPercent }
                return lhs.memPercent > rhs.memPercent
            }
            .prefix(max(0, topLimit))
            .map { $0 }
        
        return AppActivity(
            activeAppsCount: activeApps.count,
            heavyAppsCount: heavyApps.count,
            topDrainers: topDrainers
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
