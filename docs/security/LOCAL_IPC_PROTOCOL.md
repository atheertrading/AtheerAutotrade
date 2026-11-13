# Local IPC Protocol — Version 2

**Product:** ATHEER Trading Pro  
**Transport:** Parent-owned anonymous standard-I/O pipes  
**Status:** Version 2 contract implemented in backend and macOS source; target-Mac build and end-to-end verification pending.

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

Protocol v2 uses an ephemeral encrypted channel for broker credentials.

1. The macOS parent creates a fresh ephemeral Curve25519/X25519 key pair for each child-process session.
2. The parent sends `clientVersion` and its 32-byte raw X25519 public key (base64) in `system.hello`.
3. The backend creates its own fresh X25519 key pair and a cryptographically random 32-byte salt.
4. Both sides derive the same 256-bit key using X25519 shared secret and HKDF-SHA256 with the fixed context string `atheer.local-ipc.capitalcom.credentials.v1`.
5. The backend returns its 32-byte raw public key and salt in the handshake result.
6. The parent encrypts the credential JSON using AES-256-GCM with a fresh 96-bit nonce for each encrypted payload.
7. The backend authenticates and decrypts the payload in memory, validates the credential structure, and accepts exactly one credential submission per child-process session. It retains credentials only in backend process memory.

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

Encrypted credential envelope:

```json
{
  "algorithm": "AES-256-GCM",
  "nonce": "BASE64_12_BYTE_NONCE",
  "ciphertext": "BASE64_CIPHERTEXT",
  "tag": "BASE64_16_BYTE_AUTHENTICATION_TAG"
}
```

The ephemeral exchange protects credential confidentiality and integrity over the inherited pipe. It does not authenticate the executable by itself and does not replace code-signature verification, OS process isolation, Keychain protection at rest, or HTTPS/TLS to Capital.com. JavaScript and Swift runtime memory cannot be claimed to be perfectly zeroized.

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

| Method | Purpose |
|---|---|
| `system.hello` | Negotiate protocol and establish the ephemeral secret channel |
| `system.ping` | Confirm the local IPC process responds |
| `broker.credentials.submit` | Submit one encrypted credential envelope per child session |
| `broker.connect` | Establish a Capital.com Demo REST session |
| `broker.status` | Read current broker session state |
| `broker.disconnect` | Invalidate the session and clear backend credential/session state |
| `broker.marketSearch` | Search Capital.com instruments |
| `broker.historicalPrices` | Retrieve validated historical OHLC snapshots |
| `broker.accounts` | Read broker account snapshots |
| `broker.accountPreferences` | Read account preferences |
| `broker.positions` | Read open positions |
| `broker.workingOrders` | Read working orders |
| `broker.accountSnapshots` | Capability for continuous account snapshot events |
| `broker.positionsSnapshots` | Capability for continuous position snapshot events |
| `broker.workingOrderSnapshots` | Capability for continuous working-order snapshot events |
| `broker.stream.start` | Start real-time quote/OHLC subscriptions |
| `broker.stream.stop` | Stop real-time subscriptions |

All broker operations in this milestone are read-only. The backend rejects Live environment selection. No dealing or order-submission operation is exposed.

## 6. Backend event frames

The backend may send unsolicited event envelopes on stdout while a request/response session is active. Events do not carry request IDs and are never interpreted as request completions.

```json
{
  "protocol": "atheer.local-ipc",
  "version": 2,
  "kind": "event",
  "event": "broker.account.snapshot",
  "payload": {
    "cycleId": 1,
    "observedAt": "2026-11-13T10:00:00.000Z",
    "activeAccountId": "BROKER_ACCOUNT_ID",
    "accounts": []
  }
}
```

Every event frame must contain exactly `protocol`, `version`, `kind`, `event`, and `payload`. Payload must be a JSON object. Event names are explicitly allowlisted in both the backend and macOS parser:

| Event | Payload contract |
|---|---|
| `broker.marketData.status` | Market stream status and subscription state |
| `broker.marketData.quote` | Validated market quote |
| `broker.marketData.ohlc` | Validated OHLC update |
| `broker.marketData.error` | Sanitized market-data error |
| `broker.account.snapshot` | `cycleId`, `observedAt`, optional `activeAccountId`, and `accounts` array |
| `broker.positions.snapshot` | `cycleId`, `observedAt`, and `positions` array |
| `broker.workingOrders.snapshot` | `cycleId`, `observedAt`, and `workingOrders` array |
| `broker.account.sync.status` | `status`, `cycleId` when available, `failedSources` when available, `intervalMs` when available, and `observedAt` |
| `broker.account.sync.error` | `source`, sanitized `message`, and `observedAt` |

Event frames obey the same 65,536-byte limit as request and response frames. The account monitor emits account, positions, and working-order snapshots independently so one source failure does not suppress successful data from another source.

## 7. Protocol errors and session termination

Safe error codes include `INVALID_FRAME`, `INVALID_ENVELOPE`, `INVALID_REQUEST_ID`, `DUPLICATE_REQUEST_ID`, `HANDSHAKE_REQUIRED`, `KEY_AGREEMENT_FAILED`, `PROTOCOL_VERSION_UNSUPPORTED`, `METHOD_NOT_FOUND`, `INVALID_PAYLOAD`, `FRAME_TOO_LARGE`, `SESSION_REQUEST_LIMIT`, `CREDENTIALS_REQUIRED`, `BROKER_NOT_CONNECTED`, `BROKER_API_ERROR`, and `BROKER_OPERATION_FAILED`.

Malformed frames, unsupported protocol versions, invalid envelopes, duplicate IDs, and session request-limit breaches terminate the IPC session. An unknown application method is a request-level error and does not by itself terminate the session. An event with an unknown event name is rejected by the client parser.

## 8. Security rules

1. Stdout is protocol-only; diagnostics use sanitized stderr.
2. Never log serialized request/response frames or payloads.
3. Never place secrets in process environment, command line, launch arguments, files, or telemetry.
4. Keychain remains the source of credentials at rest; the native app owns Keychain access.
5. Encrypt credentials in transit over IPC using the ephemeral v2 secret channel.
6. Capital.com REST uses HTTPS/TLS; CST and X-SECURITY-TOKEN remain backend-process memory only.
7. The backend process is bundled and launched from a fixed app-bundle path; do not use arbitrary PATH resolution.
8. A restarted child is a new session and must complete a fresh key agreement and credential submission.
9. No broker account mutation, dealing, risk bypass, order, or execution capability is exposed.
10. Demo and Live environments remain separate; Live is disabled.

## 9. Versioning policy

Incompatible handshake, framing, required-field, method, or error-semantic changes require a protocol version increment. Adding an explicitly allowlisted event while preserving existing envelope semantics is a backward-compatible protocol-v2 extension; the client must still reject unknown event names. Parent and child fail closed on unsupported protocol versions.

## 10. Verification status

The backend account monitor has dedicated tests and Backend CI passed on implementation commit `f042c8b` (56 tests). The macOS IPC parser now has regression tests for all five account events and rejection of unknown event names. Target-Mac Xcode build and end-to-end Capital.com Demo reconciliation remain pending.

## 11. References

- [ATP-BROKER-ACCOUNT-001](../engineering/ATP-BROKER-ACCOUNT-001.md)
- [ADR-0005 — Secure macOS IPC](../decisions/ADR-0005-SECURE-MACOS-IPC.md)
- [ADR-0004 — Production Architecture Baseline](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md)
- [Security Baseline](SECURITY_BASELINE.md)
