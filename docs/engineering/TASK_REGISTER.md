# Engineering Task Register

**Last reconciled:** 2026-11-14  
**Latest observed main baseline:** `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed` (PR #47 merge, 2026-11-14)  
**Open implementation PR branches:** `feat/atp-ux-001-clipboard-and-broker-polish` (PR #31); `fix/atp-persist-003-local-postgres-runner` (PR #35).  
**Local worktree:** not inspected in this GitHub review; preserve all local changes and stashes until its branch/commit/status are explicitly reconciled.

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
| ATP-CAP-SESSION-001 | Capital.com encrypted Demo session and market-data bridge | PR #19 merged as `b673d639bf5440ddd52085815bf7cf2a4fd54167`; Node CI 31/31; target-Mac, crypto interoperability, packaged runtime, and real Demo verification pending | DONE — MERGED; PENDING VERIFICATION |
| ATP-MD-WATCH-001 | Shared multi-instrument Market Watch and quote freshness | PR #21 merged as `3fed5711393059d4e089a5209b55f5fef5d8860b`; Node CI and target-Mac/Demo verification pending | DONE — MERGED; PENDING VERIFICATION |
| ATP-CAP-ACCOUNT-001 | Read-only Capital.com account, preferences, positions, and working orders | PR #29 merged as `794e9c5854bba45c5b007b44de697b030f3b72a8`; CI 46/46 | DONE — MERGED; MOCK-TESTED |

## Active milestone

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-PERSIST-001 | PostgreSQL persistence foundation — Stage 1 schema and migration baseline | Domain-owned PostgreSQL schemas; durable OMS intent, event, idempotency, and outbox records per ATP-ARCH-003 / ATP-ARCH-019 | IN PROGRESS — migration authored on feature branch; not executed against PostgreSQL |
| ATP-EXEC-001 | Automated trading execution foundation — Batch 1: centralized pre-trade Risk Engine | Pure BUY/SELL intent risk evaluation; broker quote/account freshness; stop-loss risk, gross exposure, position-count and free-margin checks | DONE — MERGED in PR #27; pure evaluator not yet integrated with OMS/Execution Gateway |

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
- Read-only Capital.com account, account-preferences, open-position, and working-order retrieval is being added in ATP-CAP-ACCOUNT-001; durable reconciliation/persistence remain unimplemented.
- LIVE, order, dealing, and execution methods remain absent. All future exposure-increasing intents must pass through centralized Risk Engine and OMS authorization.

## Planned implementation sequence after the initial broker session

| ID | Milestone | Dependency / scope | Status |
|---|---|---|---|
| ATP-BE-RUNTIME-001 | Backend runtime and composition root | Lifecycle, configuration validation, dependency construction, startup/shutdown, readiness aggregation | PLANNED |
| ATP-MD-IPC-001 | Expose Capital.com WebSocket quote/OHLC events over IPC | Event envelope, subscription lifecycle, reconnect state, and Swift event consumption | IN PROGRESS — source integrated; target verification pending |
| ATP-MD-ENGINE-001 | Market Data ingestion and quality engine | Normalize REST/stream observations; timestamps, deduplication, gaps, freshness, OHLC validation, recovery | PLANNED |
| ATP-UX-CLIPBOARD-001 | Application-wide selectable text and native clipboard behavior | Root `NavigationSplitView` applies `.textSelection(.enabled)`; native editable controls retain paste/edit behavior; PR #34 merged | DONE — MERGED; per-row/context copy remains feature-specific |
| ATP-CAP-ACCOUNT-001 | Read-only broker account and trading-state snapshots | GET /accounts, /accounts/preferences, /positions, /workingorders; typed parsing, observation timestamps, read-only IPC | DONE — MERGED in PR #29; 46/46 Node tests passed |
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

ATP-CAP-ACCOUNT-001 is merged as PR #29; Node.js 24.22.2 CI passed TypeScript compilation and 46/46 tests. ATP-PERSIST-001 Stage 1 is now active on `feat/atp-persist-001-postgres-foundation`, based on main `794e9c5854bba45c5b007b44de697b030f3b72a8`. Initial PostgreSQL schema and scope documentation are authored but not executed. This follows ATP-ARCH-003's approved sequence: database/migration baseline before OMS persistence. Next: review the schema, add a pinned PostgreSQL client and checksum-verified migration runner, and execute PostgreSQL integration tests. Then implement ATP-OMS-001 durable state transitions and idempotency. No broker dealing or LIVE capability is introduced.

## Change log

- 2026-11-13: Added ATP-MD-WATCH-001 on `feat/atp-market-data-watchlist-main`, based directly on main after PR #19 was merged. Draft PR #21 is open; the earlier stacked PR #20 was closed as superseded. Added shared persisted watchlist, multi-epic subscriptions, cross-screen Market Watch display, quote normalization/freshness classification, and corrected the Xcode SRCROOT script expansion. CI, target-Mac Xcode build, and real Demo quote delivery remain pending. Added ATP-UX-CLIPBOARD-001 as a separate planned milestone.

- 2026-11-13: PR #18 merged as `675ea4af4d54610539218858e3d2f99c4c9a1985`. ATP-CAP-SESSION-001 was merged through PR #19 as `b673d639bf5440ddd52085815bf7cf2a4fd54167`; encrypted IPC v2, Demo REST session lifecycle, market search/history, WebSocket event IPC, and Xcode backend packaging are now in main. Target-Mac, crypto interoperability, packaged runtime, and real Demo verification remain pending.

- 2026-11-13: PR #17 merged ATP-CAP-UI-001 as `9297f28fd2079dc5801cd89baf2b4723ed625a75`; PR #18 subsequently merged ATP-CAP-UI-002 as `675ea4af4d54610539218858e3d2f99c4c9a1985`.

- 2026-11-12: PR #14 merged as `9445a749d78c63030e9125041a6103dca0eabafc`; ATP-ARCH-REBASE-001 completed.
- 2026-11-12: ATP-SEC-IPC-001 backend stdio protocol merged through PR #15 as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`.
- 2026-11-12: Started `security/atp-sec-ipc-001-swift-supervisor`; native Swift IPC source, XCTest source, Xcode membership, and signed bundle layout contract authored. PR #16 subsequently merged as `f13ce0e3f8157a4901c99b8d928f2540cd213adc`; verification pending.
- 2026-11-13: Added ATP-CAP-UI-001 on the same branch: Capital.com broker screen, Keychain credential store, sidebar destination, and Xcode target registration. Verification and PR #17 pending.
- 2026-11-13: Added ATP-CAP-UI-001 on the same active branch: Capital.com broker screen, Keychain credential store, sidebar destination, and Xcode target registration. PR #17 merged ATP-CAP-UI-001; PR #18 merged ATP-CAP-UI-002. Xcode build and UI/Keychain tests remain pending.


- 2026-11-13: ATP-EXEC-001 Batch 1 merged through PR #27 as `df85a423b30ce72d4106c281566cf9797031dfef`. The pure centralized pre-trade RiskEngine and freshness hardening are now on main; it remains unintegrated with OMS/Execution Gateway. Backend CI run 43358303256 for ATP-CAP-ACCOUNT-001 passed TypeScript compilation and all 46 backend tests.


### ATP-CAP-ACCOUNT-001 — read-only broker trading-state snapshots

- Base: `main` at `df85a423b30ce72d4106c281566cf9797031dfef`, after PR #27 merged.
- Branch: `feat/atp-cap-account-001-readonly-snapshots`.
- Scope: typed read-only REST parsing for accounts, account preferences, open positions, and working orders; backend runtime delegation; explicit IPC allowlist; mock-based client and IPC tests.
- Official API endpoints: `GET /api/v1/accounts`, `GET /api/v1/accounts/preferences`, `GET /api/v1/positions`, and `GET /api/v1/workingorders`.
- Account `balance.available` is preserved as-is and is not assumed to equal RiskEngine free margin.
- No account mutation, order creation, dealing, position amendment/closure, OMS, persistence, SwiftUI display, or LIVE capability is added in this batch.
- Draft PR #29: https://github.com/atheertrading/AtheerAutotrade/pull/29.
- GitHub Actions Backend CI run 43358303256 passed on Node.js 24.22.2: TypeScript build passed; 46 tests passed, 0 failed, 0 skipped.
- No local Node run, Xcode build, target-Mac runtime, or real Capital.com Demo account read is claimed.


## UI milestone — ATP-UI-DASHBOARD-001

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-UI-DASHBOARD-001 | Operational Dashboard presentation | Feature branch `feat/atp-dashboard-001-operational-dashboard`; `DashboardView.swift` reorganized into Account Overview, Market Watch, Operational Status and System Activity; implementation record `docs/engineering/ATP-UI-DASHBOARD-001.md` | IMPLEMENTED — PENDING XCODE BUILD AND TARGET-MAC VERIFICATION |

- Dashboard uses existing `MarketDataStore` values for broker session, stream status, watchlist and quotes.
- Account Balance, Equity, Available Margin and Exposure are explicitly unavailable until account snapshots are wired into the UI; no placeholder financial values are fabricated.
- Automated execution and PostgreSQL runtime are explicitly shown as not connected.
- Existing Capital.com connection, credential, IPC and quote subscription source paths were not changed.
- Dashboard text selection is enabled; application-wide text selection was already merged in PR #34.
- This feature branch does not modify `main`. Merge only after review and target-Mac build/runtime verification.


## Newly accepted architecture standard

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-ARCH-OOP-001 | Project-wide Object-Oriented Design Standard | ADR-0006, language-specific Swift/TypeScript conventions, bounded-context directory/file conventions, object contract checklist, and incremental conformance policy | DONE — DOCUMENTED; EXISTING-CODE CONFORMANCE NOT YET AUDITED |

**Next action:** assess each existing bounded context against docs/architecture/OOP_DESIGN_STANDARD.md. Record Conformant / Partially conformant / Not assessed / Blocked with path-level evidence. Refactor only within scoped implementation milestones; preserve existing behavior and Xcode project membership.


## ATP-ARCH-OOP-002 — source-code OOP conformance audit

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-ARCH-OOP-002 | Comprehensive source-code audit against ADR-0006 and OOP_DESIGN_STANDARD.md | Inventory and inspect each active module; assess responsibility concentration, abstraction, encapsulation, dependency direction, lifecycle, testability, and directory/file ownership; record path-level evidence and staged remediation priorities | IN PROGRESS — initial critical-path audit recorded; full repository/module inventory and remaining source reviews pending |

- Audit report: [ATP-ARCH-OOP-002 Source Conformance Audit](ATP-ARCH-OOP-002-SOURCE-CONFORMANCE-AUDIT.md).
- Initial reviewed modules: macOS MarketDataStore, BackendProcessSupervisor, CapitalComBrokerView; backend stdio IPC, CapitalComRuntime, CapitalComClient, IPCSecretChannel, and RiskEngine.
- Initial assessment: state/orchestration modules are predominantly Partially conformant; IPCSecretChannel and RiskEngine are Conformant for the inspected responsibilities. Other modules remain Not assessed until complete source review.
- No source refactor, directory move, runtime change, or trading permission change is included in this audit stage.
- Next: complete source inventory and inspect each remaining active module, its callers, tests, and composition boundary before defining module-specific refactors.


## ATP-ARCH-OOP-003 — Explicit backend IPC composition

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-ARCH-OOP-003 | Remove concrete broker-runtime construction from stdio IPC and establish an explicit composition-root boundary | Introduce a broker capability contract, inject the runtime, compose CapitalComRuntime in server.ts, and cover the boundary with deterministic test doubles | DONE — MERGED in PR #47 at `64025fd`; Backend CI 51/51 passed; target-Mac verification pending |

- Branch: `refactor/atp-arch-oop-003-stdio-composition`, based on `main`.
- Changed source: `services/backend/src/api/stdio-ipc.ts`, `services/backend/src/server.ts`.
- Updated tests: `services/backend/tests/stdio-ipc.test.mjs`.
- Added implementation record: `docs/engineering/ATP-ARCH-OOP-003-STDIO-COMPOSITION.md`.
- The transport no longer constructs a concrete CapitalComRuntime or hides that dependency in a default parameter. The composition root owns construction and lifecycle handoff.
- IPC protocol v2, method names, payload validation, capability negotiation, encrypted one-shot credentials, read-only broker methods, and disconnect-on-session-exit behavior are preserved.
- No order/dealing method, RiskEngine bypass, LIVE capability, or trading permission was added.
- GitHub Actions Backend CI run 43528019119 passed on Node.js 24.22.2: TypeScript build passed; 51/51 Node tests passed. No local build or test has been run by this GitHub-only change.
- Next: inspect CI evidence and resolve any failures before starting the next bounded remediation.


## Current open implementation work — reconciled 2026-11-14

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-BASELINE-001 | Source-of-truth and engineering-record reconciliation | PR #48 documentation changes are present on `main`; PR #50 governance instructions merged at `d44e184d998b719289c42159db138073d3213584` | DONE — merged to main |
| ATP-UX-001 | Broker workspace, clipboard, and trading UI clarity | PR #52; branch `feat/atp-ux-001-current-main`; six SwiftUI/UI audit files ported to current main; PR #31 closed unmerged as superseded; no target-Mac Xcode acceptance evidence | IMPLEMENTED ON CURRENT-MAIN BRANCH — DRAFT; TARGET-MAC XCODE/UI ACCEPTANCE REQUIRED |
| ATP-PERSIST-003 | Enforce local PostgreSQL and correct migration execution | PR #51; branch `fix/atp-persist-003-current-main`; 4 commits ahead / 0 behind main; Backend CI run 43535924779 passed TypeScript build and 52/52 tests; PR #35 closed unmerged as superseded; no local PostgreSQL database or migration execution | SOURCE IMPLEMENTED AND CI VERIFIED; PostgreSQL NOT IMPLEMENTED OPERATIONALLY — owner-Mac provisioning, schema reconciliation, and real integration tests remain pending |

### Current branch and architecture notes

- PR #45 (ADR-0006), PR #46 (initial ATP-ARCH-OOP-002 audit), and PR #47 (ATP-ARCH-OOP-003) are merged.
- ATP-ARCH-OOP-002 remains IN PROGRESS; the initial review is not a whole-repository conformance result.
- PR #31 was closed unmerged as superseded by current-main-based PR #52; its original branch/history was preserved.
- PR #35 was closed unmerged as superseded by current-main-based PR #51; its original branch/history was preserved. The confirmed `\\gexec` defect is fixed and CI passes, but no local PostgreSQL database or migration has been executed.
- Current-main source contains a pure RiskEngine evaluator but no integrated RiskEngine → OMS → Execution Gateway path.
- No real order/dealing method or LIVE capability is present in main.


## Owner instruction governance and current work reconciliation — 2026-11-14

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-GOV-001 | Persist owner-approved project instructions in GitHub | PR #50 merged as `d44e184d998b719289c42159db138073d3213584`; custom instructions are normative and loaded first by root `AGENTS.md` | DONE — MERGED TO MAIN |
| ATP-EXEC-002 | Capital.com market dealing adapter | PR #53; branch `feat/atp-exec-002-current-main`; 8 commits ahead / 0 behind current main; adapter and tests ported from PR #49; CI pending on current-main port | IMPLEMENTED ON CURRENT-MAIN BRANCH — DRAFT; NOT AN OPERATIONAL ORDER PATH |
| ATP-UX-001 | Broker workspace, clipboard, and trading UI clarity | PR #52 current-main port; 6 commits ahead / 0 behind main at creation; 5 SwiftUI files and UX audit; PR #31 closed unmerged | IMPLEMENTED ON BRANCH — DRAFT; TARGET-MAC XCODE/UI ACCEPTANCE PENDING |
| ATP-PERSIST-003 | Local PostgreSQL migration runner | PR #51 Draft; branch 4 ahead / 0 behind main; CI run 43535924779 passed TypeScript build and 52/52 tests; PR #35 closed unmerged as superseded; no database provisioned and no migration executed | SOURCE IMPLEMENTED AND CI VERIFIED; DATABASE NOT IMPLEMENTED OPERATIONALLY — local provisioning and integration gates pending |
| ATP-BASELINE-001 | Documentation reconciliation | PR #48 changes are present in current main baseline `d5a82dc236ceed9987b4ab86d168e7a8da40f814` | DONE — MERGED |

### Mandatory dependency order

1. ATP-GOV-001 is merged. All subsequent work must load the owner-approved project instructions through `AGENTS.md`.
2. Review and complete ATP-PERSIST-003 PR #51 only after the schema ownership mapping is resolved and owner-Mac PostgreSQL integration tests pass; do not claim PostgreSQL implemented until the local database is provisioned and real migrations/integration checks pass.
3. Reconcile ATP-EXEC-002 with the accepted order architecture. Its adapter method is only an infrastructure primitive; do not expose it until durable OMS, mandatory RiskEngine authorization, Execution Gateway, and broker reconciliation are implemented.
4. Reconcile ATP-UX-001 and obtain target-Mac Xcode/UI acceptance. Do not merge it based only on backend CI.
5. After these dependencies are resolved, select the next milestone from the current architecture/task register. No wholesale rewrite or project restart.


### ATP-PERSIST-003 current-main port — 2026-11-14

- PR #35 was closed unmerged as superseded; its branch/history was preserved and not force-pushed.
- PR #51: https://github.com/atheertrading/AtheerAutotrade/pull/51 — branch `fix/atp-persist-003-current-main`, based on current main, 4 commits ahead / 0 behind.
- Corrected the JavaScript template-literal escaping so psql receives the literal `\\gexec` meta-command. The unit test now asserts the generated string contains the actual backslash command.
- GitHub Actions Backend CI run `43535924779` passed on Node.js 24.22.2: TypeScript build passed; 52 tests passed, 0 failed, 0 skipped.
- PR #51 remains Draft. No PostgreSQL server was provisioned and no migration was applied. Schema ownership mismatch between ATP-ARCH-003 and migration 0001 remains an explicit blocker before the first application.


## ATP-PERSIST-004 — PostgreSQL schema ownership mapping

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-PERSIST-004 | Resolve ATP-ARCH-003 schema ownership before first migration | `docs/engineering/ATP-PERSIST-004-SCHEMA-OWNERSHIP-PROPOSAL.md`; recommends `oms` for initial intent/idempotency/event/outbox tables and `atheer` only for platform migration metadata | PROPOSED — OWNER APPROVAL REQUIRED; migration 0001 must not be applied until decided |

- Options assessed: domain-owned schema mapping (recommended), retain generic `trading` schema (not recommended), or split every initial object across all domains immediately (not recommended).
- No SQL or database was changed by this proposal.
- On approval, correct the still-unapplied migration 0001 with a forward-safe pre-installation update, update migration docs, and then complete owner-Mac PostgreSQL integration tests.


## ATP-UX-001 current-main port — 2026-11-14

- Old PR #31 closed unmerged as superseded; no history was rewritten or force-pushed.
- Current-main branch `feat/atp-ux-001-current-main`, draft PR #52: https://github.com/atheertrading/AtheerAutotrade/pull/52.
- Ported adaptive broker layout, Dashboard quote-state clarity, Market Watch native copy context menu, ATHEER Trading Pro sidebar branding, Workspace status wording, and the UI/UX audit.
- No target-Mac Xcode build or UI acceptance has been performed. Keep PR #52 Draft until the acceptance checklist passes on the owner's Mac.


## ATP-EXEC-002 current-main port — 2026-11-14

- Old PR #49 closed unmerged as superseded; no history was rewritten or force-pushed.
- Current-main-based branch `feat/atp-exec-002-current-main`, draft PR #53: https://github.com/atheertrading/AtheerAutotrade/pull/53. Branch comparison: 8 commits ahead / 0 behind main.
- Ported CapitalComClient market-position submission and broker confirmation methods, explicit DEMO-only and session guards, unknown-outcome handling, and deterministic mock tests.
- Added ADR-0007 and ATP-EXEC-002 implementation record. No order method is exposed through IPC/UI/strategy/AI; OMS/RiskEngine/Execution Gateway/durable reconciliation remain incomplete.
- The previous PR #49 CI passed 62/62 tests, but PR #53 must pass CI on its own current-main head before merge. No real broker order was submitted.
