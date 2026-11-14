import AppKit
import SwiftUI

struct MarketWatchView: View {
    @EnvironmentObject private var marketDataStore: MarketDataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Market Watch")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(AtheerColors.textPrimary)
                    Text("Live broker Bid/Ask observations and quote freshness")
                        .font(.system(size: 12))
                        .foregroundColor(AtheerColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CAPITAL.COM · DEMO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(AtheerColors.accent)
                    Text(marketDataStore.streamStatus.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(marketDataStore.streamStatus == "connected" ? AtheerColors.positive : AtheerColors.warning)
                }
            }

            MarketWatchTableView()

            Text("Execution reference: Capital.com Bid/Ask. Mid and Spread are derived values; they are not substitutes for executable prices.")
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textTertiary)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AtheerColors.canvas)
    }
}

struct MarketWatchTableView: View {
    @EnvironmentObject private var marketDataStore: MarketDataStore

    var compact = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(spacing: 0) {
                headerRow

                if marketDataStore.watchlist.isEmpty {
                    emptyState
                } else {
                    ForEach(marketDataStore.watchlist) { instrument in
                        instrumentRow(instrument)
                        if instrument.id != marketDataStore.watchlist.last?.id {
                            Rectangle()
                                .fill(AtheerColors.border)
                                .frame(height: 1)
                        }
                    }
                }
            }
            .background(AtheerColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                    .stroke(AtheerColors.border, lineWidth: 1)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Text("INSTRUMENT").frame(maxWidth: .infinity, alignment: .leading)
            Text("BID").frame(width: 94, alignment: .trailing)
            Text("ASK").frame(width: 94, alignment: .trailing)
            if !compact {
                Text("MID").frame(width: 78, alignment: .trailing)
                Text("SPREAD").frame(width: 78, alignment: .trailing)
                Text("AGE").frame(width: 58, alignment: .trailing)
                Text("STATUS").frame(width: 82, alignment: .trailing)
                Color.clear.frame(width: 22)
            } else {
                Text("SPREAD").frame(width: 72, alignment: .trailing)
                Text("AGE").frame(width: 54, alignment: .trailing)
            }
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .foregroundColor(AtheerColors.textTertiary)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(AtheerColors.elevated)
    }

    private func instrumentRow(_ instrument: MarketWatchInstrument) -> some View {
        let quote = marketDataStore.quotes[instrument.epic]

        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(instrument.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)
                    .lineLimit(1)
                Text(instrument.epic)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(AtheerColors.textTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            priceText(quote?.bid).frame(width: 94, alignment: .trailing)
            priceText(quote?.ask).frame(width: 94, alignment: .trailing)

            if !compact {
                priceText(quote?.mid).frame(width: 78, alignment: .trailing)
                priceText(quote?.spread).frame(width: 78, alignment: .trailing)
                ageText(quote).frame(width: 58, alignment: .trailing)
                freshnessText(quote).frame(width: 82, alignment: .trailing)

                Button {
                    marketDataStore.removeInstrument(epic: instrument.epic)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(AtheerColors.textTertiary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Remove instrument from Market Watch")
            } else {
                priceText(quote?.spread).frame(width: 72, alignment: .trailing)
                ageText(quote).frame(width: 54, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 49)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Copy Instrument Details", systemImage: "doc.on.doc") {
                copyInstrumentDetails(instrument, quote: quote)
            }
            Button("Copy Symbol", systemImage: "number") {
                copyToPasteboard(instrument.epic)
            }
        }
    }

    private func copyInstrumentDetails(
        _ instrument: MarketWatchInstrument,
        quote: MarketQuoteSnapshot?
    ) {
        let details = [
            "Instrument: \(instrument.name)",
            "Epic: \(instrument.epic)",
            "Type: \(instrument.instrumentType)",
            "Market status: \(instrument.marketStatus)",
            "Bid: \(quote.map { String($0.bid) } ?? "—")",
            "Ask: \(quote.map { String($0.ask) } ?? "—")",
            "Mid: \(quote.map { String($0.mid) } ?? "—")",
            "Spread: \(quote.map { String($0.spread) } ?? "—")",
            "Quote age: \(quote?.ageLabel ?? "—")",
            "Quality: \(quote?.currentQuality ?? "WAITING")"
        ].joined(separator: "\n")
        copyToPasteboard(details)
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("No instruments in Market Watch")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)
            Text("Connect Capital.com Demo, open Brokers, search for an instrument, and add it to this watchlist.")
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
    }

    private func priceText(_ value: Double?) -> some View {
        Text(value.map { $0.formatted(.number.precision(.fractionLength(2...6))) } ?? "—")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(AtheerColors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .textSelection(.enabled)
    }

    private func ageText(_ quote: MarketQuoteSnapshot?) -> some View {
        Text(quote?.ageLabel ?? "—")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(AtheerColors.textSecondary)
            .lineLimit(1)
            .textSelection(.enabled)
    }

    private func freshnessText(_ quote: MarketQuoteSnapshot?) -> some View {
        let quality = quote?.currentQuality ?? "WAITING"
        let tint: Color
        switch quality {
        case "FRESH": tint = AtheerColors.positive
        case "DELAYED", "DEGRADED": tint = AtheerColors.warning
        case "STALE": tint = AtheerColors.negative
        default: tint = AtheerColors.textTertiary
        }

        return Text(quality)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .textSelection(.enabled)
    }
}
