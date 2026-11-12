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

- Latest observed `main` baseline before this milestone: `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- PR #11 (ATP-DOM-001) was merged as `fa68db5635042b43cda16e687eeffa4f138c5cbe`; user-run verification reported TypeScript build success and 10/10 backend tests passing.
- PR #12 (ATP-CAP-001) was merged as `dfeff79b0b401d4722b5d4cf8ff9c9ab24344597`; see the current main branch history for subsequent changes.
- PR #13 (architecture diagram catalogue) was merged on 2026-11-12 as `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- The current architecture rebase work is on `architecture/atp-arch-rebase-001`, created from the then-current `main` baseline. It is documentation/architecture work only at this stage.
- The Capital.com UI feature branch `feature/atp-cap-002-broker-connection-experience` was previously reviewed and found to make direct REST calls from SwiftUI. It is not an approved architecture pattern and must not be merged as-is.
- The user's local working copy previously contained local changes and a stash. Do not pop, drop, apply, reset, clean, force-push, or overwrite local work without a reviewed reconciliation plan.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard/navigation, and Trading Workspace exist.
- Backend currently exposes process health and structured 404 handling.
- Provider-neutral Trading Domain Instrument model is merged.
- Capital.com read-only REST and WebSocket adapter source exists in the repository history, with mock-based tests. A source implementation is not proof of a connected broker.
- No concrete macOS Keychain credential provider or authenticated desktop/backend boundary is verified.
- No actual Capital.com Demo session, broker-originated quote, or candle is verified from this implementation.
- Market Data quality/freshness lifecycle, persistence/audit, Risk Engine, OMS, Execution Gateway, Portfolio/Reconciliation, Strategy Runtime, and Intelligence are not implemented as operational integrated modules.
- No live order path is implemented or authorized.

## 5. Architecture baseline accepted in ADR-0004

- Native SwiftUI macOS client remains the presentation/operator-control surface.
- Backend remains a Node.js/TypeScript modular monolith with explicit module ownership and typed boundaries.
- Backend owns broker lifecycle, market-data ingestion, domain orchestration, persistence, Risk, OMS, execution, and reconciliation.
- Capital.com is the primary broker target; initial broker integration remains read-only.
- Loopback binding alone is not authentication. The desktop/backend transport and credential handoff require a focused threat-modeled design ADR before broker operations are exposed.
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

## 9. Latest handoff — 2026-11-12

### ATP-ARCH-REBASE-001 — IN PROGRESS

Branch: `architecture/atp-arch-rebase-001`.

Created and committed:
- `docs/decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md` — product identity, modular-monolith topology, module ownership, mandatory risk/OMS/execution invariants, broker/data lifecycle, deferred local IPC decision, and distinct health/readiness states.
- Updated system overview, module boundaries, and repository README to align with ADR-0004 and ATHEER Trading Pro product identity.

No runtime source code changed. No build or tests were run because this is a documentation/architecture milestone.

- Draft PR #14 is open: https://github.com/atheertrading/AtheerAutotrade/pull/14. It is not merged; GitHub reported mergeable=false at creation, so inspect the PR state/checks before any merge decision.

### Remaining within ATP-ARCH-REBASE-001

1. Reconcile the remaining engineering status documents with the accepted product identity and current branch/PR evidence.
2. Review the architecture catalogue against ADR-0004 and update only material mismatches.
3. Open a draft PR for technical review; do not merge until architecture consistency is checked.
4. After this milestone is reviewed, begin a focused secure local IPC/credential-provider architecture spike and record its decision before coding the broker app integration.

### Local repository preservation

The user's local project and stash must remain untouched by GitHub-side work. No local filesystem or Xcode build was accessed in this session.
