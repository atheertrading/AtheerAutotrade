import Foundation

/// Immutable broker-authoritative account state shared by every application feature.
///
/// Capital.com GET /accounts semantics:
/// - balance.deposit: Funds (realised account balance, excluding open-position P&L)
/// - balance.balance: Equity (Funds + running P&L)
/// - balance.profitLoss: running P&L
/// - balance.available: available funds
/// Margin is derived as Equity - Available, matching Capital.com's platform definition.
/// Do not interpret the API field named "deposit" as used margin.
struct BrokerAccountSnapshot: Identifiable, Equatable {
    let accountID: String
    let accountName: String
    let accountType: String
    let status: String
    let currency: String
    let currencySymbol: String
    let isPreferred: Bool
    let funds: Decimal
    let equity: Decimal
    let available: Decimal
    let profitLoss: Decimal
    /// Derived from broker-reported Equity and Available, not API balance.deposit.
    var margin: Decimal { equity - available }
    /// Broker/backend observation timestamp; transport freshness is tracked separately by BrokerAccountStore.
    let observedAt: Date

    var id: String { accountID }
    var balance: Decimal { funds }
    var marginLevel: Decimal? {
        guard margin > 0 else { return nil }
        return equity / margin * 100
    }

    var age: TimeInterval {
        max(0, Date().timeIntervalSince(observedAt))
    }

    var isStale: Bool { age > 5 }

    init?(payload: [String: Any], observedAt fallbackDate: Date = Date()) {
        guard
            let accountID = payload["accountId"] as? String,
            let accountName = payload["accountName"] as? String,
            let accountType = payload["accountType"] as? String,
            let status = payload["status"] as? String,
            let currency = payload["currency"] as? String,
            let balance = payload["balance"] as? [String: Any],
            let equity = Self.decimal(balance["balance"]),
            let funds = Self.decimal(balance["deposit"]),
            let profitLoss = Self.decimal(balance["profitLoss"]),
            let available = Self.decimal(balance["available"]),
            equity >= available
        else { return nil }

        self.accountID = accountID
        self.accountName = accountName
        self.accountType = accountType
        self.status = status
        self.currency = currency
        self.currencySymbol = payload["symbol"] as? String ?? currency
        self.isPreferred = payload["preferred"] as? Bool ?? false
        self.funds = funds
        self.equity = equity
        self.available = available
        self.profitLoss = profitLoss
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
