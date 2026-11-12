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

The GitHub comparison performed for ATP-DOM-001 identified main at commit `28bca625c6a03604e77088c652bd5a2adcd15d34` as the branch base. PR #8 remains merged at `b18b0ff600459e2bd504a39d40c26c09b1fbaa3c`. This is repository-observed state, not proof that every local working copy is synchronized.

The user confirmed that the earlier Git issue was resolved and files were pushed. Do not reopen Git troubleshooting without new evidence.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard, navigation destinations, and Trading Workspace are present.
- Workspace persistence, panel management, resizing, and drag/drop are present.
- Node.js/TypeScript backend exposes a local process health endpoint and structured 404 handling.
- The first provider-neutral Trading Domain instrument model is now authored on branch `feature/trading-domain-instrument-models`; see ATP-DOM-001 in the task register. Its tests are authored but remain pending execution.
- Broker connectivity, live market data, account/portfolio integration, strategy runtime, risk evaluation, order management, execution gateway, AI services, and LIVE trading are not implemented.

## 5. XCTest, signing, and Codex boundaries

The XCTest foundation and corrections were merged through PRs #6–#8. The user-provided Codex transcript reports four XCTest cases passed with zero failures.

On 2026-11-12, Codex also reported:
- the local Apple Development certificate TeamIdentifier matched the configured team `94W645Z9FP`;
- a one-line `TargetAttributes` correction was made in `project.pbxproj` for the test target;
- Debug build succeeded and both app and embedded XCTest bundle signatures verified;
- four XCTest cases passed, zero failures;
- verification destination was macOS x86_64; arm64 remains unverified.

The user subsequently confirmed that Xcode displayed `Build Succeeded`. The informational XCTest framework messages about skipping strip on Apple-signed binaries are not errors.

**Publication status:** The local Xcode signing correction has not been confirmed as committed/pushed to GitHub. The current feature branch does not intentionally include Xcode project or signing changes. Preserve the user's working copy; do not overwrite or reset it. Before a future release or merge that relies on signed builds, reconcile the local signing change with the repository.

Codex is a task-bounded implementation/test tool, not the default project architect or executor. The original authorized Codex task was the XCTest problem. Do not silently expand future Codex tasks into broad audits or unrelated changes.

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

## 8. Working protocol

1. Read `AGENTS.md`, this record, the task register, and relevant implementation/architecture documents.
2. Identify the exact requested task and confirm whether it is already complete.
3. Inspect relevant current files before editing.
4. Define scope, dependencies, acceptance criteria, and verification.
5. Implement one milestone without unrelated refactoring.
6. Verify affected behavior only.
7. Record actual results and the next action in the task register and implementation status.

## 9. Latest handoff — 2026-11-12

The Apple Development / XCTest signing recovery is closed on the user's local Xcode environment based on the user's `Build Succeeded` confirmation and Codex's reported signature and XCTest verification. No arm64 runtime validation is claimed.

The active implementation milestone is ATP-DOM-001: provider-neutral instrument identity and contract metadata. It is intentionally limited to a validated domain model and unit tests. It does not add broker integration, quote ingestion, order intent acceptance, risk evaluation, persistence, or execution.

Branch: `feature/trading-domain-instrument-models`.

The branch contains:
- `services/backend/src/modules/trading-domain/instrument.ts`
- `services/backend/tests/instrument.test.mjs`
- Updated Trading Domain README.

The implementation uses exact decimal strings for price/quantity increments and minimum quantity, keeps absent provider specifications absent, and freezes validated instrument objects. Tests have been authored but have not yet been executed in the user's local environment.

The next action is to validate the backend test suite on the development Mac, review the resulting PR, and merge only after successful verification. Do not repeat the completed signing repair.
