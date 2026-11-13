import Foundation

/// Immutable representation of an open position reported by the connected broker.
struct BrokerPositionSnapshot: Identifiable, Equatable {
    let dealID: String
    let epic: String
    let instrumentName: String
    let direction: String
    let size: Decimal
    let openingLevel: Decimal
    let currency: String
    let unrealizedProfitLoss: Decimal?
    let bid: Decimal?
    let ask: Decimal?
    let brokerUpdatedAt: String?

    var id: String { dealID }

    init?(payload: [String: Any]) {
        guard
            let position = payload["position"] as? [String: Any],
            let market = payload["market"] as? [String: Any],
            let dealID = position["dealId"] as? String,
            let epic = market["epic"] as? String,
            let instrumentName = market["instrumentName"] as? String,
            let direction = position["direction"] as? String,
            let size = Self.decimal(position["size"]),
            let openingLevel = Self.decimal(position["level"]),
            let currency = position["currency"] as? String
        else { return nil }

        self.dealID = dealID
        self.epic = epic
        self.instrumentName = instrumentName
        self.direction = direction
        self.size = size
        self.openingLevel = openingLevel
        self.currency = currency
        self.unrealizedProfitLoss = Self.decimal(position["upl"])
        self.bid = Self.decimal(market["bid"])
        self.ask = Self.decimal(market["offer"])
        self.brokerUpdatedAt = market["updateTimeUTC"] as? String
    }

    private static func decimal(_ value: Any?) -> Decimal? {
        guard let number = value as? NSNumber else { return nil }
        return number.decimalValue
    }
}
