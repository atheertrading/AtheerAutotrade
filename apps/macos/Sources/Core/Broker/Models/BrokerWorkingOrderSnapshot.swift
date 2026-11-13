import Foundation

/// Immutable representation of a pending working order reported by the broker.
struct BrokerWorkingOrderSnapshot: Identifiable, Equatable {
    let dealID: String
    let epic: String
    let instrumentName: String
    let direction: String
    let orderType: String
    let timeInForce: String
    let size: Decimal
    let orderLevel: Decimal
    let currency: String
    let createdAt: String?

    var id: String { dealID }

    init?(payload: [String: Any]) {
        guard
            let order = payload["workingOrderData"] as? [String: Any],
            let market = payload["marketData"] as? [String: Any],
            let dealID = order["dealId"] as? String,
            let epic = order["epic"] as? String,
            let instrumentName = market["instrumentName"] as? String,
            let direction = order["direction"] as? String,
            let orderType = order["orderType"] as? String,
            let timeInForce = order["timeInForce"] as? String,
            let size = Self.decimal(order["orderSize"]),
            let orderLevel = Self.decimal(order["orderLevel"]),
            let currency = order["currencyCode"] as? String
        else { return nil }

        self.dealID = dealID
        self.epic = epic
        self.instrumentName = instrumentName
        self.direction = direction
        self.orderType = orderType
        self.timeInForce = timeInForce
        self.size = size
        self.orderLevel = orderLevel
        self.currency = currency
        self.createdAt = order["createdDateUTC"] as? String
    }

    private static func decimal(_ value: Any?) -> Decimal? {
        guard let number = value as? NSNumber else { return nil }
        return number.decimalValue
    }
}
