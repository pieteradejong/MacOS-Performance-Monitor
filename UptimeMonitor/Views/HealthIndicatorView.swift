import SwiftUI

/// Small reusable view showing color dot, SF Symbol, and severity label
struct HealthIndicatorView: View {
    let status: HealthStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Image(systemName: status.sfSymbol)
                .foregroundColor(status.color)
                .font(.system(size: 12))
            Text(status.label)
                .font(.system(size: 12))
        }
    }
}




