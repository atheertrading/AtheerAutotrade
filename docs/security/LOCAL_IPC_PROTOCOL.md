# Local IPC Protocol — Version 1

**Product:** ATHEER Trading Pro  
**Transport:** Parent-owned anonymous standard-I/O pipes  
**Status:** Initial protocol contract; implementation is limited to handshake and ping.

## 1. Transport contract

- The macOS application launches and supervises one backend child process.
- Parent → child: UTF-8 NDJSON frames on child standard input.
- Child → parent: UTF-8 NDJSON frames on child standard output.
- Child standard error is diagnostics only; never parse it as protocol.
- One complete JSON object per line, terminated by LF (`\n`). CRLF may be accepted by stripping one terminal CR before parsing.
- Maximum frame size is 65,536 UTF-8 bytes, excluding line terminator.
- Empty frames, invalid UTF-8, malformed JSON, invalid envelopes, and oversized frames are protocol violations.
- Production stdio mode opens no TCP listener and no filesystem socket.
- No credentials or secrets may be supplied in command-line arguments or environment variables.

## 2. Request envelope

```json
{
  "protocol": "atheer.local-ipc",
  "version": 1,
  "kind": "request",
  "id": "a valid UUID",
  "method": "system.hello",
  "payload": {}
}
```

Required fields:
- `protocol`: exact string `atheer.local-ipc`.
- `version`: integer protocol version; currently `1`.
- `kind`: exact string `request`.
- `id`: UUID string unique for the lifetime of the IPC session.
- `method`: allowlisted method name.
- `payload`: JSON object; arrays and primitive values are not accepted as the top-level payload.

Unknown envelope fields are rejected to avoid ambiguous interpretation between protocol versions.

## 3. Handshake

The first request must be `system.hello`. No other method is accepted before successful handshake.

Example:

```json
{"protocol":"atheer.local-ipc","version":1,"kind":"request","id":"f2b66c1b-8c25-4c35-ae80-b0d59d7a9133","method":"system.hello","payload":{"clientVersion":"0.1.0"}}
```

Successful response:

```json
{"protocol":"atheer.local-ipc","version":1,"kind":"response","id":"f2b66c1b-8c25-4c35-ae80-b0d59d7a9133","ok":true,"result":{"protocolVersion":1,"service":"atheerautotrade-backend","capabilities":["system.ping"]}}
```

The parent must compare the returned protocol version and required capabilities before considering the child ready. A version mismatch is fatal; do not silently downgrade.

## 4. Response envelope

Success:

```json
{
  "protocol": "atheer.local-ipc",
  "version": 1,
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
  "version": 1,
  "kind": "response",
  "id": "request UUID or null when it cannot be recovered",
  "ok": false,
  "error": {
    "code": "SAFE_MACHINE_CODE",
    "message": "Safe, non-sensitive description."
  }
}
```

Do not include stack traces, file paths, raw provider responses, credentials, tokens, request payloads, or internal exception messages in responses.

## 5. Initial method allowlist

| Method | Purpose | Availability |
|---|---|---|
| `system.hello` | Negotiate protocol version and capabilities | Implemented first |
| `system.ping` | Confirm the IPC process responds | Initial implementation |
| `system.getReadiness` | Future aggregate backend readiness snapshot | Not yet exposed |
| `broker.connect` | Future read-only broker session request | Not exposed |
| `broker.disconnect` | Future broker session shutdown | Not exposed |
| `broker.credentials.submit` | Future one-shot credential handoff from native Keychain owner | Not exposed; requires separate security review |

Unknown methods return `METHOD_NOT_FOUND`. No generic method invocation, shell command, filesystem access, arbitrary URL fetch, or dealing operation is permitted.

## 6. Protocol errors and session termination

Safe error codes:
- `INVALID_FRAME`
- `INVALID_ENVELOPE`
- `INVALID_REQUEST_ID`
- `DUPLICATE_REQUEST_ID`
- `HANDSHAKE_REQUIRED`
- `PROTOCOL_VERSION_UNSUPPORTED`
- `METHOD_NOT_FOUND`
- `INVALID_PAYLOAD`
- `FRAME_TOO_LARGE`
- `SESSION_REQUEST_LIMIT`
- `INTERNAL_ERROR`

Invalid UTF-8, oversized frame, unsupported protocol version, invalid envelope, duplicate ID, or session request-limit breach terminates the IPC session after a bounded error response where possible. An unknown application method is a request-level error and does not by itself terminate the session.

The initial implementation limits a session to 4,096 unique requests. The parent should use a request timeout and terminate a child that stops responding. No automatic replay is permitted after timeout or process restart.

## 7. Initial security rules

1. Stdout is reserved exclusively for protocol frames.
2. Diagnostics go to stderr and are sanitized.
3. Never log serialized request/response frames or payloads.
4. Never place secrets in the process environment, command line, launch arguments, or files.
5. The initial method set exposes no credentials, account, broker, risk, order, or execution capability.
6. Parent owns process creation, pipe endpoints, shutdown, and restart.
7. A restarted child is a new session and must complete handshake again.
8. Any future credential-transfer method must be narrowly scoped, one-shot, memory-only, redacted, and separately reviewed; it must not be treated as an ordinary diagnostic request.

## 8. Versioning policy

- Additive optional response fields may be introduced only if old clients safely ignore them.
- New required request fields, changed semantics, new framing, or incompatible errors require a protocol version increment.
- Parent and child must fail closed on unsupported versions.
- Keep capability negotiation explicit. A client must not call a capability absent from the handshake response.

## 9. References

- [ADR-0005 — Secure macOS IPC](../decisions/ADR-0005-SECURE-MACOS-IPC.md)
- [ADR-0004 — Production Architecture Baseline](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md)
- [Security Baseline](SECURITY_BASELINE.md)
