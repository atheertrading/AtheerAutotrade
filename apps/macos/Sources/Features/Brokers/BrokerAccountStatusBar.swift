import SwiftUI

/// Persistent, read-only broker account strip shared by every application destination.
struct BrokerAccountStatusBar: View {
    @EnvironmentObject private var brokerAccountStore: BrokerAccountStore

    var body: some View {
        HStack(spacing: 14) {
            connectionIdentity

            Spacer(minLength: 12)

            if let account = brokerAccountStore.accountSnapshot {
                metric("FUNDS", value: money(account.funds, account: account))
                metric("EQUITY", value: money(account.equity, account: account))
                metric("AVAILABLE", value: money(account.available, account: account))
                metric("P&L", value: money(account.profitLoss, account: account))
                metric("MARGIN", value: money(account.margin, account: account))
            } else {
                Text(brokerAccountStore.lastSyncError ?? "Waiting for the first broker account snapshot")
                    .font(.system(size: 10))
                    .foregroundColor(AtheerColors.textTertiary)
                    .lineLimit(1)
            }

            if brokerAccountStore.accountSnapshot != nil && brokerAccountStore.isStale {
                Label("STALE", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AtheerColors.warning)
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
                    .foregroundColor(AtheerColors.textTertiary)
            }
        }
        .frame(minWidth: 100, alignment: .leading)
        .help("Broker account synchronization status")
    }

    private var statusColor: Color {
        switch brokerAccountStore.syncStatus {
        case "connected": return AtheerColors.positive
        case "syncing": return AtheerColors.accent
        case "degraded": return AtheerColors.warning
        default: return AtheerColors.textTertiary
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(AtheerColors.textTertiary)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AtheerColors.textPrimary)
                .lineLimit(1)
        }
        .help(title)
    }

    private func money(_ value: Decimal, account: BrokerAccountSnapshot) -> String {
        let number = NSDecimalNumber(decimal: value).doubleValue
        return "\(account.currencySymbol)\(number.formatted(.number.precision(.fractionLength(2))))"
    }
}
