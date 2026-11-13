import Combine
import Foundation

struct MarketWatchInstrument: Codable, Hashable, Identifiable {
    let epic: String
    let name: String
    let instrumentType: String
    let marketStatus: String

    var id: String { epic }
}

struct MarketQuoteSnapshot: Identifiable {
    let epic: String
    let bid: Double
    let ask: Double
    let mid: Double
    let spread: Double
    let brokerTimestamp: Double
    let receivedAt: Double
    let qualityAtReceipt: String

    var id: String { epic }

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
    @Published private(set) var streamError: String?

    private let persistenceKey = "com.atheertrading.market-watch.v1"
    private var isObserving = false
    private var isStartingStream = false

    private init() {
        restoreWatchlist()
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        BackendProcessSupervisor.shared.setEventHandler { [weak self] name, payload in
            DispatchQueue.main.async {
                self?.consume(event: name, payload: payload)
            }
        }
    }

    func contains(epic: String) -> Bool {
        watchlist.contains { $0.epic == epic }
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
            self?.startStreamForCurrentWatchlist()
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
                }
            }
        }
    }

    private func consume(event name: String, payload: [String: Any]) {
        switch name {
        case "broker.marketData.status":
            streamStatus = payload["status"] as? String ?? "unknown"
        case "broker.marketData.quote":
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
            else { return }

            quotes[epic] = MarketQuoteSnapshot(
                epic: epic,
                bid: bid,
                ask: ask,
                mid: mid,
                spread: spread,
                brokerTimestamp: brokerTimestamp,
                receivedAt: receivedAt,
                qualityAtReceipt: quality
            )
            streamError = nil
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
