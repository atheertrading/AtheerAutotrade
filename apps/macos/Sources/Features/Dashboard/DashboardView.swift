import Combine
import SwiftUI

/// Operational dashboard for the ATHEER Trading Pro macOS workstation.
///
/// Data integrity rule: account values and operational events are never fabricated.
/// A missing service is presented as unavailable until a typed, authoritative
/// snapshot is connected to this view.
struct DashboardView: View {
    @EnvironmentObject private var marketDataStore: MarketDataStore

    private let statusColumns = [
        GridItem(.adaptive(minimum: 220), spacing: 14, alignment: .top)
    ]
    private let accountRefreshTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    private var isStreaming: Bool {
        marketDataStore.streamStatus == "connected"
    }

    private var marketFeedDescription: String {
        if let error = marketDataStore.streamError, !error.isEmpty {
            return error
        }
        if isStreaming {
            return "\(marketDataStore.quotes.count) quoted / \(marketDataStore.watchlist.count) watched instruments"
        }
        if marketDataStore.isBrokerConnected {
            return "Broker session authenticated; quote stream is not confirmed."
        }
        return "Connect Capital.com Demo to begin receiving broker prices."
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    accountOverview
                    marketWatchSection
                    operationalStatusSection
                    activitySection
                }
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .topLeading)
            }
            .background(AtheerColors.canvas)
        }
        .background(AtheerColors.canvas)
        .textSelection(.enabled)
        .onAppear {
            marketDataStore.refreshAccountSnapshot()
        }
        .onReceive(accountRefreshTimer) { _ in
            marketDataStore.refreshAccountSnapshot()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Trading Dashboard")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)

                Text("Account overview, market activity and system readiness")
                    .font(.system(size: 13))
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Circle()
                    .fill(isStreaming ? AtheerColors.positive : AtheerColors.warning)
                    .frame(width: 7, height: 7)
                Text(isStreaming ? "MARKET FEED ACTIVE" : "MARKET FEED INACTIVE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(AtheerColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(AtheerColors.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AtheerColors.border, lineWidth: 1))
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Account Overview

    private var accountOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                title: "Account Overview",
                subtitle: "Capital.com account snapshot · read-only"
            )

            if let account = marketDataStore.accountSnapshot {
                LazyVGrid(columns: statusColumns, alignment: .leading, spacing: 14) {
                    AccountMetricPanel(
                        title: "FUNDS / BALANCE",
                        symbol: "creditcard",
                        value: formatMoney(account.funds, account: account),
                        detail: "Broker field: balance.balance"
                    )
                    AccountMetricPanel(
                        title: "AVAILABLE",
                        symbol: "wallet.bifold",
                        value: formatMoney(account.available, account: account),
                        detail: "Funds currently available for new positions"
                    )
                    AccountMetricPanel(
                        title: "EQUITY",
                        symbol: "chart.line.uptrend.xyaxis",
                        value: formatMoney(account.equity, account: account),
                        detail: "Calculated as Funds + running P&L"
                    )
                    AccountMetricPanel(
                        title: "P&L",
                        symbol: "chart.xyaxis.line",
                        value: formatMoney(account.profitLoss, account: account),
                        detail: "Running profit / loss on open positions"
                    )
                    AccountMetricPanel(
                        title: "MARGIN",
                        symbol: "gauge.with.dots.needle.67percent",
                        value: formatMoney(account.margin, account: account),
                        detail: "Broker field: balance.deposit"
                    )
                    AccountMetricPanel(
                        title: "MARGIN LEVEL",
                        symbol: "speedometer",
                        value: account.marginLevel.map { String(format: "%.1f%%", $0) } ?? "—",
                        detail: "Calculated as Equity ÷ Margin"
                    )
                }

                Text("Account: \(account.accountName) · \(account.currency) · \(account.status) · Observed: \(account.observedAt)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AtheerColors.textTertiary)
                    .textSelection(.enabled)
            } else {
                AccountMetricPanel(
                    title: "ACCOUNT DATA",
                    symbol: "building.columns",
                    value: "—",
                    detail: marketDataStore.accountSnapshotError
                        ?? (marketDataStore.isRefreshingAccount
                            ? "Refreshing broker account snapshot…"
                            : "Connect Capital.com Demo to load account metrics.")
                )
            }
        }
    }

    // MARK: - Market Watch

    private var marketWatchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeading(
                    title: "Market Watch",
                    subtitle: "Live broker Bid / Ask observations"
                )
                Spacer()
                Text("\(marketDataStore.watchlist.count) INSTRUMENTS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(AtheerColors.textTertiary)
            }

            MarketWatchTableView(compact: true)

            HStack(spacing: 7) {
                Circle()
                    .fill(isStreaming ? AtheerColors.positive : AtheerColors.warning)
                    .frame(width: 6, height: 6)
                Text(marketFeedDescription)
                    .font(.system(size: 11))
                    .foregroundColor(AtheerColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Operational Status

    private var operationalStatusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                title: "Operational Status",
                subtitle: "Service state is shown separately from trading authorization"
            )

            LazyVGrid(columns: statusColumns, alignment: .leading, spacing: 14) {
                OperationalStatusPanel(
                    title: "CAPITAL.COM",
                    symbol: "building.2",
                    value: marketDataStore.isBrokerConnected ? "Demo connected" : "Disconnected",
                    detail: marketDataStore.isBrokerConnected
                        ? "Broker session is authenticated."
                        : "No authenticated broker session is available.",
                    tint: marketDataStore.isBrokerConnected ? AtheerColors.positive : AtheerColors.warning
                )

                OperationalStatusPanel(
                    title: "MARKET DATA",
                    symbol: "waveform.path.ecg",
                    value: isStreaming ? "Streaming" : "Not streaming",
                    detail: marketFeedDescription,
                    tint: isStreaming ? AtheerColors.positive : AtheerColors.warning
                )

                OperationalStatusPanel(
                    title: "AUTOMATED EXECUTION",
                    symbol: "shield.lefthalf.filled",
                    value: "Disabled",
                    detail: "OMS, mandatory RiskEngine authorization and execution controls are not yet integrated.",
                    tint: AtheerColors.warning
                )

                OperationalStatusPanel(
                    title: "LOCAL DATABASE",
                    symbol: "externaldrive",
                    value: "Not connected",
                    detail: "The local PostgreSQL runtime and application repositories are not yet integrated.",
                    tint: AtheerColors.warning
                )
            }
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                title: "System Activity",
                subtitle: "Timestamped operational and audit events"
            )

            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(AtheerColors.textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity stream is not connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AtheerColors.textPrimary)
                    Text("This panel will display broker, market-data, risk and order lifecycle events when the event journal is integrated.")
                        .font(.system(size: 11))
                        .foregroundColor(AtheerColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AtheerColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                    .stroke(AtheerColors.border, lineWidth: 1)
            }
        }
    }

    // MARK: - Shared Components

    private func formatMoney(_ value: Double, account: BrokerAccountSnapshot) -> String {
        "\(account.symbol)\(value.formatted(.number.precision(.fractionLength(2))))"
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textTertiary)
        }
    }
}

private struct AccountMetricPanel: View {
    let title: String
    let symbol: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AtheerColors.accent)
                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Text(value)
                .font(.system(size: 25, weight: .medium, design: .rounded))
                .foregroundColor(AtheerColors.textPrimary)

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(AtheerColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background(AtheerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                .stroke(AtheerColors.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct OperationalStatusPanel: View {
    let title: String
    let symbol: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundColor(AtheerColors.textTertiary)

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)

                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(AtheerColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(AtheerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                .stroke(AtheerColors.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
