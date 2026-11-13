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

            Text("Execution sides are fixed: SELL / BID is red and BUY / ASK is green. Directional movement is shown separately in the delta columns. Mid and Spread are derived values, not executable prices.")
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
            Text("SELL / BID").foregroundColor(AtheerColors.negative).frame(width: 82, alignment: .trailing)
            Text("BUY / ASK").foregroundColor(AtheerColors.positive).frame(width: 82, alignment: .trailing)
            Text("Δ PX").frame(width: 72, alignment: .trailing)
            Text("Δ %").frame(width: 58, alignment: .trailing)
            Text("TICKS").frame(width: 52, alignment: .trailing)
            Text("1M VOL").frame(width: 48, alignment: .trailing)
            if !compact {
                Text("MID").frame(width: 76, alignment: .trailing)
                Text("SPREAD").frame(width: 72, alignment: .trailing)
                Text("AGE").frame(width: 54, alignment: .trailing)
                Text("STATUS").frame(width: 76, alignment: .trailing)
                Color.clear.frame(width: 22)
            } else {
                Text("SPREAD").frame(width: 66, alignment: .trailing)
                Text("AGE").frame(width: 50, alignment: .trailing)
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
        let liveQuote = quote?.currentQuality == "FRESH" ? quote : nil
        // Execution-side semantics are invariant: SELL/BID is red; BUY/ASK is green.
        // Quote direction is communicated separately in the delta columns.
        // Delayed/degraded/stale quotes are withheld from executable-price cells.

        return HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: instrumentSymbol(instrument.instrumentType))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AtheerColors.accent)
                    .frame(width: 20)
                    .accessibilityHidden(true)

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
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            priceText(liveQuote?.bid, tint: AtheerColors.negative).frame(width: 82, alignment: .trailing)
            priceText(liveQuote?.ask, tint: AtheerColors.positive).frame(width: 82, alignment: .trailing)
            movementText(liveQuote?.changeFromPrevious, percent: false).frame(width: 72, alignment: .trailing)
            movementText(liveQuote?.changePercentFromPrevious, percent: true).frame(width: 58, alignment: .trailing)
            tickText(instrument, quote: liveQuote).frame(width: 52, alignment: .trailing)
            volumeText().frame(width: 48, alignment: .trailing)

            if !compact {
                priceText(liveQuote?.mid, tint: movementColor(liveQuote?.changeFromPrevious)).frame(width: 76, alignment: .trailing)
                priceText(liveQuote?.spread, tint: AtheerColors.info).frame(width: 72, alignment: .trailing)
                ageText(quote).frame(width: 54, alignment: .trailing)
                freshnessText(quote).frame(width: 76, alignment: .trailing)

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
                priceText(liveQuote?.spread, tint: AtheerColors.info).frame(width: 66, alignment: .trailing)
                ageText(quote).frame(width: 50, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 49)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("No instruments in Market Watch")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)
            Text("Open Settings → Broker Connections, connect Capital.com Demo, search for an instrument, and add it to this watchlist.")
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
    }

    private func movementColor(_ value: Double?) -> Color {
        guard let value else { return AtheerColors.textPrimary }
        if value > 0 { return AtheerColors.positive }
        if value < 0 { return AtheerColors.negative }
        return AtheerColors.textSecondary
    }

    private func priceText(_ value: Double?, tint: Color = AtheerColors.textPrimary) -> some View {
        Text(value.map { $0.formatted(.number.precision(.fractionLength(2...6))) } ?? "—")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .textSelection(.enabled)
    }

    private func movementText(_ value: Double?, percent: Bool) -> some View {
        let tint = movementColor(value)
        let label: String
        if let value {
            let marker = value > 0 ? "▲ " : (value < 0 ? "▼ " : "")
            let prefix = value > 0 ? "+" : ""
            label = marker + prefix + value.formatted(.number.precision(.fractionLength(2...4))) + (percent ? "%" : "")
        } else {
            label = "—"
        }

        return Text(label)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(tint)
            .lineLimit(1)
            .help("Quote-to-quote movement only; hidden until consecutive fresh broker quotes are available.")
    }

    private func tickText(_ instrument: MarketWatchInstrument, quote: MarketQuoteSnapshot?) -> some View {
        let ticks: String
        if let change = quote?.changeFromPrevious, let tickSize = instrument.tickSize, tickSize > 0 {
            ticks = String(format: "%.1f", change / tickSize)
        } else {
            ticks = "—"
        }

        return Text(ticks)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(AtheerColors.textSecondary)
            .help("Fresh quote-to-quote movement divided by the broker-provided tickSize.")
    }

    private func volumeText() -> some View {
        Text("—")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(AtheerColors.textTertiary)
            .help("Capital.com quote streaming supplies Bid/Ask quantities, not traded volume. One-minute traded volume requires the historical candle endpoint and is not yet integrated.")
    }

    private func instrumentSymbol(_ instrumentType: String) -> String {
        switch instrumentType.uppercased() {
        case "CURRENCIES": return "arrow.left.arrow.right"
        case "INDICES": return "chart.xyaxis.line"
        case "COMMODITIES": return "cube"
        case "SHARES": return "building.2"
        case "CRYPTOCURRENCIES": return "bitcoinsign.circle"
        default: return "chart.line.uptrend.xyaxis"
        }
    }

    private func ageText(_ quote: MarketQuoteSnapshot?) -> some View {
        let tint: Color
        switch quote?.currentQuality {
        case "FRESH": tint = AtheerColors.positive
        case "DELAYED", "DEGRADED": tint = AtheerColors.warning
        case "STALE": tint = AtheerColors.negative
        default: tint = AtheerColors.textTertiary
        }
        return Text(quote?.ageLabel ?? "—")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(tint)
            .lineLimit(1)
            .textSelection(.enabled)
            .help(quote.map { String(format: "Broker timestamp to backend receipt: %.1f ms (uncalibrated clock delta). Backend receipt to ATHEER IPC receipt: %.1f ms.", $0.sourceToBackendMilliseconds, $0.backendToClientMilliseconds) } ?? "Waiting for a broker quote.")
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
