# Engineering Task Register

**Last reconciled:** 2026-11-13  
**Latest observed main baseline:** `f13ce0e3f8157a4901c99b8d928f2540cd213adc`  
**Active branch:** `fix/atp-cap-credentials-restore`

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
| ATP-SEC-IPC-001-B1B2 | Backend stdio protocol and production transport mode | PR #15 merged as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`; backend build/tests remain unverified | DONE — MERGED; PENDING VERIFICATION |\n| ATP-CAP-UI-001 | Capital.com broker screen and Keychain credential entry | PR #17 merged as `9297f28fd2079dc5801cd89baf2b4723ed625a75`; Xcode/UI/Keychain runtime verification pending | DONE — MERGED; PENDING VERIFICATION |

## Active milestone

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-SEC-IPC-001 | Secure local application/backend boundary and credential-provider design | Select transport, define threat model and protocol, implement bounded backend stdio protocol, then integrate native app process/client and Keychain ownership | IN PROGRESS — native Swift IPC source and Xcode membership authored; compile/runtime verification and packaging pending |

Merged backend foundation: PR #15, commit `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`.

Native Swift IPC supervisor: PR #16, merged as `f13ce0e3f8157a4901c99b8d928f2540cd213adc`.

Current implementation branch: `fix/atp-cap-credentials-restore` (ATP-CAP-UI-002 correction only). PR #17 merged the original Capital.com UI into main.

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

### Batch 3 — native Swift IPC client (source authored; verification pending)

- `apps/macos/Sources/Core/Backend/LocalIPCProtocol.swift` — strict NDJSON request encoder, response-envelope validation, and incremental bounded frame decoder.
- `apps/macos/Sources/Core/Backend/BackendProcessSupervisor.swift` — child-process launch from a fixed app-bundle path, anonymous stdio pipes, handshake/capability validation, request correlation, timeout handling, stdout parsing, stderr draining, and termination handling.
- `apps/macos/Tests/LocalIPCProtocolTests.swift` — framing, envelope, size-limit, and protocol-version tests authored.
- `apps/macos/AtheerAutotrade.xcodeproj/project.pbxproj` — both source files and the XCTest file registered in their targets.
- `docs/security/MACOS_BACKEND_BUNDLE_LAYOUT.md` — expected signed runtime/backend layout and packaging gates.
- No Xcode build/test, Node build/test, runtime packaging, or child-process execution has been performed for this batch. No Keychain provider, credential handoff, or Capital.com credential UI has been added.

### ATP-CAP-UI-001 — Capital.com broker screen (merged in PR #17; verification pending)

- `apps/macos/Sources/Features/Brokers/CapitalComBrokerView.swift` — Capital.com screen with broker status, DEMO environment, LIVE lock state, API key/identifier/password fields, save/remove controls, restoration of saved credentials on appearance, retention of values after Save, connection readiness, and disabled Connect control until IPC credential handoff is verified.
- `apps/macos/Sources/Core/Security/CapitalComCredentialStore.swift` — stores the three credentials as one Keychain generic-password item; supports typed `load()`, device-only unlocked accessibility for new items, and read-back verification after both insert and update; does not persist secrets in preferences or files.
- `WorkspaceSection.swift`, `SidebarView.swift`, and `ApplicationShellView.swift` — expose the screen in the application sidebar under **BROKER CONNECTIONS → Brokers**.
- `project.pbxproj` — registers both Swift files and their groups in the app target.
- The UI baseline is merged into `main` via PR #17. It has not been built or run on the target Mac in this verification cycle. Credential transfer and actual broker authentication remain disabled.

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

### ATP-CAP-UI-002 — Credential restoration and Keychain verification (PR #18; pending)

- Add Keychain `load()` with explicit missing-item, malformed-data, and OSStatus handling.
- Verify the stored credential payload after both Keychain insert and update.
- Restore saved values when the broker screen appears; do not clear fields after Save.
- Clear form state only after explicit credential removal.
- PR #18 is draft. Source has been read back from GitHub; Xcode build and Keychain runtime tests remain pending on the target Mac.

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

First compile and verify PR #18's Keychain load/save/restore/delete paths and the Capital.com screen on the user's actual Mac. Then finish signed runtime/backend packaging, packaged IPC verification, and the one-shot credential-transfer contract. Enable broker connection only after those gates pass.

## Change log

- 2026-11-13: PR #17 merged ATP-CAP-UI-001 as `9297f28fd2079dc5801cd89baf2b4723ed625a75`. Opened draft PR #18 for ATP-CAP-UI-002: Keychain read-back/load, insert/update verification, saved-field restoration, and retaining fields after Save. Xcode verification remains pending.

- 2026-11-12: PR #14 merged as `9445a749d78c63030e9125041a6103dca0eabafc`; ATP-ARCH-REBASE-001 completed.
- 2026-11-12: ATP-SEC-IPC-001 backend stdio protocol merged through PR #15 as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`.
- 2026-11-12: Started `security/atp-sec-ipc-001-swift-supervisor`; native Swift IPC source, XCTest source, Xcode membership, and signed bundle layout contract authored. PR #16 subsequently merged as `f13ce0e3f8157a4901c99b8d928f2540cd213adc`; verification pending.
- 2026-11-13: Added ATP-CAP-UI-001 on the same branch: Capital.com broker screen, Keychain credential store, sidebar destination, and Xcode target registration. Verification and PR #17 pending.
- 2026-11-13: Added ATP-CAP-UI-001 on the same active branch: Capital.com broker screen, Keychain credential store, sidebar destination, and Xcode target registration. PR #16 remains draft; Xcode build and UI/Keychain tests are pending.
