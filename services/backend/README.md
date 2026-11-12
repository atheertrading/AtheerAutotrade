# Backend foundation

This Node.js/TypeScript service is the backend modular monolith for ATHEER Trading Pro. It is a separate process from the native SwiftUI macOS client.

## Runtime modes

### Production desktop mode — stdio IPC

The macOS application will launch and supervise the backend as a child process. Parent-to-child requests use standard input; child-to-parent responses use standard output. Standard output is reserved exclusively for versioned NDJSON protocol frames. Standard error is for sanitized diagnostics only.

The protocol handler currently exists at `src/api/stdio-ipc.ts`. It implements:
- protocol version 1 handshake (`system.hello`);
- process liveness ping (`system.ping`);
- 65,536-byte maximum frame size;
- strict request envelope and UUID validation;
- duplicate request ID detection;
- 4,096-request session limit;
- explicit method allowlist and safe error responses.

**The handler is not yet wired into `server.ts`, and the SwiftUI process launcher/client is not yet implemented.** It is a tested-by-source-design module only until the backend build and tests are executed in a real Node.js environment.

### Development/diagnostic mode — loopback HTTP

The existing HTTP runtime currently exposes only `GET /health` and structured 404 handling. It binds to loopback by default and accepts `HOST` and `PORT` configuration. This mode is for development/diagnostics only; it is not the production desktop IPC boundary and must never expose broker/account operations.

## Broker adapter

The read-only Capital.com adapter source contains authenticated REST session and historical-price methods plus WebSocket quote/OHLC subscriptions. It is not registered in the HTTP router or the stdio IPC method allowlist, is not wired to the macOS application, and cannot retrieve credentials until the native Keychain provider and a separately reviewed secret-transfer contract are implemented.

Do not interpret a healthy backend process, a successful IPC ping, or adapter source as proof of broker connectivity. No real Demo account session, quote, or candle has yet been verified.

## Build and test

Run `npm ci`, `npm run build`, and `npm test`. The test suite uses Node.js built-in `node:test`.

## Security boundaries

- The native macOS application owns Keychain access.
- The Node.js backend has no direct Keychain access.
- No credential is passed through command-line arguments, environment variables, source files, or logs.
- No production TCP listener or filesystem socket is part of the selected desktop IPC design.
- The stdio protocol initially exposes no broker, account, credential, risk, order, or execution methods.
- Any future exposure-increasing intent remains subject to the centralized Risk Engine; the Execution Gateway remains the only dealing path.
