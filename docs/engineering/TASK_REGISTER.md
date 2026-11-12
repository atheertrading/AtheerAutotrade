# Engineering Task Register

**Last reconciled:** 2026-11-12  
**Latest observed main baseline:** `9445a749d78c63030e9125041a6103dca0eabafc`  
**Active branch:** `security/atp-sec-ipc-001-stdio-boundary`

## Status definitions

- **DONE — MERGED:** Change is present in the repository.
- **DONE — VERIFIED:** Acceptance criteria were tested and evidence is recorded.
- **IN PROGRESS:** Implementation is underway; acceptance criteria are not yet met.
- **PENDING VERIFICATION:** Implementation is present, but required results are not confirmed.
- **PLANNED:** Not implemented.
- **BLOCKED:** Cannot proceed until a named dependency is resolved.
- **SUPERSEDED:** Replaced by a later decision or implementation.

## Completed milestones

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-WS-001 | Connect Trading Workspace to application shell | PR #1 merged | DONE — MERGED |
| ATP-WS-002 | Responsive workspace panel allocation | PR #2 merged | DONE — MERGED |
| ATP-WS-003 | Workspace panel management controls | PR #3 integrated through PR #2 | DONE — MERGED |
| ATP-WS-004 | Workspace resizing and controlled panel drag/drop | PR #4 merged; user reported successful build | DONE — MERGED |
| ATP-WS-005 | Deterministic panel ordering invariants | PR #5 merged; user reported successful build | DONE — MERGED |
| ATP-TEST-001 | Establish hosted XCTest target and four WorkspaceManager tests | PR #6 merged | DONE — MERGED |
| ATP-TEST-002 | Correct XCTest group path | PR #7 merged | DONE — MERGED |
| ATP-TEST-003 | Enable app Debug testability and correct Swift key paths | PR #8 merged as `b18b0ff` | DONE — MERGED |
| ATP-APPLE-001 | Configure Apple Development signing and resolve XCTest bundle signing | User confirmed Build Succeeded; Codex reported app/test signatures valid and 4 XCTest passed, 0 failed on x86_64 | DONE — LOCAL VERIFIED; GitHub publication not confirmed |
| ATP-DOM-001 | Provider-neutral instrument domain model | PR #11 squash-merged as `fa68db5`; user reported TypeScript build and 10 backend tests passed | DONE — MERGED AND USER-VERIFIED |
| ATA-DOC-001 | Preserve adapted Mermaid architecture catalogue | PR #13 merged as `58766938`; ten editable diagrams with provenance and target-architecture caveats | DONE — MERGED |
| ATP-ARCH-REBASE-001 | Establish ATHEER Trading Pro product identity and modular-monolith architecture baseline | ADR-0004 and aligned architecture/security/engineering docs; PR #14 squash-merged as `9445a749d78c63030e9125041a6103dca0eabafc` | DONE — MERGED; no runtime build required |

## Active milestone

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-SEC-IPC-001 | Secure local application/backend boundary and credential-provider design | Select transport, define threat model and protocol, implement bounded backend stdio protocol, then integrate native app process/client and Keychain ownership | IN PROGRESS — Batch 1 protocol and ADR authored; runtime integration pending |

Branch: `security/atp-sec-ipc-001-stdio-boundary`.

### Batch 1 changes on active branch

- `docs/decisions/ADR-0005-SECURE-MACOS-IPC.md` — accepted parent-owned anonymous standard-I/O pipe design and threat model.
- `docs/security/LOCAL_IPC_PROTOCOL.md` — versioned NDJSON protocol contract.
- `services/backend/src/api/stdio-ipc.ts` — bounded protocol handler with handshake, ping, strict envelope validation, UUID and duplicate checks, 65,536-byte frame cap, 4,096-request session limit, allowlist, and safe errors.
- `services/backend/tests/stdio-ipc.test.mjs` — focused framing, handshake, duplicate, payload, malformed-frame, version, size, and child-process startup tests.
- Updated security baseline, architecture overview/diagrams, decision index, backend README, and implementation status.

### Explicitly not implemented in Batch 1

- The stdio protocol handler is wired into `server.ts` through explicit `--transport=stdio` mode; HTTP remains the default development/diagnostic mode.
- No Swift `Process` launcher, pipe client, or Xcode project integration exists.
- No bundled Node.js runtime or signed backend packaging exists.
- No Keychain provider or credential-transfer method exists.
- No broker, account, risk, order, or execution method is exposed.
- A child-process integration test exercises the stdio startup path; no build or test result has been observed for the new IPC code yet.

### ATP-SEC-IPC-001 acceptance criteria

1. Production desktop mode uses parent-owned anonymous stdio pipes and opens no TCP listener or filesystem socket.
2. Parent owns backend process launch, handshake, supervision, shutdown, and restart.
3. Stdout is protocol-only; stderr is sanitized diagnostics.
4. Protocol version, frame size, request IDs, duplicate handling, session limits, method allowlist, and error responses are enforced.
5. Native Swift client rejects protocol mismatch, invalid frames, unknown IDs, oversized responses, and child termination.
6. Backend is packaged as a known signed runtime; no arbitrary PATH-based Node executable.
7. Native macOS application owns Keychain access; any secret handoff is separately scoped, memory-only, and audited.
8. No broker, account, order, or execution capability is exposed until subsequent milestones.
9. Backend tests and macOS build/runtime tests pass on the supported development Mac and toolchain.
10. No credentials are committed, logged, or passed through process arguments/environment; LIVE remains disabled.

## Planned implementation sequence after IPC

| ID | Milestone | Dependency / scope | Status |
|---|---|---|---|
| ATP-BE-RUNTIME-001 | Backend runtime and composition root | Lifecycle, configuration validation, dependency construction, startup/shutdown, readiness aggregation | PLANNED |
| ATP-CAP-LIFECYCLE-001 | Capital.com read-only session lifecycle integration | Verified IPC + native Keychain provider + explicit secret transfer; auth and ping | PLANNED |
| ATP-MD-ENGINE-001 | Market Data ingestion and quality engine | Normalize REST/stream observations; timestamps, deduplication, gaps, freshness, OHLC validation, recovery | PLANNED |
| ATP-DOM-PERSIST-001 | Durable domain and audit persistence | Domain event contracts, migrations, append-oriented audit, recovery and idempotency foundations | PLANNED |
| ATP-RISK-001 | Central Risk Engine | Mandatory evaluation for every exposure-increasing intent; policy and reason codes | PLANNED |
| ATP-OMS-001 | Order Management System | Durable lifecycle, outbox/idempotency, unknown outcomes, broker reconciliation | PLANNED |
| ATP-EXEC-001 | Controlled Execution Gateway | Broker dealing only after OMS + Risk authorization; explicit user approval and safety gates | PLANNED |
| ATP-STRAT-001 | Strategy Runtime | Signals only; no direct execution authority | PLANNED |
| ATP-PORT-INTEL-001 | Portfolio, reconciliation, and advisory intelligence | Broker-authoritative state and advisory-only AI | PLANNED |
| ATP-SYSTEM-VERIFY-001 | End-to-end operational validation | Integration, recovery, security, safety, performance, and sustained broker evidence | PLANNED |

## Other pending verification

| ID | Item | Evidence | Status |
|---|---|---|---|
| ATP-CAP-001-BUILD | Compile adapter and run focused tests | Adapter source/tests merged; current result not observed in this session | PENDING VERIFICATION |
| ATP-CAP-001-DEMO | Verify actual Capital.com Demo authentication and market data | No real session or broker-originated quote/candle evidence | PLANNED |
| ATP-MAC-ARM64-001 | Validate native app runtime on Apple Silicon | Prior runtime verification was x86_64 | PLANNED |

## Preservation and safety constraints

- Preserve local files, local changes, and stashes; GitHub work does not imply local synchronization.
- Do not overwrite local project files with GitHub versions.
- Do not repeat Xcode tests for backend-only work without a technical reason.
- No credentials in ChatGPT, source, Git, logs, process arguments, or environment variables.
- LIVE dealing remains disabled; no real trade without explicit user approval.

## Current next action

Implement Batch 2: wire the stdio transport into a dedicated backend production mode, preserve HTTP health only as a development diagnostic mode, add process-level stream tests, then implement the native Swift process supervisor and NDJSON client. Verify Node 24 build/tests and the macOS build on the user's actual development Mac.

## Change log

- 2026-11-12: PR #14 merged as `9445a749d78c63030e9125041a6103dca0eabafc`; ATP-ARCH-REBASE-001 completed.
- 2026-11-12: Started ATP-SEC-IPC-001 on `security/atp-sec-ipc-001-stdio-boundary`; ADR-0005, protocol contract, backend handler, and focused tests authored.
