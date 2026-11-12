# Engineering Task Register

This register tracks milestone state and prevents completed work from being restarted. Update it after each material implementation or verification event.

**Last reconciled:** 2026-11-12  
**Repository baseline inspected:** `main` at `b18b0ff600459e2bd504a39d40c26c09b1fbaa3c`

## Status definitions

- **DONE — MERGED:** Change is present in the repository.
- **DONE — VERIFIED:** Acceptance criteria were tested and evidence is recorded.
- **PENDING VERIFICATION:** Implementation is present, but the required result has not been confirmed.
- **PLANNED:** Not implemented.
- **BLOCKED:** Cannot proceed until a named dependency is resolved.
- **SUPERSEDED:** Replaced by a later recorded decision or implementation.

## Completed repository milestones

| ID | Milestone | Evidence | Status |
|---|---|---|---|
| ATP-WS-001 | Connect Trading Workspace to application shell | PR #1 merged | DONE — MERGED |
| ATP-WS-002 | Responsive workspace panel allocation | PR #2 merged | DONE — MERGED |
| ATP-WS-003 | Workspace panel management controls | PR #3 integrated into main through PR #2 | DONE — MERGED |
| ATP-WS-004 | Workspace resizing and controlled panel drag/drop | PR #4 merged; user reported Build Succeeded | DONE — MERGED; build user-reported |
| ATP-WS-005 | Deterministic panel ordering invariants | PR #5 merged; user reported Build Succeeded | DONE — MERGED; build user-reported |
| ATP-TEST-001 | Establish hosted XCTest target and four WorkspaceManager tests | PR #6 merged | DONE — MERGED |
| ATP-TEST-002 | Correct XCTest group path in Xcode project | PR #7 merged | DONE — MERGED |
| ATP-TEST-003 | Enable app Debug testability and correct Swift key paths | PR #8 merged as `b18b0ff` | DONE — MERGED |

## Verification still requiring evidence

| ID | Item | Current evidence | Status / rule |
|---|---|---|---|
| ATP-TEST-004 | Execute all four `WorkspaceManagerTests` on the user's Xcode environment | Four tests exist in source; PR #8 merge description requests execution. No confirmed test-run result is recorded in this register. | PENDING VERIFICATION. Do not claim tests passed. Run once only if this remains the active user-approved task. |
| ATP-MAC-001 | Confirm current local Xcode build and runtime behavior after the latest merged repository changes | Repository documentation records prior environment limitations; user has reported successful builds at earlier workspace milestones, but no current post-PR-8 result is recorded here. | PENDING VERIFICATION; do not repeat builds unless needed for the active task. |

## Project capabilities not yet implemented

The current `IMPLEMENTATION_STATUS.md` remains authoritative. Its documented unimplemented areas include broker integration, credentials, account and market data, portfolio state, strategy runtime, risk evaluation, order management, execution gateway, AI services, authentication, persistence, and LIVE trading.

These are product implementation areas, not bugs to be "fixed" by project-configuration audits. Their sequencing must be established as explicit milestones.

## Codex assignment record

- Recorded purpose: address the bounded XCTest problem.
- PRs #6–#8 establish and correct the XCTest target and test source.
- Do not silently repurpose Codex for general project setup, Apple Developer configuration, or broad architecture work.
- Any future Codex use must have a specific task, allowed file scope, acceptance criteria, and a reason it is the appropriate tool.

## Current next action

No new application feature or broad Xcode/Apple Developer reconfiguration is authorized by this register.

The only clearly identified outstanding verification item from the XCTest work is ATP-TEST-004. Confirm whether it is still pending from the user's actual Xcode run before asking for another test. Do not reopen Git troubleshooting; the user confirmed that it was resolved and the files were pushed.

## Change log

- 2026-11-12: Initial register reconciled against merged PRs #1–#8 and the current repository documentation. PR merge state is repository-observed; build/test outcomes are separately labeled and not inferred from merge status.
