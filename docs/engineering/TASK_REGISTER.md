# Engineering Task Register

This register tracks milestone state and prevents completed work from being restarted.

**Last reconciled:** 2026-11-12  
**Main baseline:** PR #11 merge commit `fa68db5635042b43cda16e687eeffa4f138c5cbe`.

## Status definitions

- **DONE — MERGED:** Change is present in the repository.
- **DONE — VERIFIED:** Acceptance criteria were tested and evidence is recorded.
- **IN PROGRESS:** Implementation is underway; acceptance criteria are not yet met.
- **PENDING VERIFICATION:** Implementation is present, but the required result has not been confirmed.
- **PLANNED:** Not implemented.
- **BLOCKED:** Cannot proceed until a named dependency is resolved.
- **SUPERSEDED:** Replaced by a later decision or implementation.

## Completed repository milestones

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
| ATP-APPLE-001 | Configure Apple Development signing and resolve XCTest bundle signing | User confirmed `Build Succeeded`; Codex reported app/test signatures valid and 4 XCTest passed, 0 failed on x86_64 | DONE — LOCAL VERIFIED; GitHub publication not confirmed |
| ATP-DOM-001 | Provider-neutral instrument domain model | PR #11 squash-merged as `fa68db5`; user ran TypeScript build and 10 backend tests successfully | DONE — MERGED AND VERIFIED |

## Active implementation

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-CAP-001 | Capital.com read-only REST and WebSocket market connectivity | Session lifecycle, market search, historical prices, live quote/OHLC subscriptions, keepalive, bounded reconnect, mock-based tests | IN PROGRESS — source authored; build/tests and live account verification pending |

Implementation branch: `feature/atp-cap-001-capital-market-connectivity`.

Current branch files:
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-client.ts`
- `services/backend/src/modules/broker-adapters/capital-com/capital-com-market-data-stream.ts`
- `services/backend/src/modules/broker-adapters/capital-com/README.md`
- `services/backend/tests/capital-com-client.test.mjs`
- `services/backend/tests/capital-com-market-data-stream.test.mjs`
- `docs/decisions/ADR-0003-CAPITAL-COM-MARKET-CONNECTIVITY.md`

No new runtime or development dependencies were added. The adapter contains no dealing, order, position, or account mutation methods.

## ATP-CAP-001 acceptance criteria

The milestone is not complete until all criteria below are met:

1. A production-appropriate credentials provider retrieves credentials from macOS Keychain without exposing them in source, logs, environment variables, or unauthenticated HTTP.
2. The application/backend boundary is secured before broker operations are exposed.
3. Capital.com Demo session authentication succeeds and session tokens remain memory-only.
4. Provider market search resolves a real epic and maps verified metadata into the provider-neutral instrument model.
5. Historical OHLC data is retrieved and validated for a selected instrument and resolution.
6. WebSocket delivers real quote updates and OHLC events for that instrument.
7. WebSocket and REST session keepalive work within documented session limits.
8. Disconnect/reconnect recovery re-subscribes without silently losing track of feed state.
9. Quote age, timestamp order, gaps, duplicates, and candle OHLC integrity are monitored and exposed as explicit data-quality states.
10. A sustained Demo observation period is recorded with actual timestamps, reconnect evidence, and zero fabricated market observations.

A successful TypeScript build, mocked unit tests, a TCP/WebSocket handshake, or a one-time quote is not sufficient to mark this milestone verified.

## Remaining validation

| ID | Item | Evidence | Status / rule |
|---|---|---|---|
| ATP-CAP-001-BUILD | Compile backend and run focused adapter tests | Tests authored on feature branch; no execution result yet | PENDING VERIFICATION |
| ATP-CAP-001-KEYCHAIN | Implement Keychain credential provider and secure local app/backend boundary | No implementation yet | PLANNED |
| ATP-CAP-001-DEMO | Authenticate and retrieve real Demo market data | No account authentication or real data received | PLANNED |
| ATP-CAP-001-STABILITY | Verify persistent stream, stale detection, and reconnect recovery | No sustained observation evidence yet | PLANNED |
| ATP-MAC-ARM64-001 | Validate native app runtime on Apple Silicon | Current verified local build destination was x86_64 | PLANNED; do not claim arm64 runtime validation |

## Product capabilities not yet implemented

Account/portfolio integration, persistence, strategy runtime, risk evaluation, order management, execution gateway, AI services, and LIVE trading remain unimplemented.

All exposure-increasing intents must eventually pass through the centralized Risk Engine. No UI, strategy, AI, or broker-adapter route may bypass it. LIVE trading remains disabled.

## Codex assignment boundary

Codex's original authorized assignment in this workflow was the bounded XCTest problem. It is not the default executor for all project work. Any future Codex assignment must specify objective, allowed files, acceptance criteria, and verification.

## Local working-copy preservation

The user's local repository had uncommitted tracked changes and untracked files. They were saved with `git stash push --include-untracked` as `stash@{0}`. The working tree was clean afterward, but local `main` remained behind `origin/main`. Do not pop or drop the stash or run destructive synchronization until a reviewed local reconciliation plan is prepared.

## Current next action

Review and compile ATP-CAP-001 in an isolated worktree. Correct only evidenced defects. Then implement the Keychain-backed credential provider and secured local integration boundary. Do not request or repeat Xcode workspace tests for this backend milestone.

## Change log

- 2026-11-12: PR #11 merged as `fa68db5`; ATP-DOM-001 is now DONE — MERGED AND VERIFIED.
- 2026-11-12: Started ATP-CAP-001 on `feature/atp-cap-001-capital-market-connectivity`; added read-only REST session/market history client, quote/OHLC WebSocket stream, and mock-based tests. No build or live account verification is claimed.
- 2026-11-12: Recorded local changes in `stash@{0}`; do not alter the stash until local synchronization is planned.
