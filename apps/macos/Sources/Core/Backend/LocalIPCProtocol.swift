import Foundation

enum LocalIPCProtocol {
    static let identifier = "atheer.local-ipc"
    static let version = 2
    static let maximumFrameBytes = 65_536
    static let clientVersion = "0.1.0"

    static func request(
        id: String,
        method: String,
        payload: [String: Any]
    ) throws -> Data {
        let envelope: [String: Any] = [
            "protocol": identifier,
            "version": version,
            "kind": "request",
            "id": id,
            "method": method,
            "payload": payload
        ]

        var frame = try JSONSerialization.data(
            withJSONObject: envelope,
            options: [.sortedKeys]
        )

        guard frame.count <= maximumFrameBytes else {
            throw LocalIPCError.frameTooLarge
        }

        frame.append(0x0A)
        return frame
    }

    static func event(from frame: Data) throws -> LocalIPCEvent {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: frame)
        } catch {
            throw LocalIPCError.invalidJSON
        }

        guard
            let envelope = object as? [String: Any],
            Set(envelope.keys) == Set(["protocol", "version", "kind", "event", "payload"]),
            envelope["protocol"] as? String == identifier,
            envelope["version"] as? Int == version,
            envelope["kind"] as? String == "event",
            let name = envelope["event"] as? String,
            !name.isEmpty,
            name.count <= 64,
            let payload = envelope["payload"] as? [String: Any]
        else {
            throw LocalIPCError.invalidResponse
        }

        return LocalIPCEvent(name: name, payload: payload)
    }

    static func response(from frame: Data) throws -> LocalIPCResponse {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: frame)
        } catch {
            throw LocalIPCError.invalidJSON
        }

        guard
            let envelope = object as? [String: Any],
            envelope["protocol"] as? String == identifier,
            envelope["version"] as? Int == version,
            envelope["kind"] as? String == "response",
            let id = envelope["id"] as? String,
            UUID(uuidString: id) != nil,
            let success = envelope["ok"] as? Bool
        else {
            throw LocalIPCError.invalidResponse
        }

        if success {
            guard
                Set(envelope.keys) == Set(["protocol", "version", "kind", "id", "ok", "result"]),
                let result = envelope["result"] as? [String: Any]
            else {
                throw LocalIPCError.invalidResponse
            }

            return LocalIPCResponse(id: id, result: result, remoteError: nil)
        }

        guard
            Set(envelope.keys) == Set(["protocol", "version", "kind", "id", "ok", "error"]),
            let errorObject = envelope["error"] as? [String: Any],
            Set(errorObject.keys) == Set(["code", "message"]),
            let code = errorObject["code"] as? String,
            !code.isEmpty,
            code.count <= 64,
            let message = errorObject["message"] as? String,
            message.count <= 512
        else {
            throw LocalIPCError.invalidResponse
        }

        return LocalIPCResponse(
            id: id,
            result: nil,
            remoteError: LocalIPCRemoteError(code: code, message: message)
        )
    }
}

struct LocalIPCEvent {
    let name: String
    let payload: [String: Any]
}

struct LocalIPCResponse {
    let id: String
    let result: [String: Any]?
    let remoteError: LocalIPCRemoteError?
}

struct LocalIPCRemoteError {
    let code: String
    let message: String
}

enum LocalIPCError: LocalizedError {
    case runtimeNotBundled
    case backendNotBundled
    case processLaunchFailed(String)
    case processNotReady
    case processTerminated
    case credentialsNotFound
    case requestTimedOut
    case frameTooLarge
    case invalidFrame
    case invalidJSON
    case invalidResponse
    case handshakeRejected
    case remote(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .runtimeNotBundled:
            return "The signed Node.js runtime is missing from the application bundle."
        case .backendNotBundled:
            return "The compiled backend entry point is missing from the application bundle."
        case .processLaunchFailed(let reason):
            return "The local backend process could not be launched: \(reason)"
        case .processNotReady:
            return "The local backend has not completed its IPC handshake."
        case .processTerminated:
            return "The local backend process terminated."
        case .credentialsNotFound:
            return "No saved Capital.com credentials were found in macOS Keychain."
        case .requestTimedOut:
            return "The local backend request timed out."
        case .frameTooLarge:
            return "The IPC frame exceeds the permitted size."
        case .invalidFrame:
            return "The local backend sent an invalid IPC frame."
        case .invalidJSON:
            return "The local backend sent invalid JSON."
        case .invalidResponse:
            return "The local backend response does not match the IPC contract."
        case .handshakeRejected:
            return "The local backend rejected protocol negotiation."
        case .remote(let code, let message):
            return "\(code): \(message)"
        }
    }
}

/// Incremental LF-delimited frame decoder. It rejects oversized and empty frames.
struct LocalIPCFrameDecoder {
    private(set) var buffer = Data()

    mutating func append(_ data: Data) throws -> [Data] {
        buffer.append(data)
        var frames: [Data] = []

        while let newline = buffer.firstIndex(of: 0x0A) {
            var frame = Data(buffer[..<newline])
            buffer.removeSubrange(...newline)

            if frame.last == 0x0D {
                frame.removeLast()
            }

            guard !frame.isEmpty else {
                throw LocalIPCError.invalidFrame
            }
            guard frame.count <= LocalIPCProtocol.maximumFrameBytes else {
                throw LocalIPCError.frameTooLarge
            }

            frames.append(frame)
        }

        guard buffer.count <= LocalIPCProtocol.maximumFrameBytes else {
            throw LocalIPCError.frameTooLarge
        }

        return frames
    }

    mutating func reset() {
        buffer.removeAll(keepingCapacity: false)
    }
}
