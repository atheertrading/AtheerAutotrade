# Project Continuity Record

**Purpose:** Preserve the authoritative handoff state between engineering sessions and prevent repeated work, lost decisions, and unsupported claims.

**Repository:** `atheertrading/AtheerAutotrade`  
**Permanent local project root (user-confirmed):** `/Users/enghossamalfahad/Developer/AtheerAutotrade`  
**Xcode project:** `apps/macos/AtheerAutotrade.xcodeproj`  
**Bundle identifier:** `com.atheerautotrade.desktop`

## 1. Project identity

AtheerAutotrade is an independent, professional automated multi-asset trading project. It is informed by applicable prior Atheer Trading Pro architecture, but it is a distinct project. Legacy assumptions must be reconciled rather than copied blindly.

The intended system separates the native macOS client, backend services, market data, broker adapters, strategies, risk management, order management, execution, portfolio, and intelligence.

## 2. Authoritative sources

| Concern | Authoritative source |
|---|---|
| Current engineering handoff and constraints | This document |
| Task status and next action | [Task Register](TASK_REGISTER.md) |
| Implemented, planned, and unvalidated functionality | [Implementation Status](IMPLEMENTATION_STATUS.md) |
| Accepted architecture decisions | `docs/decisions/` |
| Module responsibilities and safety boundaries | `docs/architecture/MODULE_BOUNDARIES.md` |
| System architecture | `docs/architecture/SYSTEM_OVERVIEW.md` |
| Security baseline | `docs/security/SECURITY_BASELINE.md` |
| Agent and Codex working rules | Repository-root `AGENTS.md` |

If documents conflict, identify the conflict, prefer newer directly verified evidence, and record the resolution.

## 3. Repository baseline

- PR #11 (ATP-DOM-001) was squash-merged on 2026-11-12 as `fa68db5635042b43cda16e687eeffa4f138c5cbe`.
- ATP-DOM-001 was verified by the user in an isolated worktree: TypeScript build succeeded and all 10 backend tests passed.
- The earlier local Git status showed the user's `main` branch behind origin and containing local changes. The user safely saved tracked and untracked changes in `stash@{0}`; the working tree then reported clean and `main...origin/main [behind 33]`.
- Do not pop, drop, apply, or overwrite that stash until the local synchronization plan is explicitly reviewed. Do not reset, clean, force-push, or change branches destructively.
- The current broker implementation is being authored on `feature/atp-cap-001-capital-market-connectivity`; it is not yet merged into main.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard, navigation destinations, and Trading Workspace are present.
- Workspace persistence, panel management, resizing, and drag/drop are present.
- Node.js/TypeScript backend exposes a local process health endpoint and structured 404 handling.
- Provider-neutral Trading Domain Instrument model is merged in PR #11.
- The new Capital.com branch contains a read-only REST client (session creation, ping, market search, historical prices) and WebSocket market-data stream (quotes and OHLC), with reconnect and keepalive behavior plus mock-based tests.
- The Capital.com adapter is not yet wired into the HTTP server or macOS application. No Keychain-backed credentials provider exists. No real Demo or Live account has been authenticated from this implementation. No real quote or candle has yet been received and verified. Therefore broker connectivity and operational market data remain **NOT VERIFIED**.
- Account/portfolio integration, strategy runtime, risk evaluation, order management, execution gateway, AI services, and LIVE trading are not implemented.

## 5. XCTest, signing, and Codex boundaries

The XCTest foundation and corrections were merged through PRs #6–#8. The user-provided Codex transcript reports four XCTest cases passed with zero failures.

On 2026-11-12, Codex also reported:
- the local Apple Development certificate TeamIdentifier matched the configured team `94W645Z9FP`;
- a one-line `TargetAttributes` correction was made in `project.pbxproj` for the test target;
- Debug build succeeded and both app and embedded XCTest bundle signatures verified;
- four XCTest cases passed, zero failures;
- verification destination was macOS x86_64; arm64 remains unverified.

The user subsequently confirmed that Xcode displayed `Build Succeeded`. The informational XCTest framework messages about skipping strip on Apple-signed binaries are not errors.

**Publication status:** The local Xcode signing correction has not been confirmed as committed/pushed to GitHub. Preserve the user's working copy and stash. Do not overwrite the local project file with the repository version.

Codex is a task-bounded implementation/test tool, not the default project architect or executor. The original authorized Codex task was the XCTest problem. Do not silently expand future Codex tasks into broad audits or unrelated implementation.

## 6. Development environment

Last user-provided environment:
- Hardware: iMac18,3 (Intel).
- macOS: Ventura 13.7.8.
- Xcode: 14.3.1.
- Swift compiler: 5.8.1.
- macOS SDK: 13.3.
- Deployment target: macOS 13.0.
- Intended architectures: x86_64 and arm64.

These are recorded environment details, not a live machine inspection. Re-check only when the toolchain changes or a task requires it.

## 7. Non-negotiable engineering constraints

- Preserve completed workspace work and unrelated local files.
- Inspect current source and project configuration before changes.
- Keep macOS deployment target at 13.0 unless a documented technical requirement justifies a change.
- Do not introduce unverified dependencies.
- Keep UI, backend, broker connectivity, risk, and execution responsibilities separate.
- Every exposure-increasing order intent must pass through the centralized Risk Engine.
- AI and UI must never bypass Risk Engine.
- Broker-confirmed data is authoritative for actual account and execution state.
- Never store broker or Apple account credentials in source code, Git, logs, or ChatGPT.
- LIVE trading remains disabled until all required safety gates and explicit user authorization are satisfied.
- Missing broker specifications or market observations must remain unknown; never fabricate defaults.
- Capital.com adapter must remain read-only until separate execution and Risk Engine milestones are accepted.

## 8. Working protocol

1. Read `AGENTS.md`, this record, the task register, and relevant implementation/architecture documents.
2. Identify the exact requested task and confirm whether it is already complete.
3. Inspect relevant current files before editing.
4. Define scope, dependencies, acceptance criteria, and verification.
5. Implement one milestone without unrelated refactoring.
6. Verify affected behavior only; do not repeat completed checks without a technical reason.
7. Record actual results and the next action in the task register and implementation status.

## 9. Latest handoff — 2026-11-12

### Completed: ATP-DOM-001

PR #11 merged at `fa68db5635042b43cda16e687eeffa4f138c5cbe`. The immutable provider-neutral Instrument model and its tests are present on main. User-run verification in the isolated worktree: `npm ci --include=dev` succeeded; `npm test` compiled TypeScript and passed 10/10 tests.

### Active: ATP-CAP-001 — Capital.com read-only market connectivity

Branch: `feature/atp-cap-001-capital-market-connectivity`.

Current branch additions:
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-client.ts`
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-market-data-stream.ts`
- `services/backend/src/modules/broker-adapters/capital-com/README.md`
- `services/backend/tests/capital-com-client.test.mjs`
- `services/backend/tests/capital-com-market-data-stream.test.mjs`
- `docs/decisions/ADR-0003-CAPITAL-COM-MARKET-CONNECTIVITY.md`

The implementation is based on the official Capital.com Public API contracts. It has not yet been compiled or run in the user's environment. It has not authenticated to a real Demo account. Do not report broker connectivity, streaming stability, or candle integrity as achieved.

### Required next actions

1. Review the new TypeScript adapter and tests for compile/runtime defects; run the backend build and focused tests in an isolated worktree based on this branch.
2. Implement a Keychain-backed credential provider and a secured local app-to-backend boundary. Do not expose credentials through unauthenticated HTTP.
3. Wire a controlled read-only connection lifecycle into the application.
4. Verify Demo authentication, market discovery, historical bars, real-time quotes, and OHLC updates using an actual Capital.com account.
5. Add quote-age monitoring, stale-data states, reconnect recovery, timestamp/gap detection, and sustained-feed evidence.
6. Only then consider the broker-connectivity milestone operationally verified.

No local stash changes have been applied or discarded. The user's local repository synchronization remains pending.
