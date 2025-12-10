import SwiftUI
import AppKit

/// Main content view displayed in the menu bar dropdown
struct MenuContentView: View {
    @ObservedObject var monitor: SystemMonitor
    @State private var selectedTab: TabSelection = .overview
    
    enum TabSelection {
        case overview
        case dev
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(TabSelection.overview)
                Text("Dev").tag(TabSelection.dev)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tab content
            if selectedTab == .overview {
                OverviewTabView(monitor: monitor)
            } else {
                DevTabView(monitor: monitor)
            }
        }
    }
}




