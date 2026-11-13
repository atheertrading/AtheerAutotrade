# Project Continuity Record

**Purpose:** Preserve the authoritative engineering handoff between sessions and prevent repeated work, lost decisions, and unsupported claims.

**Product identity:** ATHEER Trading Pro  
**Repository / temporary technical project identifier:** `atheertrading/AtheerAutotrade` / `AtheerAutotrade`  
**User-confirmed local project root:** `/Users/enghossamalfahad/Developer/AtheerAutotrade`  
**Xcode project:** `apps/macos/AtheerAutotrade.xcodeproj`  
**Current bundle identifier:** `com.atheerautotrade.desktop`

## 1. Product identity and scope

ATHEER Trading Pro is the product identity: a professional, production-oriented, automated multi-asset trading system. AtheerAutotrade is a temporary technical repository/project identifier, not a separate product identity. Retain repository, Xcode, bundle, package, and Keychain identifiers until a controlled migration plan is approved.

Prior ATHEER Trading Pro architecture and engineering material is source material to reconcile. Preserve applicable requirements, but do not copy contradictory, obsolete, provisional, or unverified implementation assumptions.

## 2. Authoritative sources

| Concern | Source |
|---|---|
| Cross-session handoff and constraints | This document |
| Task state and next action | [Task Register](TASK_REGISTER.md) |
| Implemented, planned, and unvalidated functionality | [Implementation Status](IMPLEMENTATION_STATUS.md) |
| Accepted architecture decisions | `docs/decisions/` |
| Module ownership | [Module Boundaries](../architecture/MODULE_BOUNDARIES.md) |
| Target topology | [System Overview](../architecture/SYSTEM_OVERVIEW.md) |
| Security baseline | [Security Baseline](../security/SECURITY_BASELINE.md) |
| Agent working rules | Repository-root `AGENTS.md` |

Repository records are authoritative over conversation summaries. When documents conflict, prefer newer directly verified evidence and record the reconciliation.

## 3. Repository baseline and active branches

- Latest observed `main` baseline: `794e9c5854bba45c5b007b44de697b030f3b72a8` (PR #29 merge).
- PR #11 (ATP-DOM-001) was merged as `fa68db5635042b43cda16e687eeffa4f138c5cbe`; user-run verification reported TypeScript build success and 10/10 backend tests passing.
- PR #12 (ATP-CAP-001) was merged as `dfeff79b0b401d4722b5d4cf8ff9c9ab24344597`; see the current main branch history for subsequent changes.
- PR #13 (architecture diagram catalogue) was merged on 2026-11-12 as `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- ATP-ARCH-REBASE-001 was merged through PR #14 as `9445a749d78c63030e9125041a6103dca0eabafc`.
- The Capital.com UI feature branch `feature/atp-cap-002-broker-connection-experience` was previously reviewed and found to make direct REST calls from SwiftUI. It is not an approved architecture pattern and must not be merged as-is.
- The user's local working copy previously contained local changes and a stash. Do not pop, drop, apply, reset, clean, force-push, or overwrite local work without a reviewed reconciliation plan.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard/navigation, and Trading Workspace exist.
- On main, backend exposes diagnostic HTTP mode and production stdio IPC v1 (PR #15). Native Swift IPC client/supervisor source and Xcode project membership were merged via PR #16; target-Mac build/runtime verification remains pending.
- Provider-neutral Trading Domain Instrument model is merged.
- Capital.com read-only REST and WebSocket adapter source exists in the repository history, with mock-based tests. A source implementation is not proof of a connected broker.
- ADR-0005 selects parent-owned anonymous stdio pipes. PR #17 merged the Capital.com screen/Keychain store, PR #18 merged Keychain restoration, and PR #19 merged the encrypted Demo session and market-data bridge into main as `b673d639bf5440ddd52085815bf7cf2a4fd54167`. Target-Mac build, crypto interoperability, packaged launch, and real Demo verification remain pending. ATP-MD-WATCH-001 now builds directly on main in `feat/atp-market-data-watchlist-main`.
- No actual Capital.com Demo session, broker-originated quote, or candle is verified from this implementation.
- A first quote-normalization component is now present on the stacked Market Watch branch, but no real Demo quote is verified. Full Market Data ordering/deduplication, gap detection, OHLC integrity, persistence/audit, and recovery remain incomplete. Risk Engine, OMS, Execution Gateway, Portfolio/Reconciliation, Strategy Runtime, and Intelligence are not implemented as operational integrated modules.
- No live order path is implemented or authorized.

## 5. Architecture baseline accepted in ADR-0004

- Native SwiftUI macOS client remains the presentation/operator-control surface.
- Backend remains a Node.js/TypeScript modular monolith with explicit module ownership and typed boundaries.
- Backend owns broker lifecycle, market-data ingestion, domain orchestration, persistence, Risk, OMS, execution, and reconciliation.
- Capital.com is the primary broker target; initial broker integration remains read-only.
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

1. Read `AGENTS.md`, this record, task register, implementation status, and relevant ADR/security/architecture documents.
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


## Latest handoff — ATP-MD-QUALITY-002 (2026-11-13)

- Draft PR #40: https://github.com/atheertrading/AtheerAutotrade/pull/40
- Branch: `feat/atp-md-quality-002-quote-sides-latency-volume`, based on ATP-REALTIME-001 head commit `992d6c4d91c555307332688a799013d327146ade`.
- Restored fixed SELL/BID red and BUY/ASK green in the shared Market Watch table; directional movement remains separate in delta columns.
- Removed the 120 ms row animation and retained 16 ms coalescing.
- Added native IPC event receipt timestamp capture and distinct model deltas for backend-to-client delivery and broker-timestamp-to-backend receipt. The latter is not calibrated until Capital.com server-time offset is measured.
- Capital.com WebSocket quote contract includes bidQty/ofrQty, not executed volume. REST historical candles expose optional lastTradedVolume. One-minute volume monitor/IPC/UI is still pending; UI continues to withhold a value rather than misrepresent quote quantities or search results as traded volume.
- Source/doc changes only through GitHub. No Xcode build, Demo quote-parity test, server-time calibration, or volume monitor verification is claimed. PR #40 remains draft; do not merge or release before the outstanding checks.


### 2026-11-13 — ATP-MD-QUALITY-002 compile correction

Resolved the undefined `movementTint` reference in `MarketWatchView.swift` by using the existing `movementColor(liveQuote?.changeFromPrevious)` helper for MID-price directional coloring. BID/ASK execution-side colors remain invariant (BID red, ASK green). Commit: `dabf08e1d777546a161a1d7873bacb554d118999`. Local Xcode build remains pending.
