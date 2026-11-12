# Local IPC Protocol — Version 2

**Product:** ATHEER Trading Pro  
**Transport:** Parent-owned anonymous standard-I/O pipes  
**Status:** Source implementation added; build and end-to-end verification pending.

## 1. Transport contract

- The native macOS application launches and supervises the bundled backend child process.
- Parent → child: UTF-8 NDJSON frames on child standard input.
- Child → parent: UTF-8 NDJSON frames on child standard output.
- Child standard error is diagnostics only; never parse it as protocol.
- One complete JSON object per line, terminated by LF. CRLF may be accepted by stripping one terminal CR.
- Maximum frame size is 65,536 UTF-8 bytes, excluding the line terminator.
- Empty frames, invalid UTF-8, malformed JSON, invalid envelopes, and oversized frames are protocol violations.
- Production stdio mode opens no TCP listener and no filesystem socket.
- Credentials and session tokens are never placed in process arguments or environment variables.

## 2. Request envelope

```json
{
  "protocol": "atheer.local-ipc",
  "version": 2,
  "kind": "request",
  "id": "a valid UUID",
  "method": "system.hello",
  "payload": {}
}
```

Required fields are exact. Unknown envelope fields are rejected. The request ID must be a UUID unique for the lifetime of the IPC session.

## 3. Ephemeral encrypted secret channel establishment

Protocol v2 changes the handshake because broker credentials must be encrypted as data while crossing the local process boundary.

1. The macOS parent creates a fresh ephemeral Curve25519/X25519 key pair for each child-process session.
2. The parent sends `clientVersion` and its 32-byte raw X25519 public key (base64) in `system.hello`.
3. The backend creates its own fresh X25519 key pair and a cryptographically random 32-byte salt.
4. Both sides derive the same 256-bit key using X25519 shared secret and HKDF-SHA256 with the fixed context string `atheer.local-ipc.capitalcom.credentials.v1`.
5. The backend returns its 32-byte raw public key and salt in the handshake result.
6. The parent encrypts the credential JSON using AES-256-GCM with a fresh 96-bit nonce for each encrypted payload.
7. The backend authenticates and decrypts the payload in memory, validates the credential structure, and accepts exactly one credential submission per child-process session. It retains the credentials only in backend process memory.

Handshake request:

```json
{
  "protocol": "atheer.local-ipc",
  "version": 2,
  "kind": "request",
  "id": "f2b66c1b-8c25-4c35-ae80-b0d59d7a9133",
  "method": "system.hello",
  "payload": {
    "clientVersion": "0.1.0",
    "clientPublicKey": "BASE64_X25519_PUBLIC_KEY"
  }
}
```

Handshake response includes:

```json
{
  "protocolVersion": 2,
  "service": "atheerautotrade-backend",
  "capabilities": [
    "system.ping",
    "broker.credentials.submit",
    "broker.connect",
    "broker.status",
    "broker.disconnect",
    "broker.marketSearch",
    "broker.historicalPrices"
  ],
  "keyAgreement": {
    "algorithm": "X25519-HKDF-SHA256-AES-256-GCM",
    "publicKey": "BASE64_X25519_PUBLIC_KEY",
    "salt": "BASE64_RANDOM_SALT"
  }
}
```

Encrypted credential envelope:

```json
{
  "algorithm": "AES-256-GCM",
  "nonce": "BASE64_12_BYTE_NONCE",
  "ciphertext": "BASE64_CIPHERTEXT",
  "tag": "BASE64_16_BYTE_AUTHENTICATION_TAG"
}
```

The public-key exchange is ephemeral and provides confidentiality/integrity for the credential payload on the inherited pipe. It does not authenticate the executable by itself and does not replace code-signature verification of the bundled backend, OS process isolation, Keychain protection at rest, or HTTPS/TLS to Capital.com. JavaScript and Swift runtime memory cannot be claimed to be perfectly zeroized.

## 4. Response envelope

Success:

```json
{
  "protocol": "atheer.local-ipc",
  "version": 2,
  "kind": "response",
  "id": "request UUID",
  "ok": true,
  "result": {}
}
```

Failure:

```json
{
  "protocol": "atheer.local-ipc",
  "version": 2,
  "kind": "response",
  "id": "request UUID or null",
  "ok": false,
  "error": {
    "code": "SAFE_MACHINE_CODE",
    "message": "Safe, non-sensitive description."
  }
}
```

Never include stack traces, file paths, raw provider responses, credentials, session tokens, request payloads, or internal exception messages in responses.

## 5. Application method allowlist

| Method | Purpose | State |
|---|---|---|
| `system.hello` | Negotiate protocol and establish ephemeral secret channel | Implemented in source |
| `system.ping` | Confirm local IPC process responds | Implemented in source |
| `broker.credentials.submit` | Submit exactly one encrypted credential envelope per child session; backend retains it in memory only | Implemented in source |
| `broker.connect` | Establish and ping a Capital.com Demo REST session | Implemented in source |
| `broker.status` | Read current broker session state | Implemented in source |
| `broker.disconnect` | Invalidate session and clear backend credential/session state | Implemented in source |
| `broker.marketSearch` | Search Capital.com instruments | Implemented in source |
| `broker.historicalPrices` | Retrieve validated historical OHLC snapshots | Implemented in source |
| `broker.stream.start` | Start real-time quote/OHLC subscriptions | Implemented in source |
| `broker.stream.stop` | Stop real-time subscriptions | Implemented in source |
| Account, order, position, dealing, and execution methods | No capability is exposed | Prohibited in this milestone |

All broker methods are read-only. The backend rejects Live environment selection. No generic method invocation, shell command, filesystem access, arbitrary URL fetch, or dealing operation is permitted.

## 6. Backend event frames

The backend may send unsolicited event envelopes on stdout while a request/response session is active. Events do not carry request IDs and are never interpreted as request completions.

```json
{
  "protocol": "atheer.local-ipc",
  "version": 2,
  "kind": "event",
  "event": "broker.marketData.quote",
  "payload": {
    "epic": "MARKET_EPIC",
    "bid": 1.2345,
    "ask": 1.2347,
    "timestamp": 1790000000000
  }
}
```

Event names are bounded strings and payloads must be JSON objects. Event frames obey the same 65,536-byte limit as request and response frames. The current event set is broker.marketData.status, broker.marketData.quote, broker.marketData.ohlc, and broker.marketData.error. Stream status is transport-connected only after the WebSocket opens and connected only after both quote and OHLC subscriptions are acknowledged.

## 7. Protocol errors and session termination

Safe error codes include:
- `INVALID_FRAME`
- `INVALID_ENVELOPE`
- `INVALID_REQUEST_ID`
- `DUPLICATE_REQUEST_ID`
- `HANDSHAKE_REQUIRED`
- `KEY_AGREEMENT_FAILED`
- `PROTOCOL_VERSION_UNSUPPORTED`
- `METHOD_NOT_FOUND`
- `INVALID_PAYLOAD`
- `FRAME_TOO_LARGE`
- `SESSION_REQUEST_LIMIT`
- `CREDENTIALS_REQUIRED`
- `BROKER_NOT_CONNECTED`
- `BROKER_API_ERROR`
- `BROKER_OPERATION_FAILED`
- `INTERNAL_ERROR`

Invalid UTF-8, oversized frames, unsupported protocol versions, invalid envelopes, duplicate IDs, or session request-limit breaches terminate the IPC session. An unknown application method is a request-level error and does not by itself terminate the session.

The initial implementation limits a session to 4,096 unique requests. The parent uses request timeouts and terminates a child that stops responding. No automatic replay is permitted after timeout or process restart.

## 8. Security rules

1. Stdout is protocol-only; diagnostics use sanitized stderr.
2. Never log serialized request/response frames or payloads.
3. Never place secrets in process environment, command line, launch arguments, files, or telemetry.
4. Keychain remains the source of credentials at rest; the native app owns Keychain access.
5. Encrypt credentials in transit over IPC using the ephemeral v2 secret channel.
6. Capital.com REST uses HTTPS/TLS; CST and X-SECURITY-TOKEN remain backend-process memory only.
7. The backend process is bundled and launched from a fixed app-bundle path; do not use arbitrary PATH resolution.
8. A restarted child is a new session and must complete a fresh key agreement and handshake. The broker credential submission is one-shot per child session; reconnect after disconnect starts a new child session.
9. No broker account mutation, dealing, risk bypass, order, or execution capability is exposed.
10. Demo and Live environments remain separate; Live is disabled.

## 9. Versioning policy

Incompatible handshake, framing, required-field, method, or error-semantic changes require a protocol version increment. Parent and child fail closed on unsupported versions. Capability negotiation is mandatory; a client must not call a method absent from the handshake response.

## 10. Verification status

Backend TypeScript compilation and 31/31 Node tests passed in GitHub Actions on Node.js 24.22.2 (run 43332525299). Xcode build, CryptoKit/Node cross-language interoperability, packaged runtime launch, and actual Capital.com Demo authentication remain unverified on the target Mac.

## 11. References

- [ADR-0005 — Secure macOS IPC](../decisions/ADR-0005-SECURE-MACOS-IPC.md)
- [ADR-0004 — Production Architecture Baseline](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md)
- [Security Baseline](SECURITY_BASELINE.md)
