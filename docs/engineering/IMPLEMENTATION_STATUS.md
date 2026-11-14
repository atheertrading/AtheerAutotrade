# Implementation status

**Product identity:** ATHEER Trading Pro  
**Repository / temporary technical identifier:** AtheerAutotrade  
**Status basis:** Repository source inspection and recorded user/test evidence. Source presence is not runtime verification.

## Implemented in source

### macOS application
- Native SwiftUI macOS application target, dark-first navigation shell, and Trading Workspace with panel management, resizing, and drag/drop.
- Capital.com broker screen with DEMO environment, Keychain credential entry/save/restore/delete, connection state, Connect/Disconnect actions, and authenticated market discovery UI.
- Shared MarketDataStore and Markets destination; user watchlists persist locally, support up to 40 Capital.com instruments, and remain subscribed when navigating away from the Brokers screen.
- Dashboard, Markets destination, Brokers screen, and Trading Workspace panel share the same Market Watch table, displaying broker Bid/Ask, derived Mid/Spread, quote age, and freshness state. Dashboard connection indicators are driven by shared broker/feed state rather than hard-coded disconnected labels.
- Native app owns macOS Keychain access. Credential values are not persisted in preferences or project files.
- IPCSecretChannel.swift uses ephemeral Curve25519/X25519 key agreement, HKDF-SHA256, and AES-256-GCM to encrypt the credential payload before it crosses the local app/backend pipe.
- BackendProcessSupervisor.swift starts the backend from fixed app-bundle paths, performs protocol v2 handshake/capability negotiation, correlates requests, applies timeouts, consumes broker market-data events, and supervises child termination. The SwiftUI app delegate requests child shutdown during application termination.
- Historical user evidence: Xcode Build Succeeded on 2026-11-12; four XCTest cases and signing checks were reported passing on x86_64. These results predate the current IPC v2 changes and do not verify this branch.

### Backend foundation
- `risk-engine.ts` now implements a pure pre-trade evaluation boundary for BUY/SELL exposure-increasing intents: validates intent/account/quote/policy inputs; checks quote and account-snapshot freshness; computes stop-loss monetary risk and gross exposure; enforces per-trade risk, aggregate exposure, position-count, and free-margin-reserve limits; returns immutable rejection reason codes. It requires broker-supplied contract multiplier, account-currency monetary inputs, and estimated initial margin. PR #27 is merged to main; the evaluator is not yet wired into OMS, IPC, strategies, UI, or broker dealing.
- Node.js/TypeScript modular backend with diagnostic-only HTTP mode and production desktop stdio transport.
- Protocol v2 supports bounded NDJSON framing, strict envelopes, UUID request IDs, duplicate detection, request limits, and safe errors.
- IpcSecretChannel implements per-child-session X25519/HKDF-SHA256/AES-256-GCM decryption. Credential submission is one-shot per child session; mutable plaintext buffers are cleared after parsing where feasible.
- CapitalComRuntime owns the read-only broker session lifecycle. It accepts validated credentials in memory, establishes a Capital.com Demo REST session, verifies it with authenticated ping, reports status, and exposes market search and historical prices.
- CapitalComClient source supports session creation, authenticated ping, market search, and historical prices. CapitalComMarketDataStream is wired through IPC v2 event frames for quote/OHLC subscriptions, keepalive, reconnect, and re-subscription.
- `market-data-quality.ts` validates broker Bid/Ask and timestamps, derives Mid and Spread without synthesizing executable prices, records broker and local receipt timestamps, and classifies quote age using the 5/10/15-second policy.
- The backend stores CST and X-SECURITY-TOKEN only in process memory. Capital.com REST uses HTTPS/TLS.
- No broker dealing, order, position mutation, account mutation, or LIVE method is exposed.

### Persistence foundation — ATP-PERSIST-001 (active branch)
- Authored `services/backend/migrations/0001_trading_oms_foundation.sql` on `feat/atp-persist-001-postgres-foundation`.
- The migration defines PostgreSQL schemas and initial tables for scoped idempotency records, canonical trade intents, append-oriented order events, and a durable command outbox.
- Quantities use PostgreSQL `numeric` without a fixed scale to avoid unintended precision truncation; timestamps use `timestamptz`; idempotency is scoped by command, account, trading mode, principal, and key, with a canonical payload SHA-256 fingerprint.
- Added `services/backend/migrations/README.md` documenting the architecture basis, scope, exclusions, and next verification gates.
- This is schema source only. No migration runner, PostgreSQL driver, database connection, database role/grant configuration, or applied database is present yet. Do not describe persistence as operational.

### Runtime packaging source
- Xcode app target includes a Package Backend Runtime build phase.
- apps/macos/Scripts/package-backend.sh requires Node.js 24 universal (x86_64 + arm64), compiles the backend, and copies the Node executable and compiled backend into the fixed bundle paths used by the supervisor.
- The script copies package.json ESM metadata and signs the nested Node executable with the minimal V8 JIT entitlement when Xcode code signing is enabled. Exact Node patch pinning, release signature verification, and notarization remain outstanding.

## Not yet verified

- Current branch has not been built with Xcode 14.3.1 / Swift 5.8.1 on the target Intel Mac.
- GitHub Actions Backend CI run 43332767979 on Node.js 24.22.2 completed successfully: TypeScript build passed and 31/31 backend tests passed. The run predates a later UI-only screen-lifecycle change; backend source was unchanged after the passing run. The workflow was then updated to Node-24-native action releases.
- Node.js X25519/HKDF/AES-GCM decryption has backend test source but no executed result. CryptoKit-to-Node cross-language interoperability has not yet been tested.
- Xcode packaging phase, universal Node runtime copy, nested signature, and final app signature have not been verified.
- Packaged child-process startup, protocol v2 handshake, encrypted credential transfer, app-termination shutdown, process restart, and UI state synchronization have not been verified.
- The owner reports that the local Xcode application authenticates to Capital.com Demo and receives broker-originated asset prices. This remains owner-reported runtime evidence; this review did not independently reproduce it. Current-main Xcode build, packaged runtime, real account snapshots, and OHLC delivery remain unverified.
- The new Market Watch SwiftUI files and Xcode project membership have not yet been compiled on the target Mac.

## Not implemented or not operationally integrated

- Capital.com WebSocket quote/OHLC stream is wired through IPC v2 events and the shared Market Watch UI, but actual broker-originated quote/OHLC delivery has not been verified.
- Full Market Data ingestion lifecycle remains incomplete: ordering, deduplication, gap detection, candle integrity, durable storage, stale-event propagation, and recovery. The current quote normalizer is an initial component, not a completed Market Data Engine.
- Durable broker account/position/order reconciliation and persistence. Read-only API snapshot methods are being implemented in ATP-CAP-ACCOUNT-001; no SwiftUI consumer is wired yet.
- Durable Trading Domain persistence, migrations, append-oriented audit journal, and restart recovery.
- Risk Engine integration into an enforced order-intake/OMS path; the pure pre-trade evaluator is merged but not operationally integrated.
- Order Management System and durable intent state machine.
- Execution Gateway and broker dealing integration.
- Portfolio/account/position reconciliation.
- Strategy Runtime and Intelligence services.
- LIVE trading; no real order path is implemented or authorized.

## Architecture and security baseline

- Native SwiftUI client is presentation/operator-control only.
- Node.js/TypeScript backend owns broker lifecycle, data ingestion, orchestration, risk, OMS, execution, and reconciliation.
- The merged Capital.com connectivity milestone is read-only; this is an incremental implementation stage, not the product scope. Manual and automated dealing across DEMO and LIVE are mandatory product capabilities.
- All exposure-increasing intents must pass through centralized Risk Engine.
- OMS owns durable intent lifecycle; Execution Gateway is the only dealing path and accepts only Risk-approved, OMS-authorized intent.
- Broker-confirmed account and execution state is authoritative.
- Unknown broker submission outcomes require reconciliation, never blind retry.
- Production desktop IPC uses parent-owned anonymous standard-I/O pipes. No production TCP listener or filesystem socket is opened.
- Credentials are protected at rest by macOS Keychain, encrypted over IPC with ephemeral X25519/HKDF-SHA256/AES-256-GCM, and transmitted to Capital.com over HTTPS/TLS. This is data encryption; it is distinct from application code signing and bundle integrity.
- Session tokens remain backend-process memory only. No secrets in Git, logs, process arguments, environment variables, or app resources.
- LIVE remains disabled until all safety controls and explicit user authorization are implemented and verified.

## Verification record

- ATP-DOM-001: user reported TypeScript build success and 10/10 backend tests passing.
- XCTest/signing: user confirmed Xcode Build Succeeded; Codex reported four tests passed and signatures valid on x86_64. This is historical evidence only.
- PR #15 merged backend stdio IPC foundation as 8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5.
- PR #16 merged native Swift IPC supervisor source as f13ce0e3f8157a4901c99b8d928f2540cd213adc.
- PR #17 merged Capital.com screen and Keychain store as 9297f28fd2079dc5801cd89baf2b4723ed625a75.
- PR #18 merged Keychain load/read-back verification and field restoration as 675ea4af4d54610539218858e3d2f99c4c9a1985.
- PR #19 merged feat/atp-capitalcom-operational-connection into main as `b673d639bf5440ddd52085815bf7cf2a4fd54167`. It adds IPC v2 encrypted secret transfer, read-only Demo broker methods, Xcode backend packaging, market search/history, and WebSocket quote/OHLC event IPC. Target-Mac build, crypto interoperability, packaged runtime, and real Demo verification remain pending.
- Branch feat/atp-market-data-watchlist-main adds shared Market Watch, multi-epic subscriptions, quote normalization/freshness, and the application-level market-data store. Backend CI and target-Mac verification are pending.
- ATP-EXEC-001 RiskEngine is merged to main through PR #27 (`df85a423b30ce72d4106c281566cf9797031dfef`); it remains a pure evaluator, not connected to OMS or execution.
- Stacked branch feat/atp-market-data-watchlist adds shared persistent Market Watch, multi-epic subscriptions, quote normalization, Bid/Ask/Mid/Spread, and freshness display. Backend CI and target-Mac Xcode/runtime verification are pending.
- Apple Silicon arm64 runtime remains unverified.

## Next acceptance gates

1. Run Node.js 24 backend CI; fix all TypeScript and Node test failures.
2. On the target Mac, build with Xcode 14.3.1 / Swift 5.8.1 and deployment target macOS 13.0.
3. Verify CryptoKit/Node X25519-HKDF-AES-GCM interoperability and invalid-tag rejection.
4. Verify Xcode packaging, universal Node runtime, nested code signatures, and bundled child launch.
5. Verify encrypted credential submission, actual Capital.com Demo authentication, authenticated ping, market search, and historical prices using the user's own Demo account. Never request credentials in ChatGPT.
6. Verify WebSocket subscription acknowledgements and sustained multi-instrument Bid/Ask delivery in the shared Market Watch. Confirm quote age and 5/10/15-second freshness states against broker timestamps.
7. Complete the full Market Data Engine: ordering, deduplication, gap detection, OHLC integrity, persistence, and recovery.
8. Add broker account/position read-only snapshots and reconciliation only after the relevant official API contracts are confirmed.
9. Implement centralized Risk Engine, durable OMS, and Execution Gateway before enabling any dealing method. Keep LIVE disabled until all safety controls and explicit user-authorization gates are implemented and verified.


### ATP-EXEC-001 — The New Batch / Batch 1
- Branch: `feat/atp-new-batch-risk-engine-foundation`; draft PR #27.
- Added `services/backend/src/modules/risk-engine/risk-engine.ts` and `services/backend/tests/risk-engine.test.mjs`.
- Initial GitHub Actions run 43350570347 passed the Backend CI job (TypeScript build and backend test command). A later commit strengthened account-snapshot freshness and future-intent validation; its CI run is pending.
- No local Node execution, Xcode build, broker Demo order, or live trade is claimed.


## ATP-CAP-ACCOUNT-001 — read-only broker state implementation

**Branch:** `feat/atp-cap-account-001-readonly-snapshots`  
**Base commit:** `df85a423b30ce72d4106c281566cf9797031dfef` (PR #27 merged)

Implemented on this branch:
- Typed Capital.com account snapshots: balance, deposit, profit/loss, available funds, currency, account status/type, and preferred account.
- Typed account preferences: hedging mode and leverage availability.
- Typed open-position snapshots: broker deal identifiers, side, size, entry level, P&L, leverage, and market metadata.
- Typed working-order snapshots: identifiers, side, epic, quantity, order level/type, time-in-force, and market metadata.
- Local receipt timestamps for each snapshot.
- Read-only IPC methods: `broker.accounts`, `broker.accountPreferences`, `broker.positions`, and `broker.workingOrders`.
- Mock-based REST and IPC tests.

Limitations:
- Capital.com documents the account balance field as `available`; it is not asserted to equal RiskEngine `freeMargin`.
- No order creation, dealing, position mutation, account mutation, SwiftUI consumer, durable reconciliation, or LIVE capability is included.
- GitHub Actions Backend CI run 43358303256 passed on Node.js 24.22.2: TypeScript compilation passed and Node test output reported 46 passed, 0 failed, 0 skipped. No local build or real Demo account observation is claimed.


## Project-wide OOP design standard — ATP-ARCH-OOP-001

- Accepted architecture decision: ADR-0006.
- Normative conventions: docs/architecture/OOP_DESIGN_STANDARD.md.
- Scope: all source modules, directories, files, tests, and implementation teams across Swift/SwiftUI and TypeScript/Node.js.
- New and materially changed code must use cohesive object responsibilities, encapsulation, explicit protocol/interface boundaries, composition, dependency injection, and lifecycle ownership.
- Idiomatic Swift value types/protocols/enums and deterministic pure functions remain valid; the rule is not class-per-file or class-per-function.
- Existing source conformance has **not yet been audited**. Do not claim whole-repository OOP compliance until each bounded context is assessed and evidence is recorded.
- No source-code refactor or directory move was performed as part of this documentation milestone.


## ATP-ARCH-OOP-002 — source-code OOP conformance audit

- **Status:** IN PROGRESS; initial critical-path review only.
- **Audit record:** [ATP-ARCH-OOP-002-SOURCE-CONFORMANCE-AUDIT.md](ATP-ARCH-OOP-002-SOURCE-CONFORMANCE-AUDIT.md).
- **Partially conformant (reviewed):** macOS MarketDataStore, BackendProcessSupervisor, CapitalComBrokerView; backend stdio IPC, CapitalComRuntime, CapitalComClient.
- **Conformant for inspected responsibilities:** backend IPCSecretChannel and RiskEngine.
- **Not assessed:** remaining market-data stream/quality modules, composition root, trading domain, persistence runtime, OMS, execution, strategies, intelligence, portfolio/reconciliation, and full test architecture.
- Main design concerns: concentration of mutable state and orchestration, global singleton dependencies, direct concrete construction, and insufficient separation between presentation, transport, application, and domain ownership.
- No source-code changes or runtime verification were performed by this audit stage. Do not claim whole-repository conformance.


## ATP-ARCH-OOP-003 — Backend IPC composition boundary

**Merged into main:** PR #47, merge commit `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.

- `stdio-ipc.ts` now accepts the explicit `StdioIpcBroker` contract. The transport layer no longer imports or instantiates `CapitalComRuntime`.
- `server.ts` constructs `CapitalComRuntime` and injects it into the stdio transport as the composition root.
- IPC tests use a deterministic broker test double for unit-level sessions. The production child-process test still starts `server.js`, exercising explicit production composition.
- Protocol v2, capability allowlist, encrypted credential transfer, read-only broker methods, and disconnect cleanup are unchanged by intent.

**Verification status:** GitHub Actions Backend CI run 43528019119 passed on Node.js 24.22.2: TypeScript compilation passed and 51/51 Node tests passed. Packaged app behavior, current-main Xcode build, target-Mac runtime, and independent Capital.com Demo runtime verification remain unverified. No dealing or LIVE capability was added. PR #47 is closed and merged.


## Baseline reconciliation — 2026-11-14

**Verified GitHub main:** `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.

- PR #45 (ADR-0006 / OOP standard), PR #46 (initial OOP source audit), and PR #47 (stdio broker dependency injection) are closed and merged.
- PR #47 Backend CI run 43528019119 passed on Node.js 24.22.2: TypeScript build passed; 51/51 tests passed.
- PR #31 was closed unmerged as superseded by current-main-based PR #52. PR #52 is Draft and awaits target-Mac Xcode/UI acceptance.
- PR #35 was closed unmerged as superseded by current-main-based PR #51. PR #51 fixes the `\\gexec` defect and CI passes; no local PostgreSQL database or migration has been executed.
- The owner reports working Capital.com Demo authentication and broker-originated price delivery in the local Xcode application. This remains owner-reported and is not converted into independent verification.
- The full OOP source audit remains IN PROGRESS. ADR-0006 acceptance does not establish legacy-code conformance.
- No broker dealing, operational OMS/Execution path, or LIVE capability is present in main.


### ATP-BASELINE-001 documentation reconciliation

- Draft PR #48: https://github.com/atheertrading/AtheerAutotrade/pull/48
- Eight documentation files updated on `docs/atp-baseline-reconciliation-001`.
- No application/backend source, tests, SQL, Xcode project, broker permission, or runtime behavior changed.
- PR #48 is open, draft, and not merged; owner review is pending.


## Current reconciled status — 2026-11-14 (owner instruction and trading scope)

### Product scope
ATHEER Trading Pro must support both manual and automated trading through broker-linked DEMO and LIVE account environments. The currently merged `main` branch has not yet integrated an operational order path. Read-only market/account connectivity is an incremental milestone only and must never be described as the intended product boundary.

### Current main and active branches
- Current main baseline: `d44e184d998b719289c42159db138073d3213584`.
- PR #48 documentation reconciliation is present in main.
- PR #50 merged the owner-approved custom instructions and mandatory `AGENTS.md` loading rule as `d44e184d998b719289c42159db138073d3213584`.
- PR #49 / ATP-EXEC-002 adds a DEMO-only Capital.com market-position adapter method and deal-confirmation parser on a feature branch. GitHub Actions run `43534214647` passed TypeScript compilation and 62/62 tests on Node.js 24.22.2. It is not merged and not exposed through IPC, UI, strategy, or AI. It does not implement OMS, RiskEngine integration, Execution Gateway, durable persistence, or reconciliation.
- PR #35 old branch was closed unmerged as superseded. PR #51 / ATP-PERSIST-003 ports the migration-runner changes to current main and fixes the `\\gexec` template-literal escaping defect. Backend CI run `43535924779` passed TypeScript build and 52/52 tests. This remains source-level implementation only; no local PostgreSQL database has been provisioned and no migration executed.
- PR #31 was closed unmerged as superseded by PR #52. PR #52 ports the UI changes to current main and remains Draft pending target-Mac Xcode/UI acceptance. Its branch remains 20 commits ahead and 70 behind current main and is not mergeable.

### Persistence status
**PostgreSQL: NOT IMPLEMENTED OPERATIONALLY.** Migration SQL and runner source are not equivalent to a provisioned local PostgreSQL server, applied migrations, working repositories, or verified restart recovery. The local-Mac-only policy remains the current-phase requirement. The generic `trading` schema versus ATP-ARCH-003 domain-owned schema mapping must be resolved before applying migration 0001. No applied migration may be rewritten in place.

### Execution status
**End-to-end trading: NOT IMPLEMENTED.** The RiskEngine remains a pure evaluator, not an enforced order-intake gate. OMS, durable idempotency/outbox, Execution Gateway, application order IPC, manual order ticket, strategy order intake, broker confirmation/fill processing, and reconciliation are not integrated. The PR #49 adapter method is an isolated infrastructure primitive and must not be exposed until those controls exist.

### Owner-confirmed local synchronization
The owner confirms that the local development code matches the GitHub project code. This is an owner-confirmed fact. Do not repeatedly ask the owner to reconfirm it. A new feature branch created on GitHub after the synchronization point is not automatically present on the local Mac.

### Verification boundary
No local Terminal command, Xcode build, local PostgreSQL provisioning/migration, target-Mac UI acceptance, or real broker order was executed as part of this documentation/governance update. CI evidence above applies only to the specific PR #49 source commit recorded in its workflow run.


### ATP-PERSIST-003 — current-main source port and CI result

- Old PR #35 was closed unmerged as superseded; no commit history was rewritten or force-pushed.
- Current-main-based PR #51: `fix/atp-persist-003-current-main`, 4 commits ahead / 0 behind main, Draft.
- Corrected the template-literal escape so generated psql input contains a literal `\\gexec` command; added a unit assertion against the generated output.
- GitHub Actions Backend CI run `43535924779` passed on Node.js 24.22.2: TypeScript build passed; 52 passed, 0 failed, 0 skipped.
- **PostgreSQL remains NOT IMPLEMENTED operationally.** No local PostgreSQL server/database was provisioned and no migration applied. Resolve ATP-ARCH-003 schema ownership versus migration 0001 before the first migration; perform owner-Mac integration tests before merge.

### ATP-GOV-001 — owner-approved instructions

- PR #50 merged to main as `d44e184d998b719289c42159db138073d3213584`.
- `docs/engineering/ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md` is normative project guidance and is the first mandatory context file in root `AGENTS.md`.
- Manual and automated trading across DEMO/LIVE are explicit mandatory product requirements. Read-only connectivity is only an incremental implementation milestone.


### ATP-PERSIST-004 — schema ownership decision

- Proposal: `docs/engineering/ATP-PERSIST-004-SCHEMA-OWNERSHIP-PROPOSAL.md`.
- Recommended mapping: initial OMS tables under `oms`; migration ledger under platform metadata schema `atheer`.
- Status: PROPOSED — OWNER APPROVAL REQUIRED. No migration 0001 changes or database operations were performed. Do not apply the migration until the mapping is approved.


### ATP-UX-001 — current-main UI port

- PR #31 closed unmerged as superseded; its original branch/history remains preserved.
- PR #52: `feat/atp-ux-001-current-main`, six commits ahead / zero behind current main at creation, Draft.
- Ported adaptive Capital.com broker layout, Dashboard distinction between authentication/subscription/actual quote receipt, Market Watch native copy context menu, ATHEER Trading Pro branding, and accurate Workspace status copy.
- UI/UX audit and acceptance criteria are included.
- No target-Mac Xcode build, XCTest, UI automation, accessibility audit, or real broker runtime check has been performed. Do not merge until the owner-Mac acceptance gates pass.

### ATP-PERSIST-003 / ATP-PERSIST-004

- PR #51 is the current-main migration-runner port; Backend CI run 43535924779 passed TypeScript build and 52/52 tests. The psql `\\gexec` escaping defect is corrected.
- PostgreSQL remains NOT IMPLEMENTED operationally. No local server/database has been provisioned and no migration applied.
- ATP-PERSIST-004 schema ownership proposal is PROPOSED — OWNER APPROVAL REQUIRED; do not change or apply migration 0001 until approved.

### ATP-GOV-001

- PR #50 merged as `d44e184d998b719289c42159db138073d3213584`; owner instructions are normative and mandatory through root `AGENTS.md`.
