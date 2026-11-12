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

Use the following existing repository documents; do not create competing versions:

| Concern | Authoritative source |
|---|---|
| Current engineering handoff and constraints | This document |
| Task status and next action | [Task Register](TASK_REGISTER.md) |
| Implemented, planned, and unvalidated functionality | [Implementation Status](IMPLEMENTATION_STATUS.md) |
| Accepted architecture decisions | `docs/decisions/` (currently ADR-0001) |
| Module responsibilities and safety boundaries | `docs/architecture/MODULE_BOUNDARIES.md` |
| System architecture | `docs/architecture/SYSTEM_OVERVIEW.md` |
| Security baseline | `docs/security/SECURITY_BASELINE.md` |
| Agent and Codex working rules | Repository-root `AGENTS.md` |

If documents conflict, do not silently choose one. Identify the conflict, prefer newer directly verified evidence, and record the resolution.

## 3. Current repository baseline

The repository's default branch was inspected through GitHub on 2026-11-12. The observed main-branch head was:

- Commit: `b18b0ff600459e2bd504a39d40c26c09b1fbaa3c`
- This is the merge commit for PR #8, which corrected the XCTest build settings and Swift key-path expressions.
- PR #8 is closed and merged.

This is a GitHub-observed repository state, not proof that every local working copy is synchronized. The user has explicitly confirmed that the earlier Git problem was resolved and the project files were pushed successfully. Do not reopen Git troubleshooting unless the user reports a new Git problem or new evidence establishes one.

## 4. Current implementation baseline

According to the current `IMPLEMENTATION_STATUS.md` and inspected source:

- Native SwiftUI macOS application shell exists.
- Dashboard, navigation destinations, and the trading workspace UI exist.
- Workspace persistence, panel management, resizing, and drag/drop implementation are present in the repository.
- A Node.js/TypeScript backend foundation exists and currently exposes a local process health endpoint.
- The current repository documentation states that broker connectivity, live market data, account/portfolio integration, strategy runtime, risk evaluation, order management, execution gateway, AI services, and LIVE trading are not implemented.
- Do not describe planned modules as implemented.

## 5. XCTest and Codex history

The recorded Codex assignment was bounded to the XCTest problem. Codex must not be treated as the default executor for every project task or as the project architect.

The XCTest foundation and corrections were merged through:
- PR #6 — establish the hosted XCTest target and four `WorkspaceManagerTests`.
- PR #7 — correct the Tests group location in the Xcode project hierarchy.
- PR #8 — add `ENABLE_TESTABILITY = YES` to the app Debug configuration and correct Swift key-path syntax.

PR #8 merged as commit `b18b0ff600459e2bd504a39d40c26c09b1fbaa3c`.

**Verification distinction:** The source contains four workspace tests and the PR is merged. The merge itself does not prove that all four tests were executed successfully on the user's Mac. No claim of four passing XCTest tests is recorded here unless a test result is subsequently supplied or observed.

## 6. Development environment record

The last user-provided development environment record is:
- Hardware: iMac18,3 (Intel).
- macOS: Ventura 13.7.8.
- Xcode: 14.3.1.
- Swift compiler: 5.8.1.
- macOS SDK: 13.3.
- Deployment target: macOS 13.0.
- Intended architectures: x86_64 and arm64.

Treat these as recorded environment details, not a live inspection of the machine. Re-check toolchain versions only when the machine/toolchain changes or a task requires it; do not repeatedly ask the user to re-establish known facts.

## 7. Non-negotiable engineering constraints

- Preserve completed workspace work and unrelated local files.
- Inspect current source and project configuration before changes.
- Keep macOS deployment target at 13.0 unless a documented technical requirement justifies a change.
- Prefer native macOS APIs and verify API availability against the actual toolchain.
- Do not introduce unverified dependencies.
- Keep UI, backend, broker connectivity, risk, and execution responsibilities separate.
- Every exposure-increasing order intent must pass through the centralized Risk Engine.
- AI and UI must never bypass Risk Engine.
- Broker-confirmed data is authoritative for actual account and execution state.
- Never store broker or Apple account credentials in source code, Git, logs, or ChatGPT.
- LIVE trading remains disabled until all required safety gates and explicit user authorization are satisfied.

## 8. Working protocol

For every new task:

1. Read `AGENTS.md`, this continuity record, the task register, and the relevant implementation/architecture documents.
2. Identify the exact requested task and confirm whether it is already complete.
3. Inspect only the relevant current files and their history where needed.
4. Define scope, dependencies, acceptance criteria, and a minimal verification plan.
5. Implement one milestone without unrelated refactoring.
6. Verify only the affected behavior; do not rerun unchanged tests without a technical reason.
7. Record actual results and the next action in the task register and implementation status.

## 9. Update discipline

Update this document only when a durable project fact, current milestone, environment, constraint, or handoff changes. Keep dated evidence and clearly label its source as user-confirmed, repository-observed, or tool-verified. Do not turn transient conversation details into permanent project requirements.


## 10. Latest user-reported Codex session — 2026-11-12

**Scope correction:** The user clarified that Codex was originally introduced for one bounded purpose: resolving the XCTest problem. It is not the default implementation agent for broad project setup, Apple Developer configuration, or general engineering tasks. The prior instruction that expanded Codex into a full Apple/Xcode configuration task was an assistant scope error. The repository's Codex usage boundary remains mandatory.

The user subsequently ran that broader instruction. The pasted Codex transcript reports the following local working-copy changes (not yet confirmed as committed or pushed):
- `apps/macos/AtheerAutotrade.xcodeproj/project.pbxproj`: changed signing from explicitly disabled to Automatic / Apple Development and configured related project settings.
- `apps/macos/AtheerAutotrade.entitlements`: created with App Sandbox and outgoing network client entitlement.
- `apps/macos/AtheerAutotrade.xcodeproj/xcshareddata/xcschemes/AtheerAutotrade.xcscheme`: added the existing XCTest target to the shared Test action.
- Codex reported no Swift source or Workspace functionality changes.

**Verification evidence supplied by the user (Codex transcript):**
- Xcode 14.3.1, Swift 5.8.1, macOS 13.7.8, macOS SDK 13.3.
- Xcode project resolution and effective settings inspection completed.
- Normal Debug build failed at signing because no Development Team/account or valid signing identity was available on the machine.
- XCTest command succeeded with a command-line-only code-signing override; Codex reported 4 tests passed and 0 failed.
- This is transcript-reported evidence, not an independently inspected result bundle. It proves the test invocation reported success, but does not prove signed-app build, embedded signed entitlements, Apple Developer portal capability state, or runtime network behavior.
- Xcode account configuration was reported empty; local signing identity count was zero; Apple Developer portal was not checked.

**Disposition:** Treat these three project configuration changes as local/unreviewed pending changes until their actual diff and working-tree state are reviewed. Do not tell the user to rerun the tests merely to reconfirm the same reported result. Do not ask the user to troubleshoot Git; the user confirmed the previous Git issue was resolved and files were pushed. The current Apple signing blocker requires the account owner to add/sign in to the intended Apple Developer account in Xcode and select the correct Team; do not invent a Team ID or alter project signing as a workaround.

## 11. Continuity-system implementation rule

The continuity system already exists in this repository. Its authoritative files are `AGENTS.md`, `docs/engineering/PROJECT_CONTINUITY.md`, `docs/engineering/TASK_REGISTER.md`, and `docs/engineering/IMPLEMENTATION_STATUS.md`, with architecture decisions under `docs/decisions/`. Do not create duplicate `PROJECT_STATE.md`, `ARCHITECTURE_DECISIONS.md`, `IMPLEMENTATION_LOG.md`, or `CODEX_PROTOCOL.md` files unless a documented gap proves they are necessary. Update the existing sources of truth.
