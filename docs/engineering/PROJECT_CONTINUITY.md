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

- Latest observed `main` baseline after PR #18 merge: `675ea4af4d54610539218858e3d2f99c4c9a1985`.
- PR #11 (ATP-DOM-001) was merged as `fa68db5635042b43cda16e687eeffa4f138c5cbe`; user-run verification reported TypeScript build success and 10/10 backend tests passing.
- PR #12 (ATP-CAP-001) was merged as `dfeff79b0b401d4722b5d4cf8ff9c9ab24344597`; see the current main branch history for subsequent changes.
- PR #13 (architecture diagram catalogue) was merged on 2026-11-12 as `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- ATP-ARCH-REBASE-001 was merged through PR #14 as `9445a749d78c63030e9125041a6103dca0eabafc`.
- The Capital.com UI feature branch `feature/atp-cap-002-broker-connection-experience` was previously reviewed and found to make direct REST calls from SwiftUI. It is not an approved architecture pattern and must not be merged as-is.
- The user's local working copy previously contained local changes and a stash. Do not pop, drop, apply, reset, clean, force-push, or overwrite local work without a reviewed reconciliation plan.

## 4. Current implementation baseline

- Native SwiftUI macOS application shell, dashboard/navigation, and Trading Workspace exist.
- On main, backend exposes diagnostic HTTP mode and production stdio IPC v1 (PR #15). Native Swift IPC client/supervisor source and Xcode project membership were merged via PR #16; target-Mac build/runtime verification remains pending.
- Provider-neutral Trading Domain Instrument model is merged.
- Capital.com read-only REST and WebSocket adapter source exists in the repository history, with mock-based tests. A source implementation is not proof of a connected broker.
- ADR-0005 selects parent-owned anonymous stdio pipes. PR #17 merged the Capital.com screen/Keychain store and PR #18 merged Keychain load/read-back verification and credential restoration. The active branch feat/atp-capitalcom-operational-connection adds protocol v2 encrypted one-shot credential transfer, read-only Demo session methods, market search/history, WebSocket quote/OHLC event delivery to the macOS UI, Connect/Disconnect/stream controls, application-termination child shutdown, and an Xcode runtime packaging phase. These new changes are source-only pending CI, target-Mac build, crypto interoperability, packaged launch, and real Demo verification.
- No actual Capital.com Demo session, broker-originated quote, or candle is verified from this implementation.
- Market Data quality/freshness lifecycle, persistence/audit, Risk Engine, OMS, Execution Gateway, Portfolio/Reconciliation, Strategy Runtime, and Intelligence are not implemented as operational integrated modules.
- No live order path is implemented or authorized.

## 5. Architecture baseline accepted in ADR-0004

- Native SwiftUI macOS client remains the presentation/operator-control surface.
- Backend remains a Node.js/TypeScript modular monolith with explicit module ownership and typed boundaries.
- Backend owns broker lifecycle, market-data ingestion, domain orchestration, persistence, Risk, OMS, execution, and reconciliation.
- Capital.com is the primary broker target; initial broker integration remains read-only.
- ADR-0005 selects parent-owned anonymous standard-I/O pipes for production desktop IPC. Loopback HTTP remains development/diagnostic-only. The native macOS app owns Keychain access; protocol v2 transfers credentials only as AES-256-GCM ciphertext over the per-session X25519/HKDF channel.
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

## 9. Latest handoff — 2026-11-13

### ATP-ARCH-REBASE-001 — DONE / MERGED

PR #14 was merged into `main` as squash commit `9445a749d78c63030e9125041a6103dca0eabafc`. ADR-0004 establishes ATHEER Trading Pro as product identity and the modular-monolith architecture baseline.

### ATP-SEC-IPC-001 — IN PROGRESS

PR #15 merged backend stdio protocol and startup mode as `8cb8734624957c8bfb367ee8bfe4a2bbb51ce0e5`. PR #16 merged native Swift IPC protocol/supervisor source as `f13ce0e3f8157a4901c99b8d928f2540cd213adc`.

PR #17 (`feat(macOS): add Capital.com broker screen and Keychain credentials`) was merged as `9297f28fd2079dc5801cd89baf2b4723ed625a75`. PR #18 (`fix(macOS): restore and verify Capital.com Keychain credentials`) was merged as `675ea4af4d54610539218858e3d2f99c4c9a1985`. Current branch: `feat/atp-capitalcom-operational-connection`.

Batch 1 authored:
- `docs/decisions/ADR-0005-SECURE-MACOS-IPC.md` — accepted parent-owned anonymous standard-I/O pipe transport for desktop process IPC, with threat model and alternatives.
- `docs/security/LOCAL_IPC_PROTOCOL.md` — versioned NDJSON contract, strict envelope, handshake, limits, method allowlist, and safe errors.
- `services/backend/src/api/stdio-ipc.ts` — protocol handler for handshake and ping only; bounded frames, UUIDs, duplicate detection, request limits, and method allowlist.
- `services/backend/tests/stdio-ipc.test.mjs` — focused protocol tests authored but not executed.
- Updated security baseline, system overview, architecture diagrams, backend README, ADR index, task register, and implementation status.

Batch 1–2 backend work is merged. The stdio handler is wired into `server.ts` through explicit `--transport=stdio` mode; default HTTP mode remains for development diagnostics only. A child-process integration test was authored, but the merged backend build/test result is not confirmed in this work session.

Batch 3 authored and merged via PR #16:
- `apps/macos/Sources/Core/Backend/LocalIPCProtocol.swift` — strict request/response envelope handling and bounded NDJSON framing.
- `apps/macos/Sources/Core/Backend/BackendProcessSupervisor.swift` — fixed-path child launch, stdio pipes, handshake, request IDs/timeouts, stderr drain, and termination handling.
- `apps/macos/Tests/LocalIPCProtocolTests.swift` — focused XCTest source.
- Xcode project membership for the two production Swift files and the test file.
- `docs/security/MACOS_BACKEND_BUNDLE_LAYOUT.md` — fixed bundle paths and signing/packaging gates.

PR #16 is merged, but target-Mac Xcode build/runtime verification for the supervisor remains pending. PR #17 and PR #18 are merged. The active branch implements encrypted IPC v2, read-only Demo session/market search/history, and WebSocket quote/OHLC event IPC with macOS UI consumption. Broker account/position reconciliation, order/dealing, and LIVE methods remain absent.

### Next batch

1. Compile and test the native Swift IPC source and XCTest target on the user's actual Mac.
2. Run the merged backend Node 24 build/tests in a supported environment.
3. Add packaging copy phases for a pinned Node runtime and compiled backend output.
4. Verify nested code signatures, hardened-runtime behavior, process launch, timeout, child crash, and explicit restart.
5. Connect the supervisor to application lifecycle and expose process readiness.
6. Build and test PR #18's Capital.com screen/Keychain persistence correction on the target Mac; then design one-shot Keychain credential transfer before enabling connection or broker session methods.

### Local repository preservation

All work in this handoff was performed through GitHub. No local filesystem, Xcode build, or local Git working copy was accessed. Preserve all user local changes and stashes.
