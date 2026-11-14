# Project Continuity Record

**Purpose:** Preserve the authoritative engineering handoff between sessions and prevent repeated work, lost decisions, and unsupported claims.

**Product identity:** ATHEER Trading Pro  
**Repository / temporary technical project identifier:** `atheertrading/AtheerAutotrade` / `AtheerAutotrade`  
**User-confirmed local project root:** `/Users/enghossamalfahad/Developer/AtheerAutotrade`  
**Xcode project:** `apps/macos/AtheerAutotrade.xcodeproj`  
**Current bundle identifier:** `com.atheerautotrade.desktop`

## 1. Product identity and scope

ATHEER Trading Pro is the product identity: a professional, production-oriented multi-asset trading platform requiring both manual and automated trading through broker-linked DEMO and LIVE account environments. Read-only connectivity is an incremental implementation milestone, not the product scope. AtheerAutotrade is a temporary technical repository/project identifier, not a separate product identity. Retain repository, Xcode, bundle, package, and Keychain identifiers until a controlled migration plan is approved.

Prior ATHEER Trading Pro architecture and engineering material is source material to reconcile. Preserve applicable requirements, but do not copy contradictory, obsolete, provisional, or unverified implementation assumptions.

## 2. Authoritative sources

| Concern | Source |
|---|---|
| Owner-approved role, product scope, governance, trading and safety instructions | [ATHEER Trading Pro Custom Instructions](ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md) |
| Cross-session handoff and constraints | This document |
| Task state and next action | [Task Register](TASK_REGISTER.md) |
| Implemented, planned, and unvalidated functionality | [Implementation Status](IMPLEMENTATION_STATUS.md) |
| Accepted architecture decisions | `docs/decisions/` |
| Module ownership | [Module Boundaries](../architecture/MODULE_BOUNDARIES.md) |
| Target topology | [System Overview](../architecture/SYSTEM_OVERVIEW.md) |
| Security baseline | [Security Baseline](../security/SECURITY_BASELINE.md) |
| Agent working rules | Repository-root `AGENTS.md` |
| Normative project instructions | [Custom GPT Instructions](ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md) |

Repository records are authoritative over conversation summaries. When documents conflict, prefer newer directly verified evidence and record the reconciliation.

## 3. Repository baseline and active branches

- Current verified GitHub `main` baseline for this handoff: `d44e184d998b719289c42159db138073d3213584` (includes PR #48 documentation reconciliation and PR #50 owner-approved governance instructions).
- PR #45 merged ADR-0006 / project-wide OOP standard as `65b814a09b905011cb0da00f493e341c7ee94591`.
- PR #46 merged the initial ATP-ARCH-OOP-002 source-conformance audit as `0bbd272d7a3ec33b53f6d84a1658f8c07e93e396`.
- PR #47 merged ATP-ARCH-OOP-003 stdio broker dependency injection as `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.
- Current open PRs include #31 (ATP-UX-001), #49 (ATP-EXEC-002), and #51 (ATP-PERSIST-003 current-main port); PR #35 is closed unmerged as superseded. See latest handoff below.
- The owner-confirmed local project root is `/Users/enghossamalfahad/Developer/AtheerAutotrade`; the Xcode project is `apps/macos/AtheerAutotrade.xcodeproj`.
- The local working tree, branch, commit, uncommitted files, and stashes were not inspected in this GitHub review. Do not assume local files match GitHub main. Do not reset, clean, force-push, pop/drop stashes, or overwrite local work without a reviewed reconciliation plan.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, Dashboard, broker screen, Market Watch, and configurable Trading Workspace are present in source.
- The native app includes `BackendProcessSupervisor`, protocol-v2 IPC client, encrypted credential channel, and Keychain credential store.
- The Node.js/TypeScript modular-monolith backend supports diagnostic HTTP health mode and production stdio IPC v2. `server.ts` composes `CapitalComRuntime`; the transport consumes an injected `StdioIpcBroker` contract.
- Capital.com source includes read-only Demo session lifecycle, market search, historical prices, WebSocket quote/OHLC stream, and read-only account/preferences/positions/working-order snapshots.
- Shared `MarketDataStore`, watchlist persistence, quote display, and backend quote normalization/freshness classification are present.
- A provider-neutral Instrument model and pure RiskEngine evaluator are present. RiskEngine is not integrated into an enforced order-intake/OMS/Execution Gateway path.
- PostgreSQL schema and migration-runner source exist. No local PostgreSQL database has been provisioned and no real migration execution is claimed. PR #35 contains pending local-only enforcement/correctness changes.
- **Owner-reported runtime evidence:** the owner reports that the local Xcode application authenticates to Capital.com Demo and receives broker-originated asset prices. This remains owner-reported and has not been independently reproduced in this review.
- Current-main Xcode build, target-Mac packaging/runtime, CryptoKit-to-Node interoperability, sustained broker soak, and independent Demo observation remain unverified.
- No broker dealing method is merged to main. PR #49 contains an isolated DEMO-only adapter method on a feature branch; there is still no integrated OMS/Execution path or LIVE authorization in main.

## 5. Architecture baseline accepted in ADR-0004

- Native SwiftUI macOS client remains the presentation/operator-control surface.
- Backend remains a Node.js/TypeScript modular monolith with explicit module ownership and typed boundaries.
- Backend owns broker lifecycle, market-data ingestion, domain orchestration, persistence, Risk, OMS, execution, and reconciliation.
- Capital.com is the primary broker target. The current merged Capital.com connectivity milestone is read-only, but manual and automated dealing across DEMO and LIVE are mandatory product capabilities. The read-only milestone must not be treated as the final broker integration.
- ADR-0005 selects parent-owned anonymous standard-I/O pipes for production desktop IPC. Loopback HTTP remains development/diagnostic-only. The native macOS app owns Keychain access; protocol v2 transfers credentials only as AES-256-GCM ciphertext over the per-session X25519/HKDF channel.
- The Execution Gateway is the only dealing path. It accepts dispatch only from OMS with a Risk decision bound to the exact immutable intent.
- Every exposure-increasing intent passes through centralized Risk Engine.
- Broker-confirmed account and execution state is authoritative. Unknown submission outcomes require reconciliation; never blind retry.
- LIVE remains disabled until all safety controls and explicit user authorization are implemented and verified.
- Process health, backend readiness, broker REST session, WebSocket state, market-data quality, persistence, trading readiness, and LIVE authorization are distinct states.

## 6. Development environment (last user-provided; not live-inspected)

- Hardware: iMac18,3 (Intel).
- macOS: Ventura 13.7.8.
- Xcode: 14.3.1.
- Swift compiler: 5.8.1.
- macOS SDK: 13.3.
- Deployment target: macOS 13.0.
- Intended architectures: x86_64 and arm64.

Reassess the toolchain only when the development environment changes or a task requires it. Do not claim arm64 runtime support without runtime validation.

## 7. Non-negotiable constraints

- Preserve existing local changes, stashes, workspace work, and unrelated files.
- Inspect exact current files before editing.
- Keep deployment target macOS 13.0 unless a documented requirement justifies change.
- Do not introduce unverified dependencies.
- Keep UI, backend, broker connectivity, risk, and execution responsibilities separate.
- All exposure-increasing intents pass through centralized Risk Engine.
- UI, strategies, and AI cannot bypass Risk or call broker dealing APIs.
- Never place credentials/tokens/private keys in source, Git, logs, process arguments, or ChatGPT.
- Use platform-appropriate secure storage; broker session tokens remain memory-only.
- Missing broker specifications or market observations remain unknown; never fabricate defaults.
- No real trade without explicit user approval.

## 8. Working protocol

1. Read `AGENTS.md`, `ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md`, this record, task register, implementation status, and relevant ADR/security/architecture documents.
2. Confirm the requested milestone is not already complete.
3. Inspect exact source and project configuration before edits.
4. Define scope, dependencies, acceptance criteria, and verification.
5. Implement one milestone without unrelated refactoring.
6. Verify only affected behavior; do not repeat completed tests without a technical reason.
7. Record actual changed files, results, and next action in the task register and implementation status.

## 9. Latest handoff — 2026-11-13

### Merged baseline

- PR #14 merged ADR-0004 product identity and modular-monolith architecture as 9445a749d78c63030e9125041a6103dca0eabafc.
- PR #15 merged backend stdio IPC foundation as 8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5.
- PR #16 merged native Swift IPC protocol/supervisor source as f13ce0e3f8157a4901c99b8d928f2540cd213adc.
- PR #17 merged the Capital.com broker screen and Keychain store as 9297f28fd2079dc5801cd89baf2b4723ed625a75.
- PR #18 merged Keychain load/read-back verification and saved-field restoration as 675ea4af4d54610539218858e3d2f99c4c9a1985.
- Current observed main baseline: 675ea4af4d54610539218858e3d2f99c4c9a1985.

### ATP-CAP-SESSION-001 — merged PR #19

Merged commit: `b673d639bf5440ddd52085815bf7cf2a4fd54167`  
Pull request: https://github.com/atheertrading/AtheerAutotrade/pull/19

The branch extends the merged work; it does not recreate the app or replace the existing adapter.

Implemented in source:
- IPC protocol v2 with per-child ephemeral X25519/HKDF-SHA256/AES-256-GCM encrypted credential transfer and one-shot credential submission.
- CapitalComRuntime for Demo REST session creation, authenticated ping, status, market search, historical prices, and WebSocket stream lifecycle.
- WebSocket quote/OHLC event frames from backend to native Swift UI, including subscription state and bounded frame validation.
- SwiftUI Connect/Disconnect, authenticated market discovery, live quote/one-minute OHLC view, two-column broker workspace, and app-termination child shutdown.
- Xcode build phase and packaging script for a bundled universal Node.js 24 runtime, ESM package metadata, and compiled backend. A minimal V8 JIT entitlement is applied to the Node helper when code signing is enabled.
- Updated security, protocol, bundle, ADR, implementation-status, and task-register documentation.

Verification:
- GitHub Actions Backend CI run 43332767979 passed on Node.js 24.22.2: TypeScript build succeeded and 31/31 tests passed.
- The Node tests cover IPC framing, handshake, one-shot encrypted credential submission, AES-GCM authentication-tag rejection, and the existing backend tests.
- CryptoKit-to-Node cross-language interoperability has not been tested.
- Xcode 14.3.1 / Swift 5.8.1 build, app-bundle packaging, nested signing/entitlement verification, packaged child-process launch, and real Capital.com Demo authentication remain pending.
- Actual WebSocket subscription acknowledgements and sustained quote/OHLC delivery remain unverified.
- Account/position reconciliation, Risk Engine, OMS, Execution Gateway, order/dealing, and LIVE remain absent.

### Next acceptance sequence

1. Build the macOS target on the actual Intel Mac using Xcode 14.3.1 / Swift 5.8.1.
2. Verify the Xcode backend packaging phase, universal Node runtime, ESM entry point, JIT entitlement, nested signature, and outer app signature.
3. Verify CryptoKit/Node X25519-HKDF-AES-GCM interoperability, invalid-tag rejection, and one-shot handoff.
4. Launch the packaged child and verify protocol v2, app shutdown, process restart, and UI state.
5. Authenticate against the user's Capital.com Demo account; verify ping, market search, historical prices, WebSocket subscription acknowledgements, and sustained quote/OHLC delivery. Credentials must remain on the user's Mac and must not be shared in ChatGPT.
6. Implement market-data freshness, stale-state, gap detection, and recovery.
7. Implement read-only account/position snapshots and reconciliation only after confirming official API contracts.
8. Keep all order/dealing/LIVE capabilities disabled until Risk Engine, OMS, Execution Gateway, authorization, audit, and reconciliation gates are implemented and verified.

### Local repository preservation

All work in this handoff was performed through GitHub. No local filesystem, Xcode build, or local Git working copy was accessed. Preserve all user local changes and stashes.


### ATP-MD-WATCH-001 — branch based on merged main

Current branch: `feat/atp-market-data-watchlist-main`  
Base branch: `main` (PR #19 is already merged)  
Draft PR #21: https://github.com/atheertrading/AtheerAutotrade/pull/21  
Superseded stacked PR #20 was closed; it was not merged.

Implemented in source:
- Shared `MarketDataStore` receives IPC market-data events at the application root rather than only while the Brokers screen is visible.
- Market Watch instruments persist locally; Capital.com subscriptions support multiple selected epics, bounded by the broker adapter's 40-instrument limit.
- Markets destination and the Trading Workspace Market Watch panel display Bid, Ask, derived Mid/Spread, quote age, and freshness state.
- Broker market search adds instruments to the watchlist; stream lifecycle is no longer stopped simply because the user navigates away from Brokers.
- Backend quote normalization validates positive, ordered Bid/Ask values, retains broker and local receipt timestamps, derives Mid/Spread, and classifies age as FRESH (0–5s), DELAYED (>5–10s), DEGRADED (>10–15s), STALE (>15s), or UNKNOWN for future-dated observations.
- Added Node tests for quote normalization, integrity checks, and freshness boundaries.

Not verified:
- Node 24 CI for this branch has not yet run.
- Xcode 14.3.1 / Swift 5.8.1 compilation and target-Mac runtime are not verified.
- No actual Capital.com Demo WebSocket subscription acknowledgement or sustained quote has been observed.
- The current normalizer is not the complete Market Data Engine: ordering, deduplication, gap detection, OHLC integrity, persistence, and recovery remain outstanding.

### Design, controls, and clipboard review

- The supplied Q&A design specification identifies IPDS v1.0 as the approved baseline: dark-first, institutional/information-dense, SF Pro/SF Mono, centralized tokens, controlled semantic colors, clear button hierarchy and immediate feedback, explicit trade confirmation, keyboard navigation, visible focus, accessible labels, and non-color-only status communication.
- The two uploaded ZIP archives contain textual design/architecture specifications but no bundled PNG, JPEG, SVG, Figma, Sketch, or other standalone mockup/image assets.
- GitHub integration currently exposes `atheertrading/AtheerAutotrade`; attempting to read `atheertrading/atheer-trading-knowledge-base` returned 404. The referenced independent style-guide repository therefore remains unreviewed, not assumed absent.
- Existing SwiftUI source uses locally styled `.plain` buttons and a static environment selector; no shared button/toggle component library or explicit jumper component was found. The accessible design documents specify button hierarchy and feedback but do not provide a distinct toggle/jumper component contract.
- No app-wide text-selection or clipboard command implementation was found in the accessible source. Track ATP-UX-CLIPBOARD-001 separately: enable selectable static text from the application root and preserve native copy/paste in editable controls, without per-label patches.
- Current source color values are not fully aligned with the approved IPDS palette. This visual-system correction is deferred while price visibility is prioritized; do not introduce new local colors or control styles in the Market Watch work.

### Next acceptance sequence

1. Run Node 24 CI for ATP-MD-WATCH-001 and fix all build/test failures.
2. Build the macOS target on the target Intel Mac using Xcode 14.3.1 / Swift 5.8.1; verify Xcode project membership and app startup.
3. Verify encrypted IPC interoperability and packaged backend launch.
4. Authenticate with the user's Capital.com Demo account and verify multiple instrument subscriptions, Bid/Ask events, timestamps, freshness labels, and persistence after navigating between screens.
5. Implement the full Market Data Engine and read-only account/position reconciliation.
6. Implement Risk Engine, OMS, and Execution Gateway before enabling Demo order submission. LIVE must remain disabled until all required controls, reconciliation, authorization, and explicit approval are satisfied.
7. Implement ATP-UX-CLIPBOARD-001 as a separate application-wide UI milestone; review the independent style-guide repository once GitHub access is available.


## Latest handoff — ATP-CAP-ACCOUNT-001 (2026-11-13)

### Verified repository baseline
- PR #27 (ATP-EXEC-001 Batch 1: centralized pre-trade Risk Engine) is merged into `main`.
- Merge commit: `df85a423b30ce72d4106c281566cf9797031dfef`.
- RiskEngine source and tests are in main. It remains a pure evaluator, not an operational OMS/execution path.
- The earlier manual-market-order workflow branch/PR is a documentation/design baseline only; it does not implement order execution.

### Active implementation
- Branch: `feat/atp-cap-account-001-readonly-snapshots`.
- ATP-CAP-ACCOUNT-001 extends the existing CapitalComClient and CapitalComRuntime; it does not recreate the adapter or replace existing session/market-data functionality.
- Read-only endpoints: `GET /api/v1/accounts`, `GET /api/v1/accounts/preferences`, `GET /api/v1/positions`, and `GET /api/v1/workingorders`.
- IPC additions: `broker.accounts`, `broker.accountPreferences`, `broker.positions`, and `broker.workingOrders`.
- Account `balance.available` is preserved under its broker field name; do not assume it is RiskEngine free margin without authoritative semantics and validation.
- Each snapshot includes a local `observedAt` timestamp. Broker source timestamps remain separate where supplied.

### Safety boundaries
- No account switching/settings mutation, order creation, dealing, position amendment/closure, or broker mutation method.
- No durable reconciliation or SwiftUI display integration in this batch.
- No real Demo order is submitted by tests or implementation.
- LIVE remains disabled; RiskEngine, OMS authorization, Execution Gateway, explicit operator confirmation, audit, and reconciliation remain mandatory before future dealing.

### Verification state
- GitHub Actions Backend CI run 43358303256 passed on Node.js 24.22.2: TypeScript compilation passed; 46 tests passed, 0 failed, 0 skipped.
- Draft PR #29: https://github.com/atheertrading/AtheerAutotrade/pull/29.
- No local build, target-Mac runtime, or real Demo account read is claimed.
- Credentials remain on the user's Mac and must never be sent in ChatGPT.

### Next implementation step
After CI passes and the branch is reviewed, implement the durable OMS intent journal/state machine and idempotency boundary. Do not expose a broker dealing method until OMS and Execution Gateway are integrated with the merged RiskEngine and broker-state reconciliation.


## 10. Latest handoff — ATP-PERSIST-001 (2026-11-13)

### Verified GitHub baseline
- Current main: `794e9c5854bba45c5b007b44de697b030f3b72a8`, merged PR #29.
- PR #21 (ATP-MD-WATCH-001) is merged as `3fed5711393059d4e089a5209b55f5fef5d8860b`; CI, target-Mac build/runtime, and real Capital.com Demo quote delivery remain pending.
- PR #27 (ATP-EXEC-001 Batch 1) is merged as `df85a423b30ce72d4106c281566cf9797031dfef`; the pure RiskEngine is not integrated with OMS or Execution Gateway.
- PR #29 (ATP-CAP-ACCOUNT-001) is merged as `794e9c5854bba45c5b007b44de697b030f3b72a8`; Node 24.22.2 TypeScript build and 46/46 tests passed in CI. No target-Mac or real broker session verification is claimed.
- PR #25 (quote UI coalescing) and PR #26 (workspace sizing) remain open at the time of this handoff.

### Architecture reconciliation
- The earlier Task Register handoff said to proceed directly to the durable OMS journal/state machine after PR #29.
- ATP-ARCH-003 is an approved persistence architecture baseline and explicitly sequences: PostgreSQL database/migration baseline first, then canonical persistence types, then OMS persistence.
- ATP-ARCH-019 requires durable intent journaling, append-only lifecycle events, scoped payload-bound idempotency, and no blind retry for unknown external outcomes.
- Therefore, this branch starts ATP-PERSIST-001 Stage 1 before ATP-OMS-001. This is sequencing reconciliation, not a change to the PostgreSQL architecture decision.

### Active branch and authored source
- Branch: `feat/atp-persist-001-postgres-foundation`, based on main `794e9c5854bba45c5b007b44de697b030f3b72a8`.
- Added `services/backend/migrations/0001_trading_oms_foundation.sql`.
- Added `services/backend/migrations/README.md`.
- Updated Task Register and Implementation Status to record this bounded milestone and its verification limits.
- Initial schema covers `atheer.schema_migrations`, `trading.idempotency_records`, `trading.trade_intents`, `trading.order_events`, and `trading.order_command_outbox`.
- Exact decimal quantity storage uses PostgreSQL `numeric` without a fixed scale; timestamps use `timestamptz`; scoped idempotency includes command type, account, mode, principal, key, and payload fingerprint.

### Verification and exclusions
- SQL has not been executed against PostgreSQL and no database has been provisioned.
- No PostgreSQL driver, migration runner, runtime configuration, database roles/grants, integration tests, OMS command service, RiskEngine integration, outbox dispatcher, Execution Gateway, broker dealing method, or order IPC method has been added.
- No order is submitted. LIVE remains disabled.
- Next: review and validate the schema against ATP-ARCH-003/019; implement the pinned PostgreSQL client and checksum-verified migration runner; add PostgreSQL integration tests for atomic intent/idempotency/event creation, concurrent duplicate requests, payload mismatch, rollback, and restart recovery. Only then proceed to ATP-OMS-001 state-transition handling.
- Preserve all local Mac work and stashes. This milestone was performed through GitHub only; no local filesystem or Xcode environment was accessed.


## Latest architecture decision — 2026-11-14: ATP-ARCH-OOP-001

- ADR-0006 accepts a project-wide Object-Oriented Design Standard.
- Normative specification: docs/architecture/OOP_DESIGN_STANDARD.md.
- Root AGENTS.md now requires the standard for all future source changes.
- The standard applies across macOS Swift/SwiftUI, backend TypeScript/Node.js, tests, directories, and files.
- It requires cohesive objects, encapsulation, explicit protocols/interfaces, composition, dependency injection, and explicit lifecycle ownership. Idiomatic Swift structs/enums/protocols and pure deterministic functions remain appropriate; do not force a class into every file/function.
- Directory conventions follow bounded contexts and architectural layers. Existing paths are preserved until a scoped migration is justified.
- This milestone changes architecture documentation only. Existing code has not yet been audited or refactored for full conformance.
- Next: assess current source module-by-module and record evidence; remediate incrementally without disturbing working Capital.com connectivity or workspace functionality.


## Latest handoff — ATP-ARCH-OOP-002 (2026-11-14)

- Branch: `audit/atp-arch-oop-002-source-conformance`, based on `architecture/atp-oop-standards-001` so the accepted ADR-0006/OOP standard is available to the audit.
- Added `docs/engineering/ATP-ARCH-OOP-002-SOURCE-CONFORMANCE-AUDIT.md` with an initial path-level assessment.
- Reviewed: macOS `MarketDataStore`, `BackendProcessSupervisor`, `CapitalComBrokerView`; backend `stdio-ipc.ts`, `CapitalComRuntime`, `CapitalComClient`, `IpcSecretChannel`, and `RiskEngine`.
- Initial findings: state/orchestration concentration and singleton/concrete dependencies in key macOS and IPC/broker components; positive encapsulation in `IpcSecretChannel` and deterministic domain policy structure in `RiskEngine`.
- Audit remains IN PROGRESS. The full repository file inventory and remaining active modules have not been inspected; no whole-project conformance claim is made.
- No source code, Xcode project, package configuration, broker behavior, or trading permissions changed. No Xcode/Node tests or runtime checks were run during this audit stage.
- Next: complete source inventory and inspect remaining modules, callers, tests, dependency construction, and directory ownership; then propose narrow, behavior-preserving refactors with separate verification gates.


## Latest implementation handoff — ATP-ARCH-OOP-003 (2026-11-14)

### Objective
Begin incremental remediation of the OOP conformance findings without waiting for an Xcode build and without changing working broker behavior.

### Branch and implementation
- Repository: `atheertrading/AtheerAutotrade`.
- Branch: `refactor/atp-arch-oop-003-stdio-composition`, created from `main`.
- Added the explicit `StdioIpcBroker` capability contract to the stdio IPC boundary.
- Removed the concrete `new CapitalComRuntime()` default construction from `serveStdioIpc`.
- Moved concrete runtime construction to `services/backend/src/server.ts`, the composition root.
- Updated IPC tests to inject deterministic broker test doubles; production child-process test retains the real server startup path.
- Added `docs/engineering/ATP-ARCH-OOP-003-STDIO-COMPOSITION.md` and updated the audit, task register, and implementation status.

### Behavior and safety
- No IPC protocol/version/capability changes.
- No change to encrypted credential handoff, Capital.com Demo REST/WebSocket behavior, or read-only account/position/order snapshots.
- No broker dealing, OMS, execution, or LIVE capability added.
- Credentials and broker tokens remain outside source and ChatGPT.

### Verification
- GitHub source writes confirmed.
- Backend CI, TypeScript build, and Node tests are pending.
- No local Mac filesystem, Xcode build, runtime, or broker session was accessed or verified in this milestone.

### Next
Inspect the branch diff, run Backend CI, and address any reported failures before moving to the next OOP remediation. Continue the broader ATP-ARCH-OOP-002 audit in parallel only through separately scoped, evidence-backed work.


### ATP-ARCH-OOP-003 verification result

- GitHub Actions Backend CI run: [43528019119](https://github.com/atheertrading/AtheerAutotrade/actions/runs/43528019119).
- Runner Node.js: 24.22.2.
- Dependency installation: passed.
- TypeScript compilation: passed.
- Node tests: 51 passed, 0 failed, 0 skipped.
- Draft PR #47 remains open and unmerged pending owner review.
- This CI result does not establish Xcode build, target-Mac runtime, app packaging, or Capital.com Demo verification.


## Latest reconciled handoff — 2026-11-14 (supersedes older baseline statements)

### Verified repository baseline
- Repository: `atheertrading/AtheerAutotrade`.
- Current GitHub `main`: `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.
- Local Xcode project path supplied by the owner: `/Users/enghossamalfahad/Developer/AtheerAutotrade/apps/macos/AtheerAutotrade.xcodeproj`.
- The local Mac working tree, branch, commit, uncommitted changes, Xcode build, and live application were not accessed in this review. Do not assume local files are identical to GitHub main.

### Merged OOP milestones
- PR #45 merged ADR-0006 / project-wide OOP standard (merge commit `65b814a09b905011cb0da00f493e341c7ee94591`).
- PR #46 merged the initial ATP-ARCH-OOP-002 source-conformance audit (merge commit `0bbd272d7a3ec33b53f6d84a1658f8c07e93e396`).
- PR #47 merged ATP-ARCH-OOP-003 stdio broker dependency injection (merge commit `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`).
- PR #47 Backend CI run 43528019119 passed on Node.js 24.22.2: TypeScript build passed and 51/51 tests passed.
- ATP-ARCH-OOP-002 remains IN PROGRESS. The initial source audit is not complete, and ADR acceptance does not imply that existing source is OOP-conformant.

### Owner-reported runtime evidence
- The owner reports that the local Xcode application authenticates to Capital.com Demo and receives broker-originated asset prices.
- Preserve this as owner-reported runtime evidence. It has not been independently reproduced in this review.
- Do not describe the broker integration as absent; distinguish source integration, owner-reported local runtime, and independently verified runtime.

### Open pull requests — do not merge without their gates
- **PR #31 — ATP-UX-001:** open, not merged; branch is 20 commits ahead and 54 behind current main; Backend CI run 43430341371 passed, but no target-Mac Xcode build/UI acceptance is recorded. GitHub reports draft=false while the PR body says it must remain draft until target-Mac acceptance. Reconcile and verify before merge.
- **PR #35 — ATP-PERSIST-003:** open draft, not merged; branch is 1 commit ahead and 39 behind current main. Backend CI run 43453512269 failed 1/52 tests: the migration-runner test expected the psql `\\gexec` command, but the generated script contained `gexec` without the required backslash. Fix the escaping, rerun CI, rebase, and execute real PostgreSQL integration tests before merge.
- Local PostgreSQL-only topology is the recorded current-phase owner decision in PR #35. It does not, by itself, resolve the longer-term deployment topology described in older Q&A material.

### Architecture and source-of-truth findings
- `README.md`, `SYSTEM_OVERVIEW.md`, `MODULE_BOUNDARIES.md`, `TASK_REGISTER.md`, `IMPLEMENTATION_STATUS.md`, and earlier continuity entries contained stale implementation or PR status. This reconciliation branch updates the principal status descriptions without changing source code.
- ATP-ARCH-003 defines PostgreSQL domain-owned logical schemas (`oms`, `risk`, `execution`, `positions`, `reconciliation`, `audit`, `reference`, `integration`). Current migration 0001 instead places initial OMS tables under a generic `trading` schema. The migration has not been executed; reconcile schema ownership against ATP-ARCH-003 before applying it.
- ATP-ARCH-036 (API/service contracts) remains incomplete. The CapitalCom-shaped `StdioIpcBroker` interface is a bounded first injection seam, not a final provider-neutral application contract. Review before expanding provider scope.
- ATP-ARCH-042 proposed Express and pnpm, while current backend source uses Node built-in HTTP APIs and npm. Do not add Express or migrate package management merely to match a historical proposal; record an explicit compatibility/deviation decision after reviewing the current accepted architecture.
- The Q&A repository contains an earlier hybrid-deployment recommendation; the current-phase local PostgreSQL decision is narrower and must not be interpreted as a final platform deployment decision.
- The project-wide OOP standard is accepted, but existing modules must be assessed incrementally. Do not force class-per-file or perform cosmetic directory moves.

### Engineering sequence
1. Finish source/branch/document reconciliation and preserve the local Mac worktree.
2. Resolve/rebase the existing UX and local-PostgreSQL PRs against current main; satisfy their own acceptance gates.
3. Complete the bounded OOP/source review for the modules actually entering the next milestone; use ATP-ARCH-036 and domain contracts rather than inventing interfaces.
4. Complete Market Data correctness (OHLC consumption, monotonic timestamps, deduplication, gap/recovery, freshness-aware status) before any consumer treats the feed as execution-grade.
5. Integrate account/position/order snapshots into shared read-only UI and reconciliation views; keep broker values authoritative.
6. Validate PostgreSQL schema ownership, local-only enforcement, migration correctness, and real local integration before operational OMS work.
7. Integrate RiskEngine with immutable intents and durable OMS; implement idempotency, outbox, state transitions, unknown-outcome reconciliation, then Execution Gateway and broker dealing in DEMO only.
8. Perform sustained Demo qualification and recovery testing. LIVE remains disabled pending all safeguards and separate explicit authorization.


### ATP-BASELINE-001 — documentation reconciliation branch

- Branch: `docs/atp-baseline-reconciliation-001`, based directly on current main `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.
- Draft PR #48: https://github.com/atheertrading/AtheerAutotrade/pull/48.
- Eight documentation files updated: README, System Overview, Module Boundaries, Implementation Status, Task Register, Project Continuity, ATP-ARCH-OOP-003 implementation record, and ATP-AUD-002 audit.
- No source code, tests, Xcode project, SQL migration, broker permission, database, or runtime setting changed.
- PR #48 is open, draft, not merged, and awaiting review. No build or runtime verification is claimed for this documentation-only change.


---

## Latest handoff — 2026-11-14 (governance merged; persistence runner corrected)

### Owner-approved instructions — merged

- PR #50 merged by squash as `d44e184d998b719289c42159db138073d3213584`.
- The full owner-provided instructions are now in `docs/engineering/ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md`.
- Root `AGENTS.md` requires every coding agent to read this document first, followed by continuity, task register, implementation status, ADRs, and relevant architecture/security contracts.
- README, Project Continuity, Task Register, and Implementation Status link and reinforce the normative project instructions.
- Product scope explicitly requires manual and automated trading across DEMO and LIVE. Read-only broker connectivity is only an incremental milestone.
- No application source, database, Xcode project, or broker runtime behavior changed in PR #50.

### Current baseline and local synchronization

- Current `main`: `d44e184d998b719289c42159db138073d3213584`.
- Owner confirms local code is synchronized with GitHub project code. Do not ask repeatedly or reopen this as an unresolved issue.
- Feature branches created after the owner-confirmed synchronization point are not automatically present locally. The owner must deliberately fetch/pull those branches when appropriate.

### Active PRs and status

- **PR #31 — ATP-UX-001:** open Draft; branch 20 commits ahead and 70 behind current main; GitHub reports not mergeable. Backend CI previously passed, but target-Mac Xcode/UI acceptance is not verified. Preserve the branch and port/reconcile its changes incrementally; do not merge until target-Mac acceptance is complete.
- **PR #35 — ATP-PERSIST-003 old branch:** closed unmerged as superseded. Its source history is preserved; no force-push or destructive history rewrite was used.
- **PR #51 — ATP-PERSIST-003 current-main port:** open Draft; branch `fix/atp-persist-003-current-main`, 4 commits ahead and 0 behind current main. It ports migration-runner logic, enforces local-only PostgreSQL service endpoints, removes ambient libpq host overrides, and fixes the JavaScript template-literal escaping for the literal psql `\\gexec` meta-command. Backend CI run `43535924779` passed on Node.js 24.22.2: TypeScript build passed; 52/52 tests passed.
- **PR #49 — ATP-EXEC-002:** open Draft; branch `feat/atp-exec-002-capital-com-dealing-adapter`, 14 commits ahead and 0 behind current main. Backend CI run `43534214647` passed: TypeScript build and 62/62 tests. It adds only an isolated DEMO dealing adapter method and deal-confirmation parser; no IPC/UI/strategy/AI exposure, OMS, RiskEngine enforcement, Execution Gateway, durable outbox, or reconciliation. No real broker order was submitted.

### Critical unresolved blockers

1. **PostgreSQL is NOT IMPLEMENTED operationally.** PR #51 is source + unit/CI verification only. No PostgreSQL server/database has been provisioned on the owner Mac, and no migration has been applied.
2. **Schema ownership must be resolved before first migration.** ATP-ARCH-003 defines domain-owned schemas; migration 0001 currently uses generic `trading`/ `atheer` schema layout. Agree the mapping before applying it. Never edit a migration already applied to any database; use a new forward migration instead.
3. **PR #31 needs target-Mac Xcode/UI acceptance.** GitHub source review and backend CI cannot replace a real Xcode build and UI checks.
4. **End-to-end trading remains NOT IMPLEMENTED.** The complete path is still RiskEngine → durable OMS → Execution Gateway → broker dealing → broker confirmation → reconciliation. PR #49's adapter method is not an operational order path and must remain inaccessible to UI/strategies/AI until the controls are integrated.
5. **ATP-ARCH-036 API/service contracts and ATP-ARCH-OOP-002 full source audit remain in progress.** Resolve the relevant contracts and inspect each bounded context before expanding interfaces or refactoring.

### Next execution order

1. Merge governance is complete; use the newly mandatory instruction document on every task.
2. Review PR #51 and resolve schema ownership against ATP-ARCH-003. Keep it Draft until owner-Mac PostgreSQL provisioning, first migration, no-op rerun, checksum mismatch, rollback, and concurrent-runner tests are completed and documented.
3. Port/reconcile PR #31 changes onto current main without losing functionality, then perform target-Mac Xcode/UI acceptance before merge.
4. Review PR #49 adapter contract and retain it as an infrastructure-only primitive. Do not expose order entry until durable OMS, mandatory RiskEngine authorization, Execution Gateway, idempotency/outbox, confirmation, and reconciliation are implemented.
5. Select the next development milestone only after these dependencies are reconciled. Preserve existing code and history; no rebuild from scratch.

### Verification boundary for this handoff

- Verified through GitHub: PR #50 merge, current-main comparison, PR branch divergence, PR #51 source changes, and Backend CI results for PR #49 and PR #51.
- Owner-reported: local code is synchronized with GitHub and Capital.com Demo prices work in the local app.
- Not independently executed in this review: local Terminal commands, Xcode build, local PostgreSQL setup/migrations, target-Mac UI acceptance, or actual broker dealing.
