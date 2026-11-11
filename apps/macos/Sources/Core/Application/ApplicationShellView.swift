import SwiftUI

/// Root navigation container for the native macOS application.
/// Feature views are composed here; domain and execution logic belong in services.
struct ApplicationShellView: View {
    @State private var selection: WorkspaceSection = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(
                    min: 220,
                    ideal: 248,
                    max: 280
                )
        } detail: {
            destinationView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AtheerColors.canvas)
                .navigationTitle(selection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
        .background(AtheerColors.canvas)
    }

    @ViewBuilder
    private var destinationView: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        default:
            DestinationPlaceholderView(section: selection)
        }
    }
}
