import Combine
import Foundation

/// Application-wide broker state service. Every feature reads the same live
/// account, positions, and working-order snapshots through the environment.
final class BrokerAccountStore: ObservableObject {
    static let shared = BrokerAccountStore()

    @Published private(set) var accountSnapshot: BrokerAccountSnapshot?
    @Published private(set) var positions: [BrokerPositionSnapshot] = []
    @Published private(set) var workingOrders: [BrokerWorkingOrderSnapshot] = []
    @Published private(set) var syncStatus = "disconnected"
    /// Local receipt time, used for transport freshness and clock-skew-safe staleness.
    @Published private(set) var lastSuccessfulSyncAt: Date?
    @Published private(set) var lastSyncError: String?
    @Published private(set) var pollingIntervalMilliseconds = 1_000

    private var eventSubscriptionID: UUID?
    private let eventQueue = DispatchQueue(label: "com.atheertrading.broker-account-events")

    private init() {}

    var isConnected: Bool {
        syncStatus == "connected" || syncStatus == "degraded" || syncStatus == "syncing"
    }

    var accountSnapshotAge: TimeInterval {
        guard let lastSuccessfulSyncAt else { return .infinity }
        return max(0, Date().timeIntervalSince(lastSuccessfulSyncAt))
    }

    /// Account data is considered delayed after 2.5 cadence windows and stale
    /// after five seconds without a newly received broker snapshot.
    var isDelayed: Bool { accountSnapshotAge > 2.5 }
    var isStale: Bool { accountSnapshotAge > 5.0 }

    var freshnessLabel: String {
        guard accountSnapshot != nil else { return "WAITING" }
        if isStale { return "STALE" }
        if isDelayed { return "DELAYED" }
        return "LIVE"
    }

    func startObserving() {
        guard eventSubscriptionID == nil else { return }
        eventSubscriptionID = BackendProcessSupervisor.shared.addEventHandler { [weak self] name, payload in
            self?.eventQueue.async {
                self?.consume(event: name, payload: payload)
            }
        }
    }

    func stopObserving() {
        guard let eventSubscriptionID else { return }
        BackendProcessSupervisor.shared.removeEventHandler(eventSubscriptionID)
        self.eventSubscriptionID = nil
    }

    private func consume(event name: String, payload: [String: Any]) {
        DispatchQueue.main.async {
            switch name {
            case "broker.account.snapshot":
                self.consumeAccounts(payload)
            case "broker.positions.snapshot":
                self.consumePositions(payload)
            case "broker.workingOrders.snapshot":
                self.consumeWorkingOrders(payload)
            case "broker.account.sync.status":
                self.consumeSyncStatus(payload)
            case "broker.account.sync.error":
                self.lastSyncError = payload["message"] as? String ?? "Broker account synchronization failed."
                self.syncStatus = "degraded"
            case "system.backend.disconnected":
                self.consumeSyncStatus(["status": "disconnected"])
            default:
                break
            }
        }
    }

    private func consumeAccounts(_ payload: [String: Any]) {
        guard let accounts = payload["accounts"] as? [[String: Any]] else {
            lastSyncError = "Capital.com account snapshot has an invalid payload."
            syncStatus = "degraded"
            return
        }

        let observedAt = Self.date(payload["observedAt"] as? String) ?? Date()
        let snapshots = accounts.compactMap {
            BrokerAccountSnapshot(payload: $0, observedAt: observedAt)
        }
        let activeAccountID = payload["activeAccountId"] as? String
        guard let selected =
            snapshots.first(where: { $0.accountID == activeAccountID }) ??
            snapshots.first(where: \.isPreferred) ??
            snapshots.first else {
            lastSyncError = "Capital.com returned no usable financial account."
            syncStatus = "degraded"
            return
        }

        accountSnapshot = selected
        // Use local receipt time for freshness. Broker timestamps remain attached
        // to the immutable snapshot for audit and source-observation display.
        lastSuccessfulSyncAt = Date()
        lastSyncError = nil
    }

    private func consumePositions(_ payload: [String: Any]) {
        guard let items = payload["positions"] as? [[String: Any]] else {
            lastSyncError = "Capital.com positions snapshot has an invalid payload."
            syncStatus = "degraded"
            return
        }
        positions = items.compactMap(BrokerPositionSnapshot.init(payload:))
    }

    private func consumeWorkingOrders(_ payload: [String: Any]) {
        guard let items = payload["workingOrders"] as? [[String: Any]] else {
            lastSyncError = "Capital.com working-orders snapshot has an invalid payload."
            syncStatus = "degraded"
            return
        }
        workingOrders = items.compactMap(BrokerWorkingOrderSnapshot.init(payload:))
    }

    private static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }

    private func consumeSyncStatus(_ payload: [String: Any]) {
        guard let status = payload["status"] as? String else { return }
        syncStatus = status
        if let interval = payload["intervalMs"] as? Int {
            pollingIntervalMilliseconds = interval
        }
        if status == "disconnected" {
            accountSnapshot = nil
            positions = []
            workingOrders = []
            lastSuccessfulSyncAt = nil
            lastSyncError = nil
        } else if status == "connected" {
            lastSyncError = nil
        }
    }
}
