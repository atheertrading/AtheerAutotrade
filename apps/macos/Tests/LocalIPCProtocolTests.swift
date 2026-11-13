import XCTest
@testable import AtheerAutotrade

final class LocalIPCProtocolTests: XCTestCase {
    func testRequestUsesVersionedNDJSONEnvelope() throws {
        let frame = try LocalIPCProtocol.request(
            id: "f2b66c1b-8c25-4c35-ae80-b0d59d7a9133",
            method: "system.hello",
            payload: [
                "clientVersion": LocalIPCProtocol.clientVersion,
                "clientPublicKey": Data(repeating: 0, count: 32).base64EncodedString()
            ]
        )

        XCTAssertEqual(frame.last, 0x0A)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(frame.dropLast())) as? [String: Any]
        )
        XCTAssertEqual(json["protocol"] as? String, LocalIPCProtocol.identifier)
        XCTAssertEqual(json["version"] as? Int, LocalIPCProtocol.version)
        XCTAssertEqual(json["method"] as? String, "system.hello")
    }

    func testFrameDecoderHandlesFragmentedAndMultipleFrames() throws {
        var decoder = LocalIPCFrameDecoder()
        let first = Data("{\\"kind\\":\\"response\\"}".utf8)
        let second = Data("{\\"kind\\":\\"response2\\"}".utf8)

        XCTAssertEqual(try decoder.append(first + Data([0x0A]) + Data(second.prefix(5))).count, 1)
        let remaining = Data(second.dropFirst(5)) + Data([0x0A])
        let frames = try decoder.append(remaining)

        XCTAssertEqual(frames.count, 1)
        XCTAssertEqual(String(decoding: frames[0], as: UTF8.self), "{\\"kind\\":\\"response2\\"}")
    }

    func testFrameDecoderRejectsOversizedUnterminatedFrame() {
        var decoder = LocalIPCFrameDecoder()
        let oversized = Data(
            repeating: 0x61,
            count: LocalIPCProtocol.maximumFrameBytes + 1
        )

        XCTAssertThrowsError(try decoder.append(oversized))
    }

    func testEventParserAcceptsVersionedMarketDataEvents() throws {
        let frame = Data(
            "{\\"protocol\\":\\"atheer.local-ipc\\",\\"version\\":2,\\"kind\\":\\"event\\",\\"event\\":\\"broker.marketData.status\\",\\"payload\\":{\\"status\\":\\"connected\\"}}".utf8
        )

        let event = try LocalIPCProtocol.event(from: frame)
        XCTAssertEqual(event.name, "broker.marketData.status")
        XCTAssertEqual(event.payload["status"] as? String, "connected")
    }

    func testEventParserAcceptsEveryCapitalComAccountEvent() throws {
        let eventPayloads: [(String, String)] = [
            ("broker.account.snapshot", "{\\"accounts\\":[],\\"observedAt\\":\\"2026-11-13T10:00:00.000Z\\"}"),
            ("broker.positions.snapshot", "{\\"positions\\":[]}"),
            ("broker.workingOrders.snapshot", "{\\"workingOrders\\":[]}"),
            ("broker.account.sync.status", "{\\"status\\":\\"syncing\\",\\"intervalMs\\":2000}"),
            ("broker.account.sync.error", "{\\"source\\":\\"accounts\\",\\"message\\":\\"snapshot unavailable\\"}")
        ]

        for (name, payload) in eventPayloads {
            let frame = Data(
                "{\\"protocol\\":\\"atheer.local-ipc\\",\\"version\\":2,\\"kind\\":\\"event\\",\\"event\\":\\"\(name)\\",\\"payload\\":\(payload)}".utf8
            )
            let event = try LocalIPCProtocol.event(from: frame)
            XCTAssertEqual(event.name, name)
        }
    }

    func testEventParserRejectsUnknownEventNames() {
        let frame = Data(
            "{\\"protocol\\":\\"atheer.local-ipc\\",\\"version\\":2,\\"kind\\":\\"event\\",\\"event\\":\\"broker.unknown.event\\",\\"payload\\":{}}".utf8
        )

        XCTAssertThrowsError(try LocalIPCProtocol.event(from: frame))
    }

    func testResponseRejectsProtocolVersionMismatch() {
        let frame = Data(
            "{\\"protocol\\":\\"atheer.local-ipc\\",\\"version\\":1,\\"kind\\":\\"response\\",\\"id\\":\\"f2b66c1b-8c25-4c35-ae80-b0d59d7a9133\\",\\"ok\\":true,\\"result\\":{}}".utf8
        )

        XCTAssertThrowsError(try LocalIPCProtocol.response(from: frame))
    }

    func testCapitalComAccountFieldsUsePlatformFundsEquityAndMarginSemantics() throws {
        let payload: [String: Any] = [
            "accountId": "demo-account",
            "accountName": "ATHEER Trading",
            "accountType": "CFD",
            "status": "ENABLED",
            "currency": "USD",
            "symbol": "$",
            "preferred": true,
            "balance": [
                "balance": 995.58,
                "deposit": 1_000.20,
                "profitLoss": -4.62,
                "available": 984.59
            ]
        ]

        let account = try XCTUnwrap(BrokerAccountSnapshot(payload: payload))

        XCTAssertEqual(account.funds, Decimal(string: "1000.20"))
        XCTAssertEqual(account.equity, Decimal(string: "995.58"))
        XCTAssertEqual(account.profitLoss, Decimal(string: "-4.62"))
        XCTAssertEqual(account.available, Decimal(string: "984.59"))
        XCTAssertEqual(account.margin, Decimal(string: "10.99"))
        XCTAssertEqual(account.equity, account.funds + account.profitLoss)
    }

    func testCapitalComAccountSnapshotRejectsNegativeDerivedMargin() {
        let payload: [String: Any] = [
            "accountId": "demo-account",
            "accountName": "ATHEER Trading",
            "accountType": "CFD",
            "status": "ENABLED",
            "currency": "USD",
            "symbol": "$",
            "preferred": true,
            "balance": [
                "balance": 100.00,
                "deposit": 100.00,
                "profitLoss": 0.00,
                "available": 100.01
            ]
        ]

        XCTAssertNil(BrokerAccountSnapshot(payload: payload))
    }
}
