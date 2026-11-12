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

- Latest observed `main` baseline after PR #14 merge: `9445a749d78c63030e9125041a6103dca0eabafc`.
- PR #11 (ATP-DOM-001) was merged as `fa68db5635042b43cda16e687eeffa4f138c5cbe`; user-run verification reported TypeScript build success and 10/10 backend tests passing.
- PR #12 (ATP-CAP-001) was merged as `dfeff79b0b401d4722b5d4cf8ff9c9ab24344597`; see the current main branch history for subsequent changes.
- PR #13 (architecture diagram catalogue) was merged on 2026-11-12 as `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- ATP-ARCH-REBASE-001 was merged through PR #14 as `9445a749d78c63030e9125041a6103dca0eabafc`.
- The Capital.com UI feature branch `feature/atp-cap-002-broker-connection-experience` was previously reviewed and found to make direct REST calls from SwiftUI. It is not an approved architecture pattern and must not be merged as-is.
- The user's local working copy previously contained local changes and a stash. Do not pop, drop, apply, reset, clean, force-push, or overwrite local work without a reviewed reconciliation plan.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard/navigation, and Trading Workspace exist.
- On main, backend exposes process health and structured 404 handling. The active IPC branch adds a stdio protocol handler module, not yet wired into process startup.
- Provider-neutral Trading Domain Instrument model is merged.
- Capital.com read-only REST and WebSocket adapter source exists in the repository history, with mock-based tests. A source implementation is not proof of a connected broker.
- No concrete macOS Keychain credential provider or integrated desktop/backend process client is verified. ADR-0005 selects parent-owned anonymous stdio pipes; the backend protocol handler is not yet wired into runtime.
- No actual Capital.com Demo session, broker-originated quote, or candle is verified from this implementation.
- Market Data quality/freshness lifecycle, persistence/audit, Risk Engine, OMS, Execution Gateway, Portfolio/Reconciliation, Strategy Runtime, and Intelligence are not implemented as operational integrated modules.
- No live order path is implemented or authorized.

## 5. Architecture baseline accepted in ADR-0004

- Native SwiftUI macOS client remains the presentation/operator-control surface.
- Backend remains a Node.js/TypeScript modular monolith with explicit module ownership and typed boundaries.
- Backend owns broker lifecycle, market-data ingestion, domain orchestration, persistence, Risk, OMS, execution, and reconciliation.
- Capital.com is the primary broker target; initial broker integration remains read-only.
- ADR-0005 selects parent-owned anonymous standard-I/O pipes for production desktop IPC. Loopback HTTP remains development/diagnostic-only. The native macOS app owns Keychain access; credential transfer is deferred pending a dedicated contract.
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

### ATP-ARCH-REBASE-001 — DONE / MERGED

PR #14 was merged into `main` as squash commit `9445a749d78c63030e9125041a6103dca0eabafc`. ADR-0004 establishes ATHEER Trading Pro as product identity and the modular-monolith architecture baseline.

### ATP-SEC-IPC-001 — IN PROGRESS

Active branch: `security/atp-sec-ipc-001-stdio-boundary`, created from the merged architecture baseline.

Batch 1 authored:
- `docs/decisions/ADR-0005-SECURE-MACOS-IPC.md` — accepted parent-owned anonymous standard-I/O pipe transport for desktop process IPC, with threat model and alternatives.
- `docs/security/LOCAL_IPC_PROTOCOL.md` — versioned NDJSON contract, strict envelope, handshake, limits, method allowlist, and safe errors.
- `services/backend/src/api/stdio-ipc.ts` — protocol handler for handshake and ping only; bounded frames, UUIDs, duplicate detection, request limits, and method allowlist.
- `services/backend/tests/stdio-ipc.test.mjs` — focused protocol tests authored but not executed.
- Updated security baseline, system overview, architecture diagrams, backend README, ADR index, task register, and implementation status.

No Swift source or Xcode project file changed. The stdio handler is not wired into backend process startup. No bundled Node runtime, native Swift Process supervisor/client, Keychain provider, or credential-transfer method exists yet. No broker/account/order/execution method is exposed. No build or test result has been observed for this batch.

### Next batch

1. Wire stdio IPC into a dedicated production backend startup mode while keeping loopback HTTP health diagnostic-only.
2. Add process-level stream tests and run Node 24 build/tests in an actual supported environment.
3. Implement native Swift child-process supervision and a strict NDJSON client; update Xcode project membership.
4. Design runtime packaging/signing and verify hardened-runtime behavior.
5. Design a separate one-shot Keychain credential-transfer contract before adding broker session methods.

### Local repository preservation

All work in this handoff was performed through GitHub. No local filesystem, Xcode build, or local Git working copy was accessed. Preserve all user local changes and stashes.
