import Foundation
import ServiceManagement

/// Helper for managing "Start at login" on macOS 13+.
@available(macOS 13.0, *)
enum LaunchAtLoginManager {
    /// Current system status for the main app login item.
    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }
    
    /// True only when the system reports the app is enabled at login.
    static var isEnabled: Bool {
        status == .enabled
    }
    
    /// True when the user must approve in System Settings → Login Items.
    static var requiresApproval: Bool {
        status == .requiresApproval
    }
    
    /// Human-friendly description for UI.
    static var statusDescription: String {
        switch status {
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Needs approval in Login Items"
        case .notRegistered:
            return "Off"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Enable or disable launching at login.
    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

