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

- Latest observed `main` baseline after PR #15 merge: `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`.
- PR #11 (ATP-DOM-001) was merged as `fa68db5635042b43cda16e687eeffa4f138c5cbe`; user-run verification reported TypeScript build success and 10/10 backend tests passing.
- PR #12 (ATP-CAP-001) was merged as `dfeff79b0b401d4722b5d4cf8ff9c9ab24344597`; see the current main branch history for subsequent changes.
- PR #13 (architecture diagram catalogue) was merged on 2026-11-12 as `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- ATP-ARCH-REBASE-001 was merged through PR #14 as `9445a749d78c63030e9125041a6103dca0eabafc`.
- The Capital.com UI feature branch `feature/atp-cap-002-broker-connection-experience` was previously reviewed and found to make direct REST calls from SwiftUI. It is not an approved architecture pattern and must not be merged as-is.
- The user's local working copy previously contained local changes and a stash. Do not pop, drop, apply, reset, clean, force-push, or overwrite local work without a reviewed reconciliation plan.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard/navigation, and Trading Workspace exist.
- On main, backend exposes diagnostic HTTP mode and a production stdio IPC startup mode with handshake/ping only (PR #15). The current feature branch adds the first native Swift IPC client/supervisor source and Xcode project membership; it has not been compiled or runtime-tested.
- Provider-neutral Trading Domain Instrument model is merged.
- Capital.com read-only REST and WebSocket adapter source exists in the repository history, with mock-based tests. A source implementation is not proof of a connected broker.
- No concrete macOS Keychain credential provider is implemented. ADR-0005 selects parent-owned anonymous stdio pipes; backend stdio mode is merged, and native Swift client/supervisor source is authored on the current feature branch but not yet verified. Capital.com credential-entry UI remains absent.
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

PR #15 merged backend stdio protocol and startup mode as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`.

Current branch: `security/atp-sec-ipc-001-swift-supervisor`.

Batch 1 authored:
- `docs/decisions/ADR-0005-SECURE-MACOS-IPC.md` — accepted parent-owned anonymous standard-I/O pipe transport for desktop process IPC, with threat model and alternatives.
- `docs/security/LOCAL_IPC_PROTOCOL.md` — versioned NDJSON contract, strict envelope, handshake, limits, method allowlist, and safe errors.
- `services/backend/src/api/stdio-ipc.ts` — protocol handler for handshake and ping only; bounded frames, UUIDs, duplicate detection, request limits, and method allowlist.
- `services/backend/tests/stdio-ipc.test.mjs` — focused protocol tests authored but not executed.
- Updated security baseline, system overview, architecture diagrams, backend README, ADR index, task register, and implementation status.

Batch 1–2 backend work is merged. The stdio handler is wired into `server.ts` through explicit `--transport=stdio` mode; default HTTP mode remains for development diagnostics only. A child-process integration test was authored, but the merged backend build/test result is not confirmed in this work session.

Batch 3 authored on the current branch:
- `apps/macos/Sources/Core/Backend/LocalIPCProtocol.swift` — strict request/response envelope handling and bounded NDJSON framing.
- `apps/macos/Sources/Core/Backend/BackendProcessSupervisor.swift` — fixed-path child launch, stdio pipes, handshake, request IDs/timeouts, stderr drain, and termination handling.
- `apps/macos/Tests/LocalIPCProtocolTests.swift` — focused XCTest source.
- Xcode project membership for the two production Swift files and the test file.
- `docs/security/MACOS_BACKEND_BUNDLE_LAYOUT.md` — fixed bundle paths and signing/packaging gates.

No Xcode build/test, backend build/test, runtime package, or child process execution has been performed for this batch. No Keychain provider or credential-transfer method exists; no Capital.com credential UI exists. No broker/account/order/execution method is exposed.

### Next batch

1. Compile and test the native Swift IPC source and XCTest target on the user's actual Mac.
2. Run the merged backend Node 24 build/tests in a supported environment.
3. Add packaging copy phases for a pinned Node runtime and compiled backend output.
4. Verify nested code signatures, hardened-runtime behavior, process launch, timeout, child crash, and explicit restart.
5. Connect the supervisor to application lifecycle and expose process readiness.
6. Design one-shot Keychain credential transfer, then implement the Capital.com credential UI and native Keychain provider before broker session methods.

### Local repository preservation

All work in this handoff was performed through GitHub. No local filesystem, Xcode build, or local Git working copy was accessed. Preserve all user local changes and stashes.
