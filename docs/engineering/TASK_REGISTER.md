# Engineering Task Register

**Last reconciled:** 2026-11-12  
**Latest observed main baseline:** `58766938b1d68c8653909f7b2c50e6e78b354dd1`  
**Active branch:** `architecture/atp-arch-rebase-001`

## Status definitions

- **DONE — MERGED:** Change is present in the repository.
- **DONE — VERIFIED:** Acceptance criteria were tested and evidence is recorded.
- **IN PROGRESS:** Implementation is underway; acceptance criteria are not yet met.
- **PENDING VERIFICATION:** Implementation is present, but required results are not confirmed.
- **PLANNED:** Not implemented.
- **BLOCKED:** Cannot proceed until a named dependency is resolved.
- **SUPERSEDED:** Replaced by a later decision or implementation.

## Completed milestones

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
| ATP-APPLE-001 | Configure Apple Development signing and resolve XCTest bundle signing | User confirmed Build Succeeded; Codex reported app/test signatures valid and 4 XCTest passed, 0 failed on x86_64 | DONE — LOCAL VERIFIED; GitHub publication not confirmed |
| ATP-DOM-001 | Provider-neutral instrument domain model | PR #11 squash-merged as `fa68db5`; user reported TypeScript build and 10 backend tests passed | DONE — MERGED AND USER-VERIFIED |
| ATA-DOC-001 | Preserve adapted Mermaid architecture catalogue | PR #13 merged as `58766938`; ten editable diagrams with provenance and target-architecture caveats | DONE — MERGED; Mermaid rendering review not recorded |

## Active milestone

| ID | Milestone | Scope | Status |
|---|---|---|---|
| ATP-ARCH-REBASE-001 | Rebase architecture and engineering governance on ATHEER Trading Pro production baseline | Product identity, modular-monolith ownership, mandatory safety/execution invariants, broker/data lifecycle, health/readiness model, reconcile continuity and task records | IN PROGRESS — architecture branch created; ADR and core architecture docs committed; consistency review and draft PR pending |

Branch: `architecture/atp-arch-rebase-001`.

### Changes committed on active branch

- `docs/decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md`
- `README.md`
- `docs/architecture/SYSTEM_OVERVIEW.md`
- `docs/architecture/MODULE_BOUNDARIES.md`
- `docs/engineering/PROJECT_CONTINUITY.md`

No runtime code, dependencies, Xcode project settings, or broker execution methods were changed. No build or tests were run for this documentation-only work.

### ATP-ARCH-REBASE-001 acceptance criteria

1. ATHEER Trading Pro is consistently recorded as product identity; AtheerAutotrade remains a temporary technical identifier pending controlled migration.
2. Modular-monolith topology and module ownership are explicit.
3. UI, strategy, and AI cannot bypass centralized Risk Engine.
4. OMS is the durable order-lifecycle owner; Execution Gateway is the only broker dealing path.
5. Unknown broker submission outcomes require reconciliation and never blind retry.
6. Broker-confirmed account/execution state is authoritative; missing data remains unknown.
7. Broker authentication, REST session, WebSocket state, feed quality, persistence, trading readiness, and LIVE authorization are distinct.
8. Local IPC and Keychain credential handoff remain blocked pending a threat-modeled transport ADR; loopback is not treated as authentication.
9. Architecture diagrams and engineering records agree with the accepted ADR.
10. A draft PR is opened with an evidence-based summary; no merge until reviewed.

## Planned implementation sequence after architecture baseline

| ID | Milestone | Dependency / scope | Status |
|---|---|---|---|
| ATP-SEC-IPC-001 | Secure local application/backend boundary and credential-provider design | Threat-model and prototype supported macOS IPC options; define Keychain ownership, client identity, token handoff, restart/revocation behavior | PLANNED |
| ATP-BE-RUNTIME-001 | Backend runtime and composition root | Lifecycle, configuration validation, dependency construction, startup/shutdown, readiness aggregation | PLANNED |
| ATP-CAP-LIFECYCLE-001 | Capital.com read-only session lifecycle integration | Secure credential provider and runtime; auth, ping, explicit connection states | PLANNED |
| ATP-MD-ENGINE-001 | Market Data ingestion and quality engine | Normalize REST/stream observations; timestamps, deduplication, gaps, freshness, OHLC validation, recovery | PLANNED |
| ATP-DOM-PERSIST-001 | Durable domain and audit persistence | Domain event contracts, migrations, append-oriented audit, recovery and idempotency foundations | PLANNED |
| ATP-RISK-001 | Central Risk Engine | Mandatory evaluation for every exposure-increasing intent; policy and reason codes | PLANNED |
| ATP-OMS-001 | Order Management System | Durable lifecycle, outbox/idempotency, unknown outcomes, broker reconciliation | PLANNED |
| ATP-EXEC-001 | Controlled Execution Gateway | Broker dealing only after OMS + Risk authorization; explicit user approval and safety gates | PLANNED |
| ATP-STRAT-001 | Strategy Runtime | Signals only; no direct execution authority | PLANNED |
| ATP-PORT-INTEL-001 | Portfolio, reconciliation, and advisory intelligence | Broker-authoritative state and advisory-only AI | PLANNED |
| ATP-SYSTEM-VERIFY-001 | End-to-end operational validation | Integration, recovery, security, safety, performance, and sustained broker evidence | PLANNED |

## Other pending verification

| ID | Item | Evidence | Status |
|---|---|---|---|
| ATP-CAP-001-BUILD | Compile adapter and run focused tests | Adapter source/tests merged; no current observed build/test result for this branch in this session | PENDING VERIFICATION |
| ATP-CAP-001-DEMO | Verify actual Capital.com Demo authentication and market data | No real session or broker-originated quote/candle evidence | PLANNED |
| ATP-MAC-ARM64-001 | Validate native app runtime on Apple Silicon | Prior runtime verification was x86_64 | PLANNED |

## Preservation constraints

- Do not pop/drop/apply the user's local stash or run destructive synchronization without a reviewed plan.
- Do not overwrite local project files with GitHub versions.
- Do not repeat Xcode tests for a backend/documentation-only milestone without a technical reason.
- No credentials in ChatGPT, source, Git, logs, or process arguments.
- LIVE dealing remains disabled; no real trade without explicit user approval.

## Current next action

Complete the remaining engineering-record and diagram consistency review for ATP-ARCH-REBASE-001, then open a draft PR. After architecture review, design and record the secure local IPC/Keychain credential-provider decision before implementing broker operations in the desktop app.

## Change log

- 2026-11-12: Added ATP-ARCH-REBASE-001 on `architecture/atp-arch-rebase-001`; ADR-0004 and core architecture docs committed.
- 2026-11-12: PR #13 Mermaid catalogue merged on main; main baseline advanced to `58766938b1d68c8653909f7b2c50e6e78b354dd1`.
- 2026-11-12: Established ATHEER Trading Pro as product identity; AtheerAutotrade retained as temporary technical identifier.
