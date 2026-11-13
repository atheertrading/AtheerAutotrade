import Foundation

/// Immutable broker-authoritative account state shared by every application feature.
struct BrokerAccountSnapshot: Identifiable, Equatable {
    let accountID: String
    let accountName: String
    let accountType: String
    let status: String
    let currency: String
    let currencySymbol: String
    let isPreferred: Bool
    let funds: Decimal
    let available: Decimal
    let profitLoss: Decimal
    let margin: Decimal
    let observedAt: Date

    var id: String { accountID }
    var balance: Decimal { funds }
    var equity: Decimal { funds + profitLoss }
    var marginLevel: Decimal? {
        guard margin > 0 else { return nil }
        return equity / margin * 100
    }

    var age: TimeInterval {
        max(0, Date().timeIntervalSince(observedAt))
    }

    var isStale: Bool { age > 10 }

    init?(payload: [String: Any], observedAt fallbackDate: Date = Date()) {
        guard
            let accountID = payload["accountId"] as? String,
            let accountName = payload["accountName"] as? String,
            let accountType = payload["accountType"] as? String,
            let status = payload["status"] as? String,
            let currency = payload["currency"] as? String,
            let balance = payload["balance"] as? [String: Any],
            let funds = Self.decimal(balance["balance"]),
            let margin = Self.decimal(balance["deposit"]),
            let profitLoss = Self.decimal(balance["profitLoss"]),
            let available = Self.decimal(balance["available"])
        else { return nil }

        self.accountID = accountID
        self.accountName = accountName
        self.accountType = accountType
        self.status = status
        self.currency = currency
        self.currencySymbol = payload["symbol"] as? String ?? currency
        self.isPreferred = payload["preferred"] as? Bool ?? false
        self.funds = funds
        self.available = available
        self.profitLoss = profitLoss
        self.margin = margin
        self.observedAt = Self.date(payload["observedAt"] as? String) ?? fallbackDate
    }

    private static func decimal(_ value: Any?) -> Decimal? {
        guard let number = value as? NSNumber else { return nil }
        return number.decimalValue
    }

    private static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }
}
