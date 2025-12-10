import SwiftUI

/// Health status enum representing system health levels
enum HealthStatus {
    case ok
    case warning
    case critical
    
    /// Color representation for the health status
    var color: Color {
        switch self {
        case .ok:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }
    
    /// SF Symbol name for the health status
    var sfSymbol: String {
        switch self {
        case .ok:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }
    
    /// Short label for the health status
    var label: String {
        switch self {
        case .ok:
            return "OK"
        case .warning:
            return "Warning"
        case .critical:
            return "Restart Recommended"
        }
    }
    
    /// Detailed explanation of the health status
    var explanation: String {
        switch self {
        case .ok:
            return "System is running normally"
        case .warning:
            return "Consider monitoring system resources"
        case .critical:
            return "System restart recommended for optimal performance"
        }
    }
}




