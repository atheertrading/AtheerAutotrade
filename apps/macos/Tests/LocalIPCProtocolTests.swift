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
        let first = Data("{\"kind\":\"response\"}".utf8)
        let second = Data("{\"kind\":\"response2\"}".utf8)

        XCTAssertEqual(try decoder.append(first + Data([0x0A]) + Data(second.prefix(5))).count, 1)
        let remaining = Data(second.dropFirst(5)) + Data([0x0A])
        let frames = try decoder.append(remaining)

        XCTAssertEqual(frames.count, 1)
        XCTAssertEqual(String(decoding: frames[0], as: UTF8.self), "{\"kind\":\"response2\"}")
    }

    func testFrameDecoderRejectsOversizedUnterminatedFrame() {
        var decoder = LocalIPCFrameDecoder()
        let oversized = Data(
            repeating: 0x61,
            count: LocalIPCProtocol.maximumFrameBytes + 1
        )

        XCTAssertThrowsError(try decoder.append(oversized))
    }

    func testResponseRejectsProtocolVersionMismatch() {
        let frame = Data(
            "{\"protocol\":\"atheer.local-ipc\",\"version\":1,\"kind\":\"response\",\"id\":\"f2b66c1b-8c25-4c35-ae80-b0d59d7a9133\",\"ok\":true,\"result\":{}}".utf8
        )

        XCTAssertThrowsError(try LocalIPCProtocol.response(from: frame))
    }
}
