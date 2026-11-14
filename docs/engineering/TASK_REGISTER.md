# Engineering Task Register

**Last reconciled:** 2026-11-14  
**Latest observed main baseline:** historical task-register entry; see Project Continuity for its recorded context.  
**Active documentation change:** ATP-REL-001 — Baseline and Sequential Versioning Policy (PR #63; review pending)

## Release governance documentation — ATP-REL-001

| ID | Deliverable | Evidence | Status |
|---|---|---|---|
| ATP-REL-001 | Record immutable owner-designated baseline and sequential Semantic Versioning policy | `docs/engineering/BASELINE_AND_VERSIONING.md`; baseline tag `v1.0.0-baseline`; commit `264b445fa5657ebd91b9eda197ff0654c2402c5a`; PR #63 | DOCUMENTED ON REVIEW BRANCH — PR OPEN; NOT MERGED |

The baseline tag is immutable and remains the recovery anchor. The documentation branch is proposed for merge into `baseline/local-stable-v1`; no source code, default branch, or trading capability is changed. See [PR #63](https://github.com/atheertrading/AtheerAutotrade/pull/63).  
**Latest observed main baseline:** `bf884b57f11619472ea5d6c1aaca23534d9d781e` (main head observed during ATP-UI-DASHBOARD-001)  
**Active implementation branches:** `feat/atp-persist-001-postgres-foundation` (PostgreSQL persistence foundation); `feat/atp-dashboard-001-operational-dashboard` (Dashboard UI)

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

## Real-time telemetry milestone — ATP-REALTIME-001

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-REALTIME-001 | One-second broker account synchronization, lower-latency quote presentation, account/price semantic colors, and visible feed freshness | Branch `feat/atp-realtime-001-live-telemetry-and-color-semantics`; implementation record `docs/engineering/ATP-REALTIME-001.md` | IMPLEMENTED IN SOURCE — BACKEND CI PASSED (57/57); TARGET-MAC BUILD AND DEMO PERFORMANCE VERIFICATION PENDING |

- Capital.com account, positions, and working-order snapshots target a 1,000 ms cadence using authenticated REST polling; cycles remain non-overlapping.
- Three concurrent broker snapshots plus session validation imply approximately four requests per second at steady state, below the documented general ten-requests-per-second ceiling. This is a target cadence, not a guarantee of instantaneous broker-side updates.
- Market quote presentation batching reduced from 100 ms to 16 ms, coalescing the latest quote per instrument.
- Account freshness is based on local snapshot receipt time: LIVE through 2.5 seconds, DELAYED through 5 seconds, then STALE. The global account strip displays age and freshness continuously.
- Market Watch colors actual quote-to-quote price direction. Only FRESH quote prices/movement are displayed; delayed/degraded/stale/unknown quote values are withheld. Query-time volume and session/day change are not mislabeled as live stream data. Bid/Ask side is no longer confused with price direction.
- Dashboard and global account metrics use semantic colors for Balance/Funds, Available, Equity, P&L, Margin, and Margin Level.
- OOP boundaries remain domain-oriented: `CapitalComAccountMonitor`, `CapitalComRuntime`, `BrokerAccountStore`, `MarketDataStore`, and centralized `AtheerColors`.
- No order placement, account mutation, RiskEngine bypass, or LIVE capability is introduced.

## Preservation and safety constraints

- Preserve local files, local changes, and stashes; GitHub work does not imply local synchronization.
- Do not overwrite local project files with GitHub versions.
- Do not repeat Xcode tests for backend-only work without a technical reason.
- No credentials in ChatGPT, source, Git, logs, process arguments, or environment variables.
- LIVE dealing remains disabled; no real trade without explicit user approval.

## Current next action

ATP-REALTIME-001 is the current active UI/data task on `feat/atp-realtime-001-live-telemetry-and-color-semantics`, stacked on the continuous broker-account synchronization branch. It tightens account polling to a one-second target, reduces quote presentation batching to 16 ms, adds account/quote semantic colors, and makes feed freshness continuously visible. Backend CI, target-Mac Xcode build, and real Capital.com Demo latency/reconciliation remain pending. ATP-PERSIST-001 Stage 1 remains pending on its separate branch and is not discarded. No broker dealing or LIVE capability is introduced.

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


## UI milestone — ATP-UI-DASHBOARD-002

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-UI-DASHBOARD-002 | Broker account metrics, Market Watch presentation, and Settings navigation | Branch `feat/atp-dashboard-002-account-marketwatch-settings`; record `docs/engineering/ATP-UI-DASHBOARD-002.md` | IMPLEMENTED IN SOURCE — PENDING XCODE BUILD / DEMO VERIFICATION |

- Initial account values were consumed from the read-only `broker.accounts` IPC method. Dashboard-scoped 15-second refresh is superseded by ATP-BROKER-ACCOUNT-001's backend-owned continuous account-state monitor.
- Correct Capital.com account mapping is Funds = `balance.deposit`, Equity = `balance.balance`, P&L = `balance.profitLoss`, Available = `balance.available`, and Margin = Equity − Available. See ATP-ACCOUNT-SEMANTICS-001.
- Market Watch distinguishes SELL/BID and BUY/ASK, displays broker net/percentage change where supplied, calculates ticks only from broker tickSize, shows volume only when supplied, and adds asset-type icons.
- Quote-to-quote movement is explicitly distinguished from daily/session movement.
- Broker Connections is moved from primary navigation into Settings.
- Local Xcode build, Demo account reconciliation, market metadata/volume availability, and saved-watchlist decoding are pending.
- No order execution, account mutation, or LIVE capability is introduced.


## Broker synchronization milestone — ATP-BROKER-ACCOUNT-001

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-BROKER-ACCOUNT-001 | Continuous Capital.com account, positions, and working-orders synchronization; shared OOP application state | Branch `feat/atp-broker-001-continuous-account-sync`; `docs/engineering/ATP-BROKER-ACCOUNT-001.md` | IMPLEMENTED IN SOURCE — PENDING BACKEND CI, XCODE BUILD, AND DEMO RECONCILIATION |

- Backend `CapitalComAccountMonitor` begins immediately after successful Demo authentication and targets account, positions, and working-orders REST snapshots every 1 second without overlapping cycles.
- Account polling checks/renews the session each cycle. Capital.com official WebSocket documentation currently documents market quote and OHLC subscriptions, not account balance/positions/order events; account state therefore uses authenticated REST polling.
- The active financial account ID from the authenticated session is carried in the snapshot; the macOS app selects that account rather than assuming the preferred account is always active.
- Native OOP domain models are under `Core/Broker/Models`; the shared application service is under `Core/Broker/Services/BrokerAccountStore.swift`.
- `BrokerAccountStore` is injected at the application root for cross-feature consumption. `MarketDataStore` no longer owns a duplicate account snapshot or polling path.
- Backend CI run 43466811703 passed on Node.js 24: TypeScript build succeeded; 56 tests passed, 0 failed, 0 skipped. The target-Mac Xcode build and Demo account reconciliation remain pending.
- Account freshness is based on local receipt time: LIVE through 2.5 seconds, DELAYED through 5 seconds, then STALE. Disconnect/backend loss clears snapshots. No order placement, account mutation, or LIVE capability is introduced.


## Market-data quality milestone — ATP-MD-QUALITY-002

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-MD-QUALITY-002 | Restore fixed SELL/BID and BUY/ASK colors; attribute quote latency across broker/backend/IPC/UI; expose correctly sourced traded volume | PR #40 (`https://github.com/atheertrading/AtheerAutotrade/pull/40`) merged into the realtime feature branch, branch `feat/atp-md-quality-002-quote-sides-latency-volume`; record `docs/engineering/ATP-MD-QUALITY-002.md` | PARTIALLY IMPLEMENTED — SOURCE/IPC TIMING FIELDS ADDED; XCODE, DEMO LATENCY, SERVER-TIME CALIBRATION, AND VOLUME INGESTION PENDING |

- SELL/BID is fixed red and BUY/ASK is fixed green; quote direction is shown independently in delta fields.
- Removed the 120 ms quote-row animation. Existing 16 ms quote coalescing remains to bound main-thread update volume.
- Native IPC event receipt time is now captured separately from backend receipt time. Backend-to-client and broker-timestamp-to-backend deltas are distinct model measurements; broker timestamp delta is not yet calibrated against Capital.com server time.
- Capital.com WebSocket quote payload documents bidQty/ofrQty, not executed volume. REST historical one-minute candle responses provide optional lastTradedVolume. The volume monitor and 1M VOL display remain pending; no quote-side quantity or search snapshot is mislabeled as traded volume.
- No Xcode build, target-Mac runtime, controlled Demo price comparison, time calibration, or volume test has been performed for this branch. No live execution capability is introduced.


## Account semantics correction — ATP-ACCOUNT-SEMANTICS-001

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-ACCOUNT-SEMANTICS-001 | Correct Capital.com Funds, Equity, Available, and Margin field semantics using broker API/platform definitions and screenshot evidence | Draft PR #42: https://github.com/atheertrading/AtheerAutotrade/pull/42; branch `fix/atp-account-semantics-001-rebased`; record `docs/engineering/ATP-ACCOUNT-SEMANTICS-001.md` | IMPLEMENTED IN SOURCE — PR #42 DRAFT; XCODE BUILD, XCTEST, AND DEMO RECONCILIATION PENDING |

- Screenshot review identified a deterministic inversion: the app displayed API `balance.balance` (Equity) as Funds, displayed `balance.deposit` (Funds) as Margin, and then added P&L to Equity a second time.
- Correct mapping: Funds = `balance.deposit`; Equity = `balance.balance`; P&L = `balance.profitLoss`; Available = `balance.available`; Margin = Equity − Available.
- Regression tests were added to the existing XCTest source for the exact screenshot values and negative derived-margin rejection.
- The screenshot observations are not simultaneous; the 19-second difference is documented and small account-value differences are not treated as proof of stale data.
- Code inspection found no historical-candle reconciliation step in the live quote event path. Market quotes use WebSocket; account snapshots use one-second-target REST polling.
- PR #40 was merged into its realtime feature branch, not the broker-sync base branch. This follow-on branch carries that quote-side correction together with the account-semantics fix for review against `feat/atp-broker-001-continuous-account-sync`.
- No order placement, account mutation, RiskEngine bypass, or LIVE capability is introduced.

## Current next action

Build the macOS application and XCTest target on the owner’s Mac from `fix/atp-account-semantics-001-rebased`. Confirm the account mapping regression tests pass, then perform synchronized Capital.com Demo reconciliation and record measured account/quote latency. Do not enable LIVE trading or merge/release before the required verification and owner approval.
