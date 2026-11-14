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
                    Text("Broker-originated prices, watchlist search, and quote quality")
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

private enum MarketWatchQualityFilter: String, CaseIterable, Identifiable {
    case all, fresh, delayed, degraded, stale, waiting
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All quality states"
        case .fresh: return "Fresh"
        case .delayed: return "Delayed"
        case .degraded: return "Degraded"
        case .stale: return "Stale"
        case .waiting: return "Waiting for quote"
        }
    }
}

private enum MarketWatchSortField: String, CaseIterable, Identifiable {
    case instrument, bid, ask, spread, age, quality
    var id: String { rawValue }

    var title: String {
        switch self {
        case .instrument: return "Instrument"
        case .bid: return "Bid"
        case .ask: return "Ask"
        case .spread: return "Spread"
        case .age: return "Quote age"
        case .quality: return "Quote quality"
        }
    }
}

private enum MarketWatchOptionalColumn: String, CaseIterable, Identifiable {
    case mid, spread, age, quality, market
    var id: String { rawValue }

    var title: String {
        switch self {
        case .mid: return "Mid"
        case .spread: return "Spread"
        case .age: return "Quote age"
        case .quality: return "Quote quality"
        case .market: return "Market status"
        }
    }
}

struct MarketWatchTableView: View {
    @EnvironmentObject private var marketDataStore: MarketDataStore

    var compact = false

    @State private var searchText = ""
    @State private var qualityFilter: MarketWatchQualityFilter = .all
    @State private var sortField: MarketWatchSortField = .instrument
    @State private var sortAscending = true
    @State private var selectedEpics = Set<String>()
    @AppStorage("com.atheertrading.market-watch.visible-columns.v1")
    private var visibleColumnStorage = "mid,spread,age,quality,market"

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Group {
                if compact {
                    compactTable
                } else {
                    professionalTable
                }
            }
        }
        .onChange(of: marketDataStore.watchlist) { instruments in
            selectedEpics.formIntersection(Set(instruments.map(\.epic)))
        }
    }

    private var professionalTable: some View {
        VStack(spacing: 0) {
            tableToolbar

            if marketDataStore.watchlist.isEmpty {
                emptyState(
                    "Your Market Watch is empty",
                    message: "Connect Capital.com Demo, find an instrument in Brokers, and add it to your watchlist."
                )
            } else if displayedInstruments.isEmpty {
                emptyState(
                    "No instruments match this view",
                    message: "Adjust the search term or quote-quality filter to see more instruments."
                )
            } else {
                Table(displayedInstruments, selection: $selectedEpics) {
                    TableColumn("Instrument") { instrument in
                        instrumentIdentity(instrument)
                            .contextMenu {
                                Button {
                                    copyInstrumentDetails(instrument)
                                } label: {
                                    Label("Copy Instrument Details", systemImage: "doc.on.doc")
                                }
                                Button {
                                    copyToPasteboard(instrument.epic)
                                } label: {
                                    Label("Copy Symbol", systemImage: "number")
                                }
                            }
                    }
                    .width(min: 190, ideal: 250)

                    TableColumn("Bid") { instrument in
                        priceText(marketDataStore.quotes[instrument.epic]?.bid)
                    }
                    .width(min: 90, ideal: 105)

                    TableColumn("Ask") { instrument in
                        priceText(marketDataStore.quotes[instrument.epic]?.ask)
                    }
                    .width(min: 90, ideal: 105)

                    TableColumn("Mid") { instrument in
                        priceText(marketDataStore.quotes[instrument.epic]?.mid)
                    }
                    .width(visibleColumns.contains(.mid.rawValue) ? 95 : 0)

                    TableColumn("Spread") { instrument in
                        priceText(marketDataStore.quotes[instrument.epic]?.spread)
                    }
                    .width(visibleColumns.contains(.spread.rawValue) ? 95 : 0)

                    TableColumn("Age") { instrument in
                        ageText(marketDataStore.quotes[instrument.epic])
                    }
                    .width(visibleColumns.contains(.age.rawValue) ? 75 : 0)

                    TableColumn("Quality") { instrument in
                        freshnessText(marketDataStore.quotes[instrument.epic])
                    }
                    .width(visibleColumns.contains(.quality.rawValue) ? 110 : 0)

                    TableColumn("Market") { instrument in
                        Text(instrument.marketStatus)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(AtheerColors.textSecondary)
                            .lineLimit(1)
                    }
                    .width(visibleColumns.contains(.market.rawValue) ? 110 : 0)

                    TableColumn(" ") { instrument in
                        Button(role: .destructive) {
                            marketDataStore.removeInstrument(epic: instrument.epic)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 12))
                                .foregroundColor(AtheerColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove instrument from Market Watch")
                    }
                    .width(42)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .frame(minHeight: 320, maxHeight: .infinity)
            }

            tableFooter
        }
        .background(AtheerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                .stroke(AtheerColors.border, lineWidth: 1)
        }
    }

    private var tableToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AtheerColors.textTertiary)
                TextField("Search name, epic, or type", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .help("Filter the current watchlist by instrument name, epic, or instrument type.")
            }
            .padding(.horizontal, 11)
            .frame(height: 34)
            .frame(minWidth: 190, maxWidth: 310)
            .background(AtheerColors.canvas)
            .overlay {
                RoundedRectangle(cornerRadius: AtheerRadius.small)
                    .stroke(AtheerColors.border, lineWidth: 1)
            }

            Picker("Quality", selection: $qualityFilter) {
                ForEach(MarketWatchQualityFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 150)
            .help("Filter by the current age-based quote-quality classification.")

            Picker("Sort by", selection: $sortField) {
                ForEach(MarketWatchSortField.allCases) { field in
                    Text(field.title).tag(field)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 125)
            .help("Choose the field used to order visible instruments.")

            Button {
                sortAscending.toggle()
            } label: {
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AtheerColors.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(AtheerColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
            }
            .buttonStyle(.plain)
            .help(sortAscending ? "Ascending order" : "Descending order")

            Menu {
                ForEach(MarketWatchOptionalColumn.allCases) { column in
                    Toggle(
                        column.title,
                        isOn: Binding(
                            get: { visibleColumns.contains(column.rawValue) },
                            set: { setColumn(column, visible: $0) }
                        )
                    )
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AtheerColors.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(AtheerColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
            }
            .menuStyle(.borderlessButton)
            .help("Choose which optional Market Watch columns are visible.")

            if hasActiveFilters {
                Button("Clear") {
                    searchText = ""
                    qualityFilter = .all
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AtheerColors.accent)
                .help("Clear search and quality filters.")
            }

            Spacer(minLength: 4)
            Text("\(displayedInstruments.count) / \(marketDataStore.watchlist.count)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(AtheerColors.textSecondary)
                .help("Visible instruments / total watchlist instruments.")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AtheerColors.elevated.opacity(0.55))
    }

    private var tableFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(marketDataStore.streamStatus == "connected" ? AtheerColors.positive : AtheerColors.warning)
                .frame(width: 6, height: 6)
            Text("STREAM \(marketDataStore.streamStatus.uppercased())")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(AtheerColors.textSecondary)
            Spacer()
            Text("Use arrow keys to navigate · Right-click an instrument to copy details")
                .font(.system(size: 9))
                .foregroundColor(AtheerColors.textTertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 13)
        .frame(height: 32)
        .background(AtheerColors.elevated.opacity(0.4))
    }

    private var compactTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("INSTRUMENT").frame(maxWidth: .infinity, alignment: .leading)
                Text("BID").frame(width: 94, alignment: .trailing)
                Text("ASK").frame(width: 94, alignment: .trailing)
                Text("SPREAD").frame(width: 72, alignment: .trailing)
                Text("AGE").frame(width: 54, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(AtheerColors.textTertiary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(AtheerColors.elevated)

            if marketDataStore.watchlist.isEmpty {
                emptyState(
                    "No instruments in Market Watch",
                    message: "Connect Capital.com Demo, open Brokers, search for an instrument, and add it to this watchlist."
                )
            } else {
                ForEach(marketDataStore.watchlist) { instrument in
                    compactInstrumentRow(instrument)
                    if instrument.id != marketDataStore.watchlist.last?.id {
                        Rectangle().fill(AtheerColors.border).frame(height: 1)
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

    private func compactInstrumentRow(_ instrument: MarketWatchInstrument) -> some View {
        let quote = marketDataStore.quotes[instrument.epic]
        return HStack(spacing: 10) {
            instrumentIdentity(instrument).frame(maxWidth: .infinity, alignment: .leading)
            priceText(quote?.bid).frame(width: 94, alignment: .trailing)
            priceText(quote?.ask).frame(width: 94, alignment: .trailing)
            priceText(quote?.spread).frame(width: 72, alignment: .trailing)
            ageText(quote).frame(width: 54, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: 49)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                copyInstrumentDetails(instrument)
            } label: {
                Label("Copy Instrument Details", systemImage: "doc.on.doc")
            }
            Button {
                copyToPasteboard(instrument.epic)
            } label: {
                Label("Copy Symbol", systemImage: "number")
            }
        }
    }

    private var displayedInstruments: [MarketWatchInstrument] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return marketDataStore.watchlist
            .filter { instrument in
                let matchesSearch = term.isEmpty ||
                    instrument.name.localizedCaseInsensitiveContains(term) ||
                    instrument.epic.localizedCaseInsensitiveContains(term) ||
                    instrument.instrumentType.localizedCaseInsensitiveContains(term)

                let quality = marketDataStore.quotes[instrument.epic]?.currentQuality ?? "WAITING"
                let matchesQuality: Bool
                switch qualityFilter {
                case .all: matchesQuality = true
                case .fresh: matchesQuality = quality == "FRESH"
                case .delayed: matchesQuality = quality == "DELAYED"
                case .degraded: matchesQuality = quality == "DEGRADED"
                case .stale: matchesQuality = quality == "STALE"
                case .waiting: matchesQuality = quality == "WAITING" || quality == "UNKNOWN"
                }
                return matchesSearch && matchesQuality
            }
            .sorted(by: isOrderedBefore)
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty || qualityFilter != .all
    }

    private var visibleColumns: Set<String> {
        Set(visibleColumnStorage.split(separator: ",").map(String.init))
    }

    private func setColumn(_ column: MarketWatchOptionalColumn, visible: Bool) {
        var columns = visibleColumns
        if visible {
            columns.insert(column.rawValue)
        } else {
            columns.remove(column.rawValue)
        }
        visibleColumnStorage = columns.sorted().joined(separator: ",")
    }

    private func isOrderedBefore(_ lhs: MarketWatchInstrument, _ rhs: MarketWatchInstrument) -> Bool {
        let left = marketDataStore.quotes[lhs.epic]
        let right = marketDataStore.quotes[rhs.epic]
        switch sortField {
        case .instrument:
            let result = lhs.name.localizedStandardCompare(rhs.name)
            if result == .orderedSame {
                return lhs.epic.localizedStandardCompare(rhs.epic) == .orderedAscending
            }
            return sortAscending ? result == .orderedAscending : result == .orderedDescending
        case .bid:
            return optionalNumberOrder(left?.bid, right?.bid, lhs: lhs, rhs: rhs)
        case .ask:
            return optionalNumberOrder(left?.ask, right?.ask, lhs: lhs, rhs: rhs)
        case .spread:
            return optionalNumberOrder(left?.spread, right?.spread, lhs: lhs, rhs: rhs)
        case .age:
            return optionalNumberOrder(left?.ageMilliseconds, right?.ageMilliseconds, lhs: lhs, rhs: rhs)
        case .quality:
            let result = (left?.currentQuality ?? "WAITING").localizedStandardCompare(right?.currentQuality ?? "WAITING")
            if result == .orderedSame {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return sortAscending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    // Missing quotes remain last in either direction; broker observations are never fabricated.
    private func optionalNumberOrder(
        _ left: Double?,
        _ right: Double?,
        lhs: MarketWatchInstrument,
        rhs: MarketWatchInstrument
    ) -> Bool {
        switch (left, right) {
        case (nil, nil):
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        case (nil, .some):
            return false
        case (.some, nil):
            return true
        case let (.some(leftValue), .some(rightValue)):
            if leftValue == rightValue {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return sortAscending ? leftValue < rightValue : leftValue > rightValue
        }
    }

    private func instrumentIdentity(_ instrument: MarketWatchInstrument) -> some View {
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

    private func copyInstrumentDetails(_ instrument: MarketWatchInstrument) {
        let quote = marketDataStore.quotes[instrument.epic]
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

    private func emptyState(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)
            Text(message)
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
