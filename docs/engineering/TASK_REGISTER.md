# Engineering Task Register

This register tracks milestone state and prevents completed work from being restarted.

**Last reconciled:** 2026-11-12  
**Repository baseline:** `main` at `b18b0ff600459e2bd504a39d40c26c09b1fbaa3c` when inspected for this work.

## Status definitions

- **DONE — MERGED:** Change is present in the repository.
- **DONE — VERIFIED:** Acceptance criteria were tested and evidence is recorded.
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
| ATP-APPLE-001 | Configure Apple Development signing and resolve XCTest bundle signing | User confirmed `Build Succeeded`; Codex reported app/test signatures valid and 4 XCTest passed, 0 failed on x86_64 | DONE — LOCAL VERIFIED; GitHub publication of local signing correction not confirmed |

## Active implementation

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-DOM-001 | Provider-neutral instrument domain model | Immutable instrument identity, asset class/status, optional currency and contract metadata, exact decimal strings, runtime validation, unit tests | PENDING VERIFICATION |

Implementation branch: `feature/trading-domain-instrument-models`.

Files authored:
- `services/backend/src/modules/trading-domain/instrument.ts`
- `services/backend/tests/instrument.test.mjs`
- `services/backend/src/modules/trading-domain/README.md`

No new runtime or development dependencies were added. No broker, market-data, order, risk, persistence, UI, or execution path was introduced.

## Remaining validation

| ID | Item | Evidence | Status / rule |
|---|---|---|---|
| ATP-DOM-001-VERIFY | Run backend build and tests including instrument validation cases | Test source authored; no local execution result yet | PENDING VERIFICATION. Run `npm test` in `services/backend` once after pulling this branch. |
| ATP-MAC-ARM64-001 | Validate native app runtime on Apple Silicon | Current verified local build destination was x86_64 | PLANNED; do not claim arm64 runtime validation. |

## Product capabilities not yet implemented

Broker integration, credentials, account data, market data, portfolio state, persistence, strategy runtime, risk evaluation, order management, execution gateway, AI services, authentication, and LIVE trading remain unimplemented.

These are planned product capabilities, not project-configuration defects. All exposure-increasing intents must eventually pass through the centralized Risk Engine. No execution route may bypass it.

## Codex assignment boundary

Codex's original authorized assignment in this workflow was the bounded XCTest problem. It is not the default executor for all project work. Any future Codex assignment must specify objective, allowed files, acceptance criteria, and verification.

## Current next action

Validate ATP-DOM-001 by running the backend build and test suite on the user's development Mac. Review the PR and merge only after the test suite passes. Do not rerun the completed Xcode signing repair or reopen Git troubleshooting.

## Change log

- 2026-11-12: Reconciled signing status against the user's `Build Succeeded` confirmation and the supplied Codex report.
- 2026-11-12: Started ATP-DOM-001 on `feature/trading-domain-instrument-models`; model and tests authored, execution pending.
