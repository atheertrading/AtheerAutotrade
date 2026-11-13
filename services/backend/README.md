# Backend foundation

This Node.js/TypeScript service is the backend modular monolith for ATHEER Trading Pro. It runs as a child process supervised by the native SwiftUI macOS application.

## Runtime modes

### Production desktop mode — stdio IPC v2

The macOS application launches the bundled Node.js runtime and compiled backend from fixed app-bundle paths. Parent-to-child requests use stdin; child-to-parent responses use stdout. Stdout is protocol-only. Stderr is reserved for sanitized diagnostics.

Protocol v2 implements:
- versioned NDJSON handshake, bounded 65,536-byte frames, UUID request IDs, duplicate detection, and a 4,096-request session limit;
- ephemeral X25519 key agreement, HKDF-SHA256, and AES-256-GCM encryption for the one-shot credential payload;
- one credential submission per backend child session, with credentials retained in process memory only;
- read-only Capital.com Demo session creation and authenticated ping;
- broker session status, market search, and historical OHLC retrieval;
- read-only account list/preferences, open positions, and working-order snapshots with local observation timestamps;
- safe error mapping and an explicit method allowlist.

The backend does not access macOS Keychain. The native app loads credentials from Keychain and encrypts them before submitting them to the backend. The backend sends REST requests to Capital.com over HTTPS/TLS and keeps CST/X-SECURITY-TOKEN in memory only.

### Development/diagnostic mode — loopback HTTP

The existing HTTP runtime exposes only process health and structured 404 handling. It binds to loopback by default and is diagnostic-only. It is not the production desktop control channel and must never expose broker operations.

## Capital.com adapter and runtime

The adapter contains:
- REST Demo session creation, authenticated ping, market discovery, and historical prices;
- WebSocket quote and OHLC stream components with keepalive, bounded reconnect, and re-subscription;
- strict response and market-data payload validation.

The current runtime composes the REST client with the encrypted IPC broker lifecycle. WebSocket streaming is surfaced through IPC v2 event frames and the macOS broker screen can start/stop a selected epic's quote and one-minute OHLC subscriptions. The owner reports broker-originated quote delivery working in the local Xcode application; this is owner-reported runtime evidence, not independently reproduced by this review. Market-data freshness is initially classified at quote normalization, but ordering/deduplication, gap detection, continuity recovery, OHLC consumption in the SwiftUI store, and durable history remain incomplete. Read-only account, account-preferences, open-position, and working-order endpoints are exposed through explicit IPC allowlist methods. Account `balance.available` is preserved as documented and is not relabelled as RiskEngine free margin. Account mutation, order creation, dealing, and execution remain absent.

Do not treat source implementation, a successful process handshake, or an IPC ping as proof of a real broker session. The owner reports actual Capital.com Demo authentication and quote delivery locally; independent target-machine verification and sustained continuity testing remain separate acceptance gates.

## Build and test

Run from this directory using Node.js 24:

```sh
npm ci --include=dev
npm test
```

The Xcode project invokes the backend build during app packaging and copies the compiled output and a universal Node.js 24 runtime into the documented bundle paths. Runtime code resolves only the bundled Node executable; PATH is used only at build time. Exact patch-version pinning, code-signature verification, and notarization remain release gates.

## Security boundaries

- macOS Keychain is the source of credentials at rest; the native app owns Keychain access.
- Credential payloads are encrypted over the local IPC pipe with ephemeral X25519/HKDF-SHA256/AES-256-GCM.
- Credentials and session tokens are never passed in process arguments, environment variables, files, stdout, or logs.
- No production TCP listener or filesystem socket is part of the desktop IPC design.
- Only read-only Demo broker methods are exposed. Account and position data are read-only. Account mutation, order creation, dealing, and execution remain disabled.
- Every future exposure-increasing intent must pass through the centralized Risk Engine; the Execution Gateway remains the only dealing path.
