
import SwiftUI

/// Renders an individual workspace panel.
///
/// This view is presentation-only.
/// It does not access market data, broker services, risk controls,
/// automation services, or order execution.
struct WorkspacePanelView: View {

    let panel: WorkspacePanel

    let onHide: () -> Void
    let onClose: () -> Void
    let onToggleMaximize: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            panelHeader

            Rectangle()
                .fill(AtheerColors.border)
                .frame(height: 1)

            panelContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AtheerColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 9,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 9,
                style: .continuous
            )
            .stroke(AtheerColors.border, lineWidth: 1)
        }
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: panelSymbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AtheerColors.accent)

            Text(panel.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            panelActionButton(
                symbol: panel.isMaximized
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right",
                help: panel.isMaximized
                    ? "Restore Panel"
                    : "Maximize Panel",
                action: onToggleMaximize
            )

            panelActionButton(
                symbol: "eye.slash",
                help: "Hide Panel",
                action: onHide
            )

            panelActionButton(
                symbol: "xmark",
                help: "Close Panel",
                action: onClose
            )
        }
        .padding(.horizontal, 12)
        .frame(height: 39)
        .background(AtheerColors.elevated)
    }

    private func panelActionButton(
        symbol: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AtheerColors.textSecondary)
                .frame(width: 23, height: 23)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Panel Content

    @ViewBuilder
    private var panelContent: some View {
        switch panel.kind {

        case .chart:
            emptyState(
                symbol: "chart.xyaxis.line",
                title: "Chart Workspace",
                message: "Capital.com market data is connected. Interactive chart rendering and historical-series integration are not implemented yet."
            )

        case .marketWatch:
            MarketWatchTableView(compact: true)

        case .orderEntry:
            emptyState(
                symbol: "arrow.left.arrow.right",
                title: "Order Entry",
                message: "Capital.com market data is connected, but order submission is not implemented. No broker dealing endpoint is exposed."
            )

        case .positions:
            emptyState(
                symbol: "rectangle.stack",
                title: "Positions",
                message: "Broker account and position snapshots are not yet displayed in this workspace panel."
            )

        case .orders:
            emptyState(
                symbol: "list.bullet",
                title: "Orders",
                message: "Order lifecycle monitoring is not implemented yet. This panel cannot create or submit broker orders."
            )

        case .news:
            emptyState(
                symbol: "newspaper",
                title: "Market News",
                message: "A news data provider has not been configured."
            )

        case .history:
            emptyState(
                symbol: "clock.arrow.circlepath",
                title: "Trade History",
                message: "Historical execution records are not available."
            )

        case .journal:
            emptyState(
                symbol: "book.closed",
                title: "Trading Journal",
                message: "Journal entries will appear here when the journal service is implemented."
            )

        case .performance:
            emptyState(
                symbol: "chart.bar.xaxis",
                title: "Performance",
                message: "Performance analytics require verified account and execution records."
            )

        case .systemStatus:
            emptyState(
                symbol: "server.rack",
                title: "System Status",
                message: "Application service diagnostics are not connected."
            )
        }
    }

    // MARK: - Empty State

    private func emptyState(
        symbol: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 23, weight: .light))
                .foregroundColor(AtheerColors.textSecondary.opacity(0.75))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)

            Text(message)
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 330)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtheerColors.surface)
    }

    // MARK: - Panel Metadata

    private var panelSymbol: String {
        switch panel.kind {
        case .chart:
            return "chart.xyaxis.line"
        case .marketWatch:
            return "list.bullet.rectangle"
        case .orderEntry:
            return "arrow.left.arrow.right"
        case .positions:
            return "rectangle.stack"
        case .orders:
            return "list.bullet"
        case .news:
            return "newspaper"
        case .history:
            return "clock.arrow.circlepath"
        case .journal:
            return "book.closed"
        case .performance:
            return "chart.bar.xaxis"
        case .systemStatus:
            return "server.rack"
        }
    }
}

