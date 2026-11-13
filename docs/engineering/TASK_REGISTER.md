# Engineering Task Register

**Last reconciled:** 2026-11-13  
**Latest observed main baseline:** `b673d639bf5440ddd52085815bf7cf2a4fd54167`  
**Active branch:** `feat/atp-market-data-watchlist-main`

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
| ATP-SEC-IPC-001-B1B2 | Backend stdio protocol and production transport mode | PR #15 merged as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`; backend build/tests remain unverified | DONE — MERGED; PENDING VERIFICATION |
| ATP-CAP-UI-001 | Capital.com broker screen and Keychain credential entry | PR #17 merged as `9297f28fd2079dc5801cd89baf2b4723ed625a75`; Xcode/UI/Keychain runtime verification pending | DONE — MERGED; PENDING VERIFICATION |
| ATP-CAP-UI-002 | Keychain credential restoration and read-back verification | PR #18 merged as `675ea4af4d54610539218858e3d2f99c4c9a1985`; Xcode/Keychain runtime verification pending | DONE — MERGED; PENDING VERIFICATION |

## Active milestone

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-CAP-SESSION-001 | Operational Capital.com Demo session over encrypted local IPC | Ephemeral X25519/HKDF/AES-256-GCM credential transfer, backend session lifecycle, authenticated ping, status, market search, historical prices, WebSocket quote/OHLC event IPC, Xcode runtime packaging, functional UI | IN PROGRESS — Node 24 CI passed (31/31); Xcode/crypto interoperability/packaged runtime/real Demo verification pending |
| ATP-MD-WATCH-001 | Shared multi-instrument Market Watch and quote freshness | Persistent watchlist, multi-epic Capital.com subscriptions, shared quote events across screens, Bid/Ask/Mid/Spread, broker timestamp, receipt timestamp, freshness classification | IN PROGRESS — source implemented; backend CI, Xcode build, and real Demo quote verification pending |

Merged backend foundation: PR #15, commit 8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5.

Native Swift IPC supervisor: PR #16, merged as f13ce0e3f8157a4901c99b8d928f2540cd213adc.

Capital.com broker screen and Keychain persistence: PR #17 and PR #18 are merged into main. PR #19 subsequently merged the encrypted Demo session and market-data bridge; ATP-MD-WATCH-001 builds directly on that main baseline.

### Existing merged IPC baseline

- Backend stdio transport and protocol framing are merged through PR #15.
- Native Swift child-process supervisor and protocol codec are merged through PR #16.
- Protocol v2 on the active branch adds per-child ephemeral X25519 key agreement, HKDF-SHA256, AES-256-GCM encrypted credential transfer, and one-shot credential submission.
- The backend exposes only read-only Demo session connect/disconnect/status, market search, historical-price, and quote/OHLC stream start/stop methods.
- No account mutation, order, dealing, execution, or LIVE method is exposed.

### ATP-CAP-UI-001 / ATP-CAP-UI-002 — merged baseline

- Capital.com broker screen and Keychain credential storage were merged in PR #17.
- Keychain load/read-back verification and restoration of saved fields were merged in PR #18.
- Both remain pending target-Mac Xcode and Keychain runtime verification.

### ATP-CAP-SESSION-001 — active implementation

- services/backend/src/security/ipc-secret-channel.ts — ephemeral X25519 key agreement, HKDF-SHA256, AES-256-GCM decryption, and in-memory key handling.
- services/backend/src/modules/broker-adapters/capital-com/capital-com-runtime.ts — in-memory credentials, Demo session creation, authenticated ping, status, market search, historical prices, and disconnect.
- services/backend/src/api/stdio-ipc.ts — protocol v2 handshake, one-shot encrypted credentials.submit, and read-only broker method allowlist.
- apps/macos/Sources/Core/Backend/IPCSecretChannel.swift — CryptoKit X25519/HKDF/AES-GCM credential encryption.
- apps/macos/Sources/Core/Backend/BackendProcessSupervisor.swift — Keychain load, encrypted one-shot transfer, Demo connect/disconnect, status, market search/history, WebSocket event consumption, and app-termination child shutdown.
- apps/macos/Sources/Features/Brokers/CapitalComBrokerView.swift — active Connect/Disconnect state, authenticated market search, and layered data-protection explanation.
- apps/macos/Scripts/package-backend.sh and Xcode project build phase — Node.js 24 universal runtime and compiled backend packaging into fixed app-bundle paths.
- Added backend Node 24 CI workflow and Node-side encrypted-envelope authentication/one-shot transfer test source; CryptoKit-to-Node interoperability remains pending.
- Node 24 CI run 43332767979 passed TypeScript compilation and 31/31 backend tests. Xcode, CryptoKit/Node interoperability, packaged runtime, and real Capital.com Demo results remain pending.

### Remaining scope and safety boundaries

- WebSocket quote/OHLC adapter is wired through IPC v2 event frames and the macOS UI; actual quote/OHLC delivery and sustained stream behavior remain unverified.
- Initial quote normalization and 5/10/15-second freshness classification are now present in source; end-to-end Demo delivery remains unverified. Full ordering/deduplication, gap detection, OHLC integrity, persistence, and recovery remain unimplemented.
- Broker account/position snapshots and reconciliation remain unimplemented.
- LIVE, order, dealing, and execution methods remain absent. All future exposure-increasing intents must pass through centralized Risk Engine and OMS authorization.

## Planned implementation sequence after the initial broker session

| ID | Milestone | Dependency / scope | Status |
|---|---|---|---|
| ATP-BE-RUNTIME-001 | Backend runtime and composition root | Lifecycle, configuration validation, dependency construction, startup/shutdown, readiness aggregation | PLANNED |
| ATP-MD-IPC-001 | Expose Capital.com WebSocket quote/OHLC events over IPC | Event envelope, subscription lifecycle, reconnect state, and Swift event consumption | IN PROGRESS — source integrated; target verification pending |
| ATP-MD-ENGINE-001 | Market Data ingestion and quality engine | Normalize REST/stream observations; timestamps, deduplication, gaps, freshness, OHLC validation, recovery | PLANNED |
| ATP-UX-CLIPBOARD-001 | Application-wide selectable text and native clipboard behavior | Enable selection/copy for static text across all screens and retain native paste/edit behavior for editable controls; no per-label patches | PLANNED |
| ATP-CAP-ACCOUNT-001 | Read-only broker account and position snapshots | Confirm official Capital.com API contracts, normalize and reconcile broker-authoritative state | PLANNED |
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

Run Node 24 CI for ATP-MD-WATCH-001, then build the macOS target on the target Intel Mac. Verify the packaged child, CryptoKit/Node crypto channel, actual Capital.com Demo session, multi-instrument WebSocket subscriptions, sustained Bid/Ask delivery, and freshness display. Then continue with full Market Data gap/recovery controls, read-only account reconciliation, Risk Engine, OMS, and Execution Gateway. Application-wide copy/paste is a separate planned UI milestone.

## Change log

- 2026-11-13: Added ATP-MD-WATCH-001 on `feat/atp-market-data-watchlist-main`, based directly on main after PR #19 was merged. Draft PR #21 is open; the earlier stacked PR #20 was closed as superseded. Added shared persisted watchlist, multi-epic subscriptions, cross-screen Market Watch display, quote normalization/freshness classification, and corrected the Xcode SRCROOT script expansion. CI, target-Mac Xcode build, and real Demo quote delivery remain pending. Added ATP-UX-CLIPBOARD-001 as a separate planned milestone.

- 2026-11-13: PR #18 merged as `675ea4af4d54610539218858e3d2f99c4c9a1985`. ATP-CAP-SESSION-001 was merged through PR #19 as `b673d639bf5440ddd52085815bf7cf2a4fd54167`; encrypted IPC v2, Demo REST session lifecycle, market search/history, WebSocket event IPC, and Xcode backend packaging are now in main. Target-Mac, crypto interoperability, packaged runtime, and real Demo verification remain pending.

- 2026-11-13: PR #17 merged ATP-CAP-UI-001 as `9297f28fd2079dc5801cd89baf2b4723ed625a75`; PR #18 subsequently merged ATP-CAP-UI-002 as `675ea4af4d54610539218858e3d2f99c4c9a1985`.

- 2026-11-12: PR #14 merged as `9445a749d78c63030e9125041a6103dca0eabafc`; ATP-ARCH-REBASE-001 completed.
- 2026-11-12: ATP-SEC-IPC-001 backend stdio protocol merged through PR #15 as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`.
- 2026-11-12: Started `security/atp-sec-ipc-001-swift-supervisor`; native Swift IPC source, XCTest source, Xcode membership, and signed bundle layout contract authored. PR #16 subsequently merged as `f13ce0e3f8157a4901c99b8d928f2540cd213adc`; verification pending.
- 2026-11-13: Added ATP-CAP-UI-001 on the same branch: Capital.com broker screen, Keychain credential store, sidebar destination, and Xcode target registration. Verification and PR #17 pending.
- 2026-11-13: Added ATP-CAP-UI-001 on the same active branch: Capital.com broker screen, Keychain credential store, sidebar destination, and Xcode target registration. PR #17 merged ATP-CAP-UI-001; PR #18 merged ATP-CAP-UI-002. Xcode build and UI/Keychain tests remain pending.
