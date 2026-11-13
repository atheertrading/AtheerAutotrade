# ATP-AUD-002 — ATHEER Trading Pro Design and Implementation Audit

**Date:** 2026-11-14  
**Repository:** `atheertrading/AtheerAutotrade`  
**Audit branch:** `audit/atp-design-implementation-2026-11-14`  
**Comparison baseline:** repository `main`, with relevant feature branches and pull-request descriptions inspected  
**Reference architecture:** ATP-ARCH-014 (Unified Application Architecture, Professional UX/UI, Interaction Design) and ATP-ARCH-019 (OMS, Execution Gateway, Broker Integration, and Reconciliation)  
**Audit type:** Source-level design/implementation review; not a runtime, security penetration, or performance certification

## 1. Executive conclusion

The repository contains a real native macOS application foundation, a Capital.com Demo connectivity path, market discovery, quote presentation, secure credential handoff, and read-only account/position/order snapshot methods. The owner reports that the local Xcode build currently authenticates to Capital.com and receives asset prices; this is treated as owner-reported runtime evidence and is not contradicted by older repository documents that predate that report.

The current implementation is not yet a complete professional trading workstation and is not ready to submit broker orders. The principal gap is not the existence of a broker connection. It is the incomplete integration of market-data quality, account state, charting, order preparation, risk authorization, OMS, execution, reconciliation, audit, and long-duration operational monitoring.

The current macOS UI has a consistent dark palette and a functioning navigation/workspace foundation, but several screens remain placeholders or fixed-layout compositions. The source does not yet meet the full ATP-ARCH-014 experience specification.

**Disposition:** preserve the working broker connection, existing workspace behavior, IPC boundary, Keychain ownership, and shared market-data store. Advance through bounded milestones. Do not rebuild the application or merge source-only changes as verified functionality.

## 2. Evidence and verification boundaries

Reviewed source and records include:

- `ApplicationShellView.swift`, `SidebarView.swift`, `DashboardView.swift`
- `CapitalComBrokerView.swift`, `MarketWatchView.swift`, `MarketDataStore.swift`
- `WorkspacePanelView.swift`
- `CapitalComRuntime`, `CapitalComClient`, `stdio-ipc.ts`, and `risk-engine.ts`
- `TASK_REGISTER.md`, `IMPLEMENTATION_STATUS.md`, `PROJECT_CONTINUITY.md`
- `MODULE_BOUNDARIES.md`, `SECURITY_BASELINE.md`
- ATP-ARCH-014 and ATP-ARCH-019, plus the supplied UI/UX specification and Q&A archives
- Relevant GitHub branches and PR records, including #27, #28, #29, #31, #34, #37–#43

No Xcode build, XCTest, AppKit/SwiftUI runtime interaction, accessibility audit, local filesystem comparison, or fresh Capital.com session was executed during this audit. The GitHub integration exposes file search/read but not a complete recursive repository-tree export in this session; therefore this is a focused audit of the application shell and critical trading/data paths, not a claim that every repository file has been line-by-line audited.

## 3. Verified implementation baseline

### 3.1 Present in source

- Native SwiftUI macOS application shell with sidebar navigation and Trading Workspace panel management.
- Capital.com Demo credential storage in macOS Keychain and encrypted app-to-backend credential handoff.
- Supervised backend process and versioned stdio IPC.
- Capital.com Demo session lifecycle, market search, historical-price retrieval, and WebSocket quote/OHLC event emission.
- Shared MarketDataStore and a watchlist capped at 40 instruments.
- Quote presentation with broker Bid/Ask and derived Mid/Spread.
- Read-only backend methods for account, account preferences, open positions, and working orders.
- A pure backend RiskEngine evaluator for exposure-increasing BUY/SELL market intents, with unit-test coverage in the corresponding milestone.
- PostgreSQL OMS foundation schema authored on a feature branch; the schema is not evidence of an operational database or persistence service.

### 3.2 Not present as an integrated operational path

- Broker dealing/order methods in the production IPC allowlist.
- Manual BUY/SELL order ticket connected to a backend use case.
- Enforced RiskEngine → OMS → durable intent journal/outbox → Execution Gateway → broker dealing path.
- Broker order confirmation, fill processing, partial-fill handling, unknown-outcome reconciliation, and durable order lifecycle.
- A native account/positions/orders UI consuming the available read-only account IPC snapshots.
- A complete Market Data Engine with OHLC retention, ordering, deduplication, gap detection, candle integrity, and recovery.
- Production-grade continuous broker/session health and application activity/audit presentation.

The current IPC capability list is read-only for broker connectivity and account snapshots. The CapitalComRuntime source does not expose a dealing operation. The RiskEngine source is a pure evaluator and is not wired into an order-intake/OMS/Execution Gateway path. PR #28 explicitly describes the manual order workflow as a documentation-only baseline.

## 4. Prioritized findings

### P0 — Trading safety and execution architecture

| ID | Finding | Evidence / impact | Required action |
|---|---|---|---|
| EXE-01 | No broker order-submission path | IPC capabilities contain no create/confirm/modify/cancel dealing methods; CapitalComRuntime remains read-only. BUY/SELL cannot yet be executed by ATHEER. | Implement backend-only broker dealing adapter methods after official contract review; never call broker dealing APIs from SwiftUI. |
| EXE-02 | RiskEngine is not enforced | RiskEngine is a pure evaluator; it is not integrated with an order-intake path, OMS, IPC, or Execution Gateway. | Make centralized risk validation mandatory for every exposure-increasing intent, including manual UI requests. |
| EXE-03 | OMS and durable command lifecycle are incomplete | No operational durable journal/outbox, idempotent dispatch, broker confirmation, or reconciliation path is present. A migration-only branch does not establish runtime persistence. | Implement persistence, canonical intent/order/event models, idempotency, two-stage broker confirmation, partial fills, UNKNOWN outcome handling, and restart recovery before order submission. |
| EXE-04 | Trading UI must remain explicitly non-operational | Workspace Order Entry, Positions, and Orders are placeholders. | Keep order controls disabled until the full backend path and Demo qualification gates pass. Do not imply a trade can be placed. |

### P1 — Market-data integrity and operational state

| ID | Finding | Evidence / impact | Required action |
|---|---|---|---|
| MD-01 | OHLC events are emitted but not consumed by MarketDataStore | Backend emits `broker.marketData.ohlc`; the Swift store handles status, quote, and error only. Chart panels therefore have no complete candle stream. | Add typed candle models, validation, bounded history, ordering, gap detection, persistence policy, and chart subscriptions. |
| MD-02 | Out-of-order quote protection is missing in the current main store | Quote batching replaces the pending epic payload with the last-arriving event and stored quotes are overwritten without broker-timestamp monotonicity checks. | Reject stale/duplicate/out-of-order observations; add deterministic tests for equal, older, future, and valid timestamps. |
| MD-03 | Quote freshness uses an uncalibrated broker clock in the current main store | `ageMilliseconds` subtracts brokerTimestamp from local wall-clock time; `receivedAt` is stored but not used for the displayed age. Clock offset can distort age. | Use monotonic local receipt age for transport freshness; separately expose broker timestamp offset only after server-clock calibration. |
| MD-04 | Dashboard health is based on stream status/quote count, not fresh usable quotes | A connected stream and a non-empty quote dictionary can appear healthy even when all retained quotes have aged out. | Derive feed health from fresh/delayed/degraded/stale counts, event continuity, subscription state, and backend/session health. |
| MD-05 | Market-data recovery is incomplete | No full gap detection, sequence/deduplication, OHLC integrity, durable recovery, or reconnect reconciliation is implemented. | Build and test a stateful Market Data Engine; never equate WebSocket reconnection with data continuity. |
| MD-06 | Account APIs are not yet reflected in the primary UI | Backend read-only snapshots exist, while Dashboard account metrics and activity remain unavailable placeholders. | Add a shared typed account/position/order store, authoritative observation timestamps, stale-state handling, and cross-screen consistency. |

### P1 — User experience and application design

| ID | Finding | Evidence / impact | Required action |
|---|---|---|---|
| UX-01 | Clipboard behavior is only partially complete | Root `.textSelection(.enabled)` exists in main, but this does not provide structured copy actions for every data row/object. | Retain global text selection and native paste; add copy actions for instrument, quote, account, position, order, execution, alert, and diagnostic records as those screens become available. Protect SecureField credentials. |
| UX-02 | Existing UI improvements are split across branches | PR #31 branch contains full-width broker summary, adaptive broker layout, Market Watch context-menu copy, and clearer state labels; these improvements are not all present in the main source inspected. | Reconcile PR #31 with current main and target-Mac source before integration; do not duplicate the work or assume it is runtime-verified. |
| UX-03 | Broker screen is fixed-width in main | Main source places connection metrics in a fixed 350-point column and constrains the content width; this can compress or overflow at narrower window sizes. | Use the adaptive `ViewThatFits` layout already authored on the UX branch, then verify minimum, default, and wide window sizes. |
| UX-04 | Market Watch uses a custom fixed-column HStack | Current table has fixed widths and lacks native sorting, filtering, configurable columns, keyboard row selection, and a full structured-copy menu on main. | Evolve to a native macOS table/data-grid interaction model with sorting, filtering, column sizing/visibility, keyboard navigation, and row context actions. |
| UX-05 | Navigation overstates implemented breadth | Sidebar exposes Strategies, Positions, Orders, Portfolio, Risk, Analytics, Intelligence, Activity, and Settings while several destinations/panels remain placeholders. | Mark planned/unavailable modules clearly; implement each screen only when its underlying service contract exists. |
| UX-06 | Workspace panels are mostly placeholders | Chart, Order Entry, Positions, Orders, News, History, Journal, Performance, and System Status do not yet deliver their intended functions. | Deliver panels in dependency order and show precise readiness/limitations rather than decorative empty states. |
| UX-07 | Typography and layout are not fully adaptive | Many custom font sizes are fixed at approximately 9–13 pt; compact labels can become difficult to read and do not provide a coherent semantic typography scale. | Centralize typography tokens, retain monospaced financial numerics, test text scaling and narrow layouts, and avoid clipping. |
| UX-08 | Accessibility and keyboard behavior are not qualified | Source includes some labels/help, but there is no completed VoiceOver, Full Keyboard Access, focus, contrast, and control-size audit. | Add accessibility identifiers/labels/values, visible focus, keyboard workflows, sufficient control hit areas, and UI automation/manual acceptance tests. |
| UX-09 | Brand/navigation naming is inconsistent | Main sidebar currently uses “ATHEER / AUTOTRADE” while the approved product identity is ATHEER Trading Pro. | Align product naming, sidebar hierarchy, window titles, and status language with the approved product identity. |

### P2 — Governance and verification

| ID | Finding | Evidence / impact | Required action |
|---|---|---|---|
| GOV-01 | Engineering status documents lag later work | Task Register and Project Continuity contain older baselines and do not consistently reconcile the later UI, quote-quality, account-semantics, and compile-fix PRs. | Reconcile main, active branches, PRs, local user-reported evidence, and current implementation status before each milestone close. |
| GOV-02 | Account-field semantics have conflicting descriptions | PR #37 described balance/deposit semantics differently from the later correction proposed in PR #42. | Resolve against the official Capital.com response contract and synchronized Demo snapshots before displaying financial totals. |
| GOV-03 | Build/test evidence is fragmented | Several PRs record source changes or backend CI while target-Mac build, XCTest, packaged runtime, and broker Demo checks remain pending. | Maintain a single evidence matrix with commit, environment, command, result, timestamp, and unresolved failures. |
| GOV-04 | Long-duration testing is not defined as a release gate | A short successful connection does not establish resilience through session expiry, network loss, market transitions, restarts, or extended quote load. | Adopt the sustained Demo qualification plan in Section 6. |

## 5. Clipboard acceptance contract

The owner requirement is application-wide copy and paste. The implementation must define and test the following behavior:

1. **Text selection:** selectable static text in all destinations, panels, status areas, dialogs, and diagnostic views.
2. **Native editing:** Command-C, Command-V, select-all, cut, and standard text editing in editable controls, subject to control semantics.
3. **Structured data copy:** a row-level or object-level Copy action for every table/record type, exporting stable field labels and values in plain text or TSV.
4. **Keyboard access:** context-menu actions must also be reachable using keyboard/menu commands where appropriate.
5. **Security:** passwords, API secrets, session tokens, and other protected values must never be exposed by generic copy actions.
6. **Tests:** verify Dashboard, sidebar, Brokers, Market Watch, Trading Workspace, search results, account, positions, orders, executions, alerts, and logs. Re-test every new destination as part of its acceptance criteria.

The main-branch root modifier is a useful baseline, not completion of this contract. The UX branch's Market Watch context-menu implementation is a useful existing change to reconcile, not evidence that all structured data is copyable.

## 6. Sustained Capital.com Demo qualification plan

A few hours of successful connectivity are insufficient. The following is the recommended qualification sequence. It is a proposal for acceptance criteria, not a claim that these tests have already run.

### Stage A — Controlled functional verification

- Build the exact target Xcode scheme/configuration.
- Verify Keychain save, restore, delete, reconnect, and invalid-credential handling.
- Verify Demo authentication, market search, history, subscription acknowledgement, first quote, and OHLC event handling.
- Verify 1, 5, 10, and 40-instrument watchlists where broker/API limits permit.
- Verify displayed Bid/Ask against the broker source and preserve unknown values as unavailable.

### Stage B — 72-hour soak

- Keep the application and backend supervised for at least 72 continuous hours across available market sessions.
- Record process restarts, session renewals, quote age distributions, event counts, reconnects, API errors, CPU, memory, and UI responsiveness.
- Exercise network loss/recovery, broker session expiry, backend restart, app restart, sleep/wake, and watchlist changes.
- Do not place orders during this read-only stage.

### Stage C — Seven-calendar-day resilience test

- Continue the Demo connection across market open/close transitions and periods when selected instruments are closed.
- Test high-volatility periods, quote bursts, temporary data gaps, stale/future timestamps, duplicate/out-of-order events, rate-limit responses, and partial API failures.
- Confirm stale prices are visibly stale and never become eligible for price-dependent trading.
- Confirm reconnection triggers state reconciliation and does not silently treat old data as fresh.

### Stage D — Demo order qualification (only after execution architecture is implemented)

- Use explicitly approved Demo-only test cases and tightly bounded quantities.
- Exercise BUY and SELL, supported order types, protective instructions, rejection, cancellation, partial fills, duplicate clicks, timeout/unknown outcome, broker confirmation, external broker activity, and reconciliation.
- Verify every exposure-increasing request is blocked unless the central RiskEngine approves the exact immutable intent.
- Verify OMS persistence before transmission, idempotency, recovery after process restart, and broker-confirmed final state.
- No LIVE orders are part of this qualification.

### Stage E — 30-day Demo shadow/operational observation

- Run the complete read-only market/account system, then the qualified Demo execution system once Stage D passes, for a 30-day observation window.
- Require zero unexplained duplicate commands, zero fabricated broker states, no silent stale-data use, and no unresolved critical reconciliation defects.
- Report all incidents and corrective actions. Passing the window is evidence for a separate owner review, not automatic authorization for LIVE trading.

### Required telemetry

At minimum retain timestamped, redacted records for:

- Backend/app process lifecycle and restart reason.
- Broker REST session lifecycle and authentication failures.
- WebSocket connect, subscription acknowledgement, heartbeat, disconnect, reconnect, and resubscribe.
- Quote/OHLC event receipt, validation, age, ordering, gaps, and recovery.
- API latency, status/error class, rate-limit responses, and retry/backoff.
- Account snapshot observation age and broker/local discrepancies.
- UI responsiveness, main-thread stalls, memory, CPU, and resource growth.
- For later order tests: intent ID, idempotency key, risk decision, OMS transitions, broker deal reference/confirmation, fills, and reconciliation outcome.

Secrets and broker tokens must remain redacted.

## 7. Recommended implementation sequence

1. **ATP-BASELINE-001 — Source and branch reconciliation:** identify the exact local Xcode branch/commit, compare it with GitHub main and relevant feature branches, preserve local work, and establish a clean versioned baseline.
2. **ATP-UX-001 — Broker and clipboard polish:** reconcile existing PR #31 work; complete application-wide text selection and structured-copy coverage; adaptive broker layout; correct Demo/readiness language; verify keyboard and minimum-window behavior.
3. **ATP-MD-QUALITY-003 — Market-data correctness:** timestamp semantics, monotonic ordering, deduplication, OHLC consumption, freshness-aware Dashboard, gap/recovery state, and telemetry.
4. **ATP-ACCOUNT-UI-001 — Account and trading-state presentation:** resolve account field semantics, consume broker snapshots through shared typed stores, and implement Positions/Orders read-only views.
5. **ATP-CHART-001 — First-class charting:** historical candle retrieval, OHLC stream consumption, integrity, timeframes, and chart/workspace synchronization.
6. **ATP-PERSIST-001 — Operational persistence:** implement and verify database runtime, migrations, durable intent journal/outbox, event history, and restart recovery.
7. **ATP-RISK-001 / ATP-OMS-001 / ATP-EXEC-001 — Governed Demo execution:** integrate risk authorization, OMS lifecycle, Execution Gateway, Capital.com submit/confirm, idempotency, and reconciliation.
8. **ATP-SOAK-001 — Sustained Demo qualification:** execute Stages A–E and retain the evidence package.
9. **ATP-UX-ACCESSIBILITY-001 — Final macOS quality pass:** typography, accessibility, keyboard navigation, focus, color contrast, appearance preferences, multi-window behavior, and polished empty/loading/error states.

## 8. Design quality standard

Apple-inspired quality means native macOS behavior and disciplined information design, not visual imitation or decorative gradients. The application should:

- Use the Mac's available display area efficiently while keeping information legible.
- Support resizable layouts, saved workspaces, full-screen use, and multi-window/multi-display workflows.
- Provide native menu-bar commands and standard keyboard shortcuts for common actions.
- Use native controls and tables where they improve interaction consistency; use custom components only when trading-domain requirements justify them.
- Maintain a semantic typography, spacing, color, focus, and status system.
- Support keyboard navigation, VoiceOver, visible focus, contrast, and scalable text.
- Keep broker-confirmed facts, derived metrics, estimates, and analytical interpretations visually distinguishable.
- Display connection, subscription, quote freshness, account freshness, reconciliation, and trading authorization as separate states.

## 9. Change control and release gates

- Do not overwrite or recreate existing project modules.
- Use a dedicated feature branch per bounded milestone and review diffs before integration.
- Every source change must include tests and an implementation record; update Task Register, Implementation Status, and Project Continuity with actual evidence.
- Establish a version/tag only after the corresponding baseline is built and accepted. Do not invent a release version for an unverified state.
- No broker credentials in source, logs, chat, environment variables, or command-line arguments.
- LIVE remains disabled. No code or test in this audit authorizes a real trade.
- A milestone is complete only when its acceptance criteria and verification evidence are recorded.

## 10. Audit disposition

**Verified from source:** the application and broker read-only integration foundation exist; application-wide text selection exists on main; the current MarketDataStore lacks the identified OHLC and monotonicity handling; the current backend exposes no broker dealing capability; RiskEngine is not integrated with an OMS/Execution Gateway path; several screens remain placeholders.

**Owner-reported runtime evidence:** Capital.com Demo connection and price delivery work in the local Xcode application.

**Not verified in this audit:** target-Mac build, current local/GitHub commit identity, Xcode tests for current source, long-duration stability, accessibility, packaged runtime, and broker order execution.

**Recommended next action:** reconcile the current local branch with GitHub main and the existing UX/market-data branches, then execute ATP-UX-001 and ATP-MD-QUALITY-003 as the first implementation batches without replacing the working broker connection.


## 11. Current baseline and branch reconciliation addendum — 2026-11-14

### 11.1 Current GitHub baseline
- `main` is `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.
- PR #45 (ADR-0006), PR #46 (initial OOP audit), and PR #47 (stdio dependency injection) are merged.
- PR #47 Backend CI run 43528019119 passed: TypeScript compilation passed; 51/51 Node tests passed.
- The OOP source-conformance audit remains IN PROGRESS.

### 11.2 Open work
- PR #31 / ATP-UX-001 is open and not merged. Its branch is 20 commits ahead and 54 behind current main. Backend CI passed, but target-Mac Xcode/UI acceptance remains unverified. GitHub currently reports the PR as non-draft although its body says it should remain draft until acceptance.
- PR #35 / ATP-PERSIST-003 is open as a draft. Its branch is 1 commit ahead and 39 behind current main. CI run 43453512269 failed one of 52 tests because the generated psql command omitted the required backslash before `gexec`. No real PostgreSQL server/migration test has been performed.

### 11.3 Architecture discrepancies requiring resolution before dependent implementation
1. **Persistence schema ownership:** ATP-ARCH-003 specifies domain-owned schemas (`oms`, `risk`, `execution`, `positions`, `reconciliation`, `audit`, `reference`, `integration`). Migration 0001 currently creates `atheer` and generic `trading` schemas containing OMS/idempotency/event/outbox tables. The migration has not been executed. Resolve the mapping and ownership before applying it; do not rewrite an already-applied migration.
2. **Provider-neutral contracts:** ATP-ARCH-036 remains incomplete. The merged `StdioIpcBroker` contract in `stdio-ipc.ts` imports Capital.com-specific types and exposes the current Capital.com capability surface. This is a useful injection seam, but it is not the final provider-neutral application boundary. Do not expand it without the service-contract design.
3. **Backend toolchain proposal versus implementation:** ATP-ARCH-042 proposed Express and pnpm; current source uses Node built-in HTTP APIs and npm. This is not grounds for an automatic dependency or package-manager migration. Record the accepted implementation choice or a justified deviation.
4. **Deployment scope:** older Q&A material recommends a long-term hybrid topology. PR #35 records the owner's local-Mac-only PostgreSQL decision for the current phase. Treat the latter as a scoped database deployment constraint, not a final resolution of all production-hosting decisions.
5. **Runtime evidence:** the owner reports working local Capital.com Demo authentication and broker-originated prices. This is retained as owner-reported evidence; repository CI and this source audit do not independently verify the local runtime.

### 11.4 Scope and safety
- No source code, broker permissions, order capability, database, or trading behavior is changed by this reconciliation addendum.
- No PostgreSQL migration has been executed.
- No target-Mac Xcode build, packaged runtime test, or sustained broker soak is claimed.
- No OMS/Execution Gateway dealing path or LIVE capability is present.
