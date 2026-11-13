import SwiftUI

/// Persistent, read-only broker account telemetry shared by every application destination.
struct BrokerAccountStatusBar: View {
    @EnvironmentObject private var brokerAccountStore: BrokerAccountStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            HStack(spacing: 14) {
                connectionIdentity

                Spacer(minLength: 12)

                if let account = brokerAccountStore.accountSnapshot, !brokerAccountStore.isStale {
                    metric("BALANCE / FUNDS", value: money(account.funds, account: account), tint: AtheerColors.accent)
                    metric("EQUITY", value: money(account.equity, account: account), tint: AtheerColors.info)
                    metric("AVAILABLE", value: money(account.available, account: account), tint: AtheerColors.info)
                    metric("P&L", value: money(account.profitLoss, account: account), tint: pnlColor(account.profitLoss))
                    metric("MARGIN", value: money(account.margin, account: account), tint: AtheerColors.warning)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("FEED")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(AtheerColors.textTertiary)
                        Text(brokerAccountStore.freshnessLabel)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(freshnessColor)
                        Text(ageLabel)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(AtheerColors.textTertiary)
                    }
                } else if brokerAccountStore.accountSnapshot != nil {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("STALE · VALUES WITHHELD", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(AtheerColors.negative)
                        Text(ageLabel)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(AtheerColors.textTertiary)
                    }
                } else {
                    Text(brokerAccountStore.lastSyncError ?? "Waiting for the first broker account snapshot")
                        .font(.system(size: 10))
                        .foregroundColor(AtheerColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(AtheerColors.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AtheerColors.border)
                    .frame(height: 1)
            }
            .textSelection(.enabled)
            .accessibilityElement(children: .contain)
        }
    }

    private var connectionIdentity: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(brokerAccountStore.accountSnapshot?.accountName ?? "CAPITAL.COM")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)
                    .lineLimit(1)

                Text(brokerAccountStore.syncStatus.uppercased())
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(statusColor)
            }
        }
        .frame(minWidth: 100, alignment: .leading)
        .help("Broker account synchronization status")
    }

    private var statusColor: Color {
        if brokerAccountStore.accountSnapshot != nil && brokerAccountStore.isStale { return AtheerColors.negative }
        switch brokerAccountStore.syncStatus {
        case "connected": return AtheerColors.positive
        case "syncing": return AtheerColors.accent
        case "degraded": return AtheerColors.warning
        default: return AtheerColors.textTertiary
        }
    }

    private var freshnessColor: Color {
        switch brokerAccountStore.freshnessLabel {
        case "LIVE": return AtheerColors.positive
        case "DELAYED", "DEGRADED": return AtheerColors.warning
        case "STALE": return AtheerColors.negative
        default: return AtheerColors.textTertiary
        }
    }

    private var ageLabel: String {
        guard brokerAccountStore.lastSuccessfulSyncAt != nil else { return "—" }
        return String(format: "%.1fs", brokerAccountStore.accountSnapshotAge)
    }

    private func pnlColor(_ value: Decimal) -> Color {
        if value > 0 { return AtheerColors.positive }
        if value < 0 { return AtheerColors.negative }
        return AtheerColors.textSecondary
    }

    private func metric(_ title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(AtheerColors.textTertiary)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(brokerAccountStore.isStale ? AtheerColors.warning : tint)
                .lineLimit(1)
        }
        .help(title)
    }

    private func money(_ value: Decimal, account: BrokerAccountSnapshot) -> String {
        let number = NSDecimalNumber(decimal: value).doubleValue
        return "\(account.currencySymbol)\(number.formatted(.number.precision(.fractionLength(2))))"
    }
}
