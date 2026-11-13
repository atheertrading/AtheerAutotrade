import SwiftUI

/// Root navigation container for the native macOS application.
/// Feature views are composed here; domain and execution logic belong in services.
struct ApplicationShellView: View {
    @State private var selection: WorkspaceSection = .dashboard
    @StateObject private var workspaceManager = WorkspaceManager()
    @StateObject private var marketDataStore = MarketDataStore.shared
    @StateObject private var brokerAccountStore = BrokerAccountStore.shared

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
        // Owner requirement: selectable text and native Copy must work throughout
        // every application destination, not only in individually patched labels.
        // Editable SwiftUI text controls retain their native Paste behavior.
        .textSelection(.enabled)
        .background(AtheerColors.canvas)
        .environmentObject(marketDataStore)
        .environmentObject(brokerAccountStore)
        .onAppear {
            marketDataStore.startObserving()
            brokerAccountStore.startObserving()
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .tradingWorkspace:
            WorkspaceLayoutView(workspaceManager: workspaceManager)
        case .markets:
            MarketWatchView()
        case .brokers:
            SettingsRootView()
        case .settings:
            SettingsRootView()
        default:
            DestinationPlaceholderView(section: selection)
        }
    }
}


/// Settings owns low-frequency configuration destinations such as broker setup.
/// Broker connectivity is intentionally not a primary workspace destination.
private struct SettingsRootView: View {
    @State private var selectedCategory = "Broker Connections"

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("SETTINGS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(AtheerColors.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.top, 20)

                Button {
                    selectedCategory = "Broker Connections"
                } label: {
                    Label("Broker Connections", systemImage: "building.columns")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            selectedCategory == "Broker Connections"
                                ? AtheerColors.elevated
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
                }
                .buttonStyle(.plain)
                .foregroundColor(AtheerColors.textPrimary)
                .padding(.horizontal, 8)

                Spacer()
            }
            .frame(width: 190)
            .background(AtheerColors.sidebar)

            Rectangle()
                .fill(AtheerColors.border)
                .frame(width: 1)

            CapitalComBrokerView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AtheerColors.canvas)
    }
}
