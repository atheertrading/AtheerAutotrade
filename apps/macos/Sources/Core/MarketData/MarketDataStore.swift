import Combine
import Foundation

struct MarketWatchInstrument: Codable, Hashable, Identifiable {
    let epic: String
    let name: String
    let instrumentType: String
    let marketStatus: String
    var netChange: Double? = nil
    var percentageChange: Double? = nil
    var tickSize: Double? = nil
    var lastTradedVolume: Double? = nil

    var id: String { epic }
}

struct BrokerAccountSnapshot {
    let accountName: String
    let status: String
    let currency: String
    let symbol: String
    let funds: Double
    let margin: Double
    let profitLoss: Double
    let available: Double
    let observedAt: String

    var equity: Double { funds + profitLoss }

    var marginLevel: Double? {
        guard margin > 0 else { return nil }
        return equity / margin * 100
    }
}

struct MarketQuoteSnapshot: Identifiable {
    let epic: String
    let bid: Double
    let ask: Double
    let mid: Double
    let spread: Double
    let previousMid: Double?
    let brokerTimestamp: Double
    let receivedAt: Double
    let qualityAtReceipt: String

    var id: String { epic }

    /// Quote-to-quote movement only; this is not a session/day change.
    var changeFromPrevious: Double? {
        guard let previousMid else { return nil }
        return mid - previousMid
    }

    var changePercentFromPrevious: Double? {
        guard let previousMid, previousMid > 0 else { return nil }
        return (mid - previousMid) / previousMid * 100
    }

    var ageMilliseconds: Double {
        Date().timeIntervalSince1970 * 1_000 - brokerTimestamp
    }

    var currentQuality: String {
        let age = ageMilliseconds
        guard age >= 0 else { return "UNKNOWN" }
        if age <= 5_000 { return "FRESH" }
        if age <= 10_000 { return "DELAYED" }
        if age <= 15_000 { return "DEGRADED" }
        return "STALE"
    }

    var ageLabel: String {
        let age = ageMilliseconds
        guard age >= 0 else { return "CLOCK" }
        let seconds = age / 1_000
        return seconds < 10
            ? String(format: "%.1fs", seconds)
            : String(format: "%.0fs", seconds)
    }
}

/// Presentation-side market watch state. Broker events remain owned by the backend;
/// this store only retains the user's watchlist and renders received observations.
final class MarketDataStore: ObservableObject {
    static let shared = MarketDataStore()

    @Published private(set) var watchlist: [MarketWatchInstrument] = []
    @Published private(set) var quotes: [String: MarketQuoteSnapshot] = [:]
    @Published private(set) var streamStatus = "stopped"
    @Published private(set) var isBrokerConnected = false
    @Published private(set) var streamError: String?
    @Published private(set) var accountSnapshot: BrokerAccountSnapshot?
    @Published private(set) var accountSnapshotError: String?
    @Published private(set) var isRefreshingAccount = false

    private let persistenceKey = "com.atheertrading.market-watch.v1"
    private var isObserving = false
    private var isStartingStream = false

    // Market Watch is a presentation consumer: retain the newest quote per epic
    // and publish batches at a bounded rate instead of flooding the main queue.
    private let quoteBufferLock = NSLock()
    private var pendingQuotePayloads: [String: [String: Any]] = [:]
    private var quoteFlushScheduled = false

    private init() {
        restoreWatchlist()
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        BackendProcessSupervisor.shared.setEventHandler { [weak self] name, payload in
            guard let self else { return }

            if name == "broker.marketData.quote" {
                self.enqueueQuote(payload)
            } else {
                DispatchQueue.main.async {
                    self.consume(event: name, payload: payload)
                }
            }
        }
    }

    func contains(epic: String) -> Bool {
        watchlist.contains { $0.epic == epic }
    }

    func setBrokerConnectionState(_ connected: Bool) {
        isBrokerConnected = connected
        if connected {
            refreshAccountSnapshot()
        } else {
            accountSnapshot = nil
            accountSnapshotError = nil
            isRefreshingAccount = false
        }
    }

    /// Reads the broker's authoritative, read-only account snapshot over IPC.
    /// Capital.com defines balance.balance as Funds, deposit as Margin,
    /// profitLoss as running P&L, and available as Available Funds.
    func refreshAccountSnapshot() {
        guard isBrokerConnected, !isRefreshingAccount else { return }
        isRefreshingAccount = true

        BackendProcessSupervisor.shared.request(
            method: "broker.accounts",
            payload: [:],
            timeout: 15
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isRefreshingAccount = false

                switch result {
                case .failure(let error):
                    self.accountSnapshotError = error.localizedDescription
                case .success(let payload):
                    guard
                        let accounts = payload["accounts"] as? [[String: Any]],
                        let account = accounts.first(where: { $0["preferred"] as? Bool == true }) ?? accounts.first,
                        let balance = account["balance"] as? [String: Any],
                        let funds = (balance["balance"] as? NSNumber)?.doubleValue,
                        let margin = (balance["deposit"] as? NSNumber)?.doubleValue,
                        let profitLoss = (balance["profitLoss"] as? NSNumber)?.doubleValue,
                        let available = (balance["available"] as? NSNumber)?.doubleValue,
                        let currency = account["currency"] as? String
                    else {
                        self.accountSnapshotError = "Capital.com returned an incomplete account snapshot."
                        return
                    }

                    self.accountSnapshot = BrokerAccountSnapshot(
                        accountName: account["accountName"] as? String ?? currency,
                        status: account["status"] as? String ?? "UNKNOWN",
                        currency: currency,
                        symbol: account["symbol"] as? String ?? currency,
                        funds: funds,
                        margin: margin,
                        profitLoss: profitLoss,
                        available: available,
                        observedAt: payload["observedAt"] as? String ?? ISO8601DateFormatter().string(from: Date())
                    )
                    self.accountSnapshotError = nil
                }
            }
        }
    }

    func addInstrument(_ instrument: MarketWatchInstrument) {
        guard !contains(epic: instrument.epic), watchlist.count < 40 else { return }
        watchlist.append(instrument)
        persistWatchlist()
        restartStream()
    }

    func removeInstrument(epic: String) {
        watchlist.removeAll { $0.epic == epic }
        quotes.removeValue(forKey: epic)
        persistWatchlist()

        if watchlist.isEmpty {
            BackendProcessSupervisor.shared.stopCapitalComMarketData { _ in }
            streamStatus = "stopped"
        } else {
            restartStream()
        }
    }

    func startStreamingIfNeeded(forceRestart: Bool = false) {
        guard !watchlist.isEmpty, !isStartingStream else { return }

        let activeStates: Set<String> = [
            "connecting", "transport-connected", "connected", "reconnecting"
        ]
        if !forceRestart && activeStates.contains(streamStatus) { return }

        startStreamForCurrentWatchlist()
    }

    private func restartStream() {
        guard !watchlist.isEmpty, !isStartingStream else { return }
        isStartingStream = true

        BackendProcessSupervisor.shared.stopCapitalComMarketData { [weak self] _ in
            DispatchQueue.main.async {
                self?.startStreamForCurrentWatchlist()
            }
        }
    }

    private func startStreamForCurrentWatchlist() {
        guard !watchlist.isEmpty else {
            isStartingStream = false
            return
        }

        let epics = watchlist.map(\.epic)
        isStartingStream = true
        streamError = nil

        BackendProcessSupervisor.shared.startCapitalComMarketData(epics: epics) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isStartingStream = false

                if case .failure(let error) = result {
                    self.streamStatus = "error"
                    self.streamError = error.localizedDescription
                } else if self.watchlist.map(\.epic) != epics {
                    // A watchlist edit arrived while the prior subscription was starting.
                    self.restartStream()
                }
            }
        }
    }

    private func enqueueQuote(_ payload: [String: Any]) {
        guard let epic = payload["epic"] as? String else { return }

        quoteBufferLock.lock()
        pendingQuotePayloads[epic] = payload
        let shouldScheduleFlush = !quoteFlushScheduled
        if shouldScheduleFlush {
            quoteFlushScheduled = true
        }
        quoteBufferLock.unlock()

        guard shouldScheduleFlush else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            self?.flushPendingQuotes()
        }
    }

    private func flushPendingQuotes() {
        quoteBufferLock.lock()
        let batch = Array(pendingQuotePayloads.values)
        pendingQuotePayloads.removeAll(keepingCapacity: true)
        quoteFlushScheduled = false
        quoteBufferLock.unlock()

        consumeQuoteBatch(batch)
    }

    private func consumeQuoteBatch(_ payloads: [[String: Any]]) {
        var updatedQuotes = quotes
        var didUpdate = false

        for payload in payloads {
            guard
                let epic = payload["epic"] as? String,
                contains(epic: epic),
                let bid = payload["bid"] as? Double,
                let ask = payload["ask"] as? Double,
                let mid = payload["mid"] as? Double,
                let spread = payload["spread"] as? Double,
                let brokerTimestamp = payload["brokerTimestamp"] as? Double,
                let receivedAt = payload["receivedAt"] as? Double,
                let quality = payload["quality"] as? String
            else { continue }

            let previousMid = updatedQuotes[epic]?.mid
            updatedQuotes[epic] = MarketQuoteSnapshot(
                epic: epic,
                bid: bid,
                ask: ask,
                mid: mid,
                spread: spread,
                previousMid: previousMid,
                brokerTimestamp: brokerTimestamp,
                receivedAt: receivedAt,
                qualityAtReceipt: quality
            )
            didUpdate = true
        }

        guard didUpdate else { return }
        quotes = updatedQuotes
        streamError = nil
    }

    private func consume(event name: String, payload: [String: Any]) {
        switch name {
        case "broker.marketData.status":
            streamStatus = payload["status"] as? String ?? "unknown"
        case "broker.marketData.quote":
            consumeQuoteBatch([payload])
        case "broker.marketData.error":
            streamError = payload["message"] as? String ?? "Market data stream error."
        default:
            break
        }
    }

    private func restoreWatchlist() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let saved = try? JSONDecoder().decode([MarketWatchInstrument].self, from: data)
        else { return }

        watchlist = Array(saved.prefix(40))
    }

    private func persistWatchlist() {
        guard let data = try? JSONEncoder().encode(watchlist) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }
}
