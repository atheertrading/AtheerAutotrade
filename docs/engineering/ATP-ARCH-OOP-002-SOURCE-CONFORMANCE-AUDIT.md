# ATP-ARCH-OOP-002 — Source-Code OOP Conformance Audit

**Status:** IN PROGRESS — initial source review recorded; full repository inventory and module-by-module assessment remain open  
**Review date:** 2026-11-14  
**Repository:** `atheertrading/AtheerAutotrade`  
**Audit branch:** `audit/atp-arch-oop-002-source-conformance`  
**Normative criteria:** ADR-0006 and `docs/architecture/OOP_DESIGN_STANDARD.md`  
**Audit method:** GitHub source inspection and path-level design review; no local checkout, Xcode build, runtime test, or broker session was executed in this audit.

## 1. Purpose and scope

Assess the existing macOS Swift/SwiftUI application and Node.js/TypeScript backend against the accepted project-wide OOP standard. The review looks for:

- Classes or other objects with excessive or unrelated responsibilities.
- Missing or overly broad abstractions and contracts.
- Mutable state without clear ownership or invariant protection.
- Concrete dependencies, global state, and inappropriate dependency direction.
- Weak composition-root ownership or unclear service lifecycles.
- Inconsistent bounded-context, layer, directory, and file organization.
- Testability and observable failure/recovery behavior.

This is a staged audit, not a declaration that every source file has been inspected. The available GitHub source-search interface did not provide a complete recursive repository-tree export in this session. The modules below were selected because they form the active desktop, IPC, broker, market-data, security, and risk paths. Remaining modules are explicitly marked Not assessed.

## 2. Executive assessment

The codebase already contains several sound OOP building blocks: typed domain/transport contracts, encapsulated backend session state, a focused secret-channel object, a dedicated RiskEngine object, and provider-specific Capital.com adapter ownership.

The main design weaknesses visible in the reviewed paths are concentrated in orchestration and state ownership:

1. `MarketDataStore` combines watchlist persistence, stream lifecycle coordination, IPC event subscription, quote buffering, and presentation state. It also exposes a process-wide singleton and reaches directly into the backend supervisor.
2. `BackendProcessSupervisor` combines child-process lifecycle, IPC transport, request correlation/timeouts, handshake/secret-channel handling, and broker-specific convenience operations. It is also a global singleton.
3. `CapitalComBrokerView` owns substantial form, credential, connection, market-search, and feedback state in one declarative view. Broker operations and presentation concerns need a more explicit view-model/application-service boundary.
4. `serveStdioIpc` is a large transport/application orchestration function that constructs a concrete `CapitalComRuntime` by default and dispatches broker use cases directly. Transport parsing, capability authorization, and use-case execution need clearer seams.
5. `CapitalComRuntime` is a stateful broker-session facade, but it constructs its concrete client and stream internally and spans session, streaming, market search/history, and account snapshot delegation. Factories/contracts would improve substitution and tests.
6. Market-data value types are currently declared beside the store, while the store also performs persistence and infrastructure coordination. This weakens domain ownership and makes future chart/OHLC/data-quality expansion harder to isolate.

These findings are design risks, not proof of runtime failure. No source changes or trading behavior changes are included in this audit commit.

## 3. Module-by-module assessment

Conformance labels:
- **Conformant:** reviewed evidence meets the standard for the inspected responsibility.
- **Partially conformant:** good foundations exist, but one or more material design concerns remain.
- **Not assessed:** source coverage is insufficient for a defensible conclusion.
- **Blocked:** assessment cannot proceed because required source/dependency/evidence is unavailable.

| Area / module | Evidence inspected | Assessment | Main observations |
|---|---|---|---|
| macOS market-data presentation/state | `apps/macos/Sources/Core/MarketData/MarketDataStore.swift` | **Partially conformant** | Encapsulates published state and batches quote updates, but combines watchlist persistence, broker stream lifecycle, IPC event handling, quote buffering, and UI-facing state. Uses `static let shared` and directly depends on `BackendProcessSupervisor.shared`. Quote age is calculated from wall-clock time minus broker timestamp; `receivedAt` is retained but not used by `ageMilliseconds`. |
| macOS backend process/IPC owner | `apps/macos/Sources/Core/Backend/BackendProcessSupervisor.swift` | **Partially conformant** | Encapsulates process, pipes, request correlation, pending completions, and queue ownership. It also owns secret-channel setup and broker-specific session/market-data methods. Global singleton and concrete cross-module calls reduce substitutability and concentrate lifecycle/transport/use-case responsibilities. |
| macOS Capital.com presentation | `apps/macos/Sources/Features/Brokers/CapitalComBrokerView.swift` | **Partially conformant** | Declarative SwiftUI view, but its state surface includes credentials, saved-credential status, connection lifecycle, market discovery, result rows, and feedback. The view needs a focused presentation model plus injected application-facing broker operations. Preserve SecureField handling and Keychain ownership; do not move secrets into generic UI state services or logs. |
| Backend local IPC transport | `services/backend/src/api/stdio-ipc.ts` | **Partially conformant** | Defines narrow transport contracts and pure envelope/error helpers. The main serving function also owns framing, handshake, request replay/limit checks, capability dispatch, secret submission, and broker use-case orchestration; it constructs `CapitalComRuntime` by default. Separate transport/session policy from injected application handlers. |
| Capital.com runtime/session adapter | `services/backend/src/modules/broker-adapters/capital-com/capital-com-runtime.ts` | **Partially conformant** | Encapsulates credentials, client, session, stream and connection state. However, it directly constructs `CapitalComClient`, calls the stream factory, and combines session lifecycle, market-data lifecycle, search/history and account snapshot delegation. Introduce narrow factories/contracts only where they create a real test/substitution boundary. |
| Capital.com REST client and provider contracts | `services/backend/src/modules/broker-adapters/capital-com/capital-com-client.ts` | **Partially conformant** | Strong provider-specific types, readonly data contracts, validation helpers, and a credentials-provider interface are present. The client/parser surface is broad and requires a complete method-level review for cohesion, transport abstraction, response mapping boundaries, and test seams. |
| IPC secret channel | `services/backend/src/security/ipc-secret-channel.ts` | **Conformant for inspected responsibilities** | Focused object with private key/session-key ownership, authenticated decryption, bounded envelope validation, and explicit `destroy()`. Lifecycle cleanup on every IPC exit path and cross-language contract tests remain separate verification items. |
| Central RiskEngine | `services/backend/src/modules/risk-engine/risk-engine.ts` | **Conformant as a deterministic domain policy object** | Explicit typed intent/account/quote/policy contracts and deterministic evaluation; no infrastructure dependency or hidden mutable state. Pure validation helpers are appropriate. Its lack of integration into OMS/Execution is an architecture integration gap, not an OOP conformance defect in this class. |
| Backend broker market-data stream | `services/backend/src/modules/broker-adapters/capital-com/capital-com-market-data-stream.ts` | **Not assessed** | Search results confirm provider-specific quote/OHLC contracts and a stream factory; full implementation and lifecycle/error behavior require review. |
| Backend market-data quality/domain | `services/backend/src/modules/market-data/market-data-quality.ts` | **Not assessed** | A normalization entry point is referenced by the runtime; full contracts, policy ownership, and test coverage require review. |
| Backend composition root/runtime | `services/backend/src/server.ts` and related composition files | **Not assessed** | Need complete inspection of dependency construction, configuration, readiness, startup/shutdown, and ownership. |
| Trading domain / instrument model | `services/backend/src/modules/trading-domain/` | **Not assessed** | Need complete inventory and review of identity, invariants, provider neutrality, and object/value-type choices. |
| Persistence / PostgreSQL / migrations | `services/backend/migrations/` and persistence modules | **Not assessed** | Existing schema foundation must be distinguished from operational repository objects, migration runner, and transaction boundaries. |
| OMS / order lifecycle | order-management modules and persistence integration | **Not assessed** | Need inspect current branch/main sources and contracts; do not infer implementation from architecture documents alone. |
| Execution Gateway / dealing boundary | execution and broker adapter dealing paths | **Not assessed** | No dealing path was evidenced in the previously recorded source audit; verify current source and keep dealing disabled. |
| Strategy runtime | strategy modules | **Not assessed** | Need inventory and review of lifecycle, signal contracts, dependency direction, and absence of dealing authority. |
| Intelligence / AI | intelligence modules | **Not assessed** | Need inventory and review of advisory-only authority, typed inputs/outputs, and separation from execution. |
| Portfolio / reconciliation | portfolio modules | **Not assessed** | Need review of broker-authoritative state, projection ownership, discrepancy handling, and persistence. |
| Test architecture | backend tests and macOS XCTest sources | **Not assessed** | Need map tests to module contracts, lifecycle, failure paths, integration boundaries, and deterministic fakes. |
| Directory and file architecture | reviewed paths plus module-boundary documentation | **Partially conformant** | Bounded-context roots exist, but macOS mixes `Core/MarketData` state with broker orchestration and `Features/Brokers` presentation. Backend has a clearer `modules/broker-adapters/capital-com` boundary. Do not mass-move files; first define ownership and safe Xcode/package migration plans. |

## 4. Cross-cutting findings and priority

### P1 — State ownership and dependency inversion

- Reduce direct singleton-to-singleton dependencies between `MarketDataStore` and `BackendProcessSupervisor`.
- Introduce narrow protocols for market-data subscription/event delivery and broker application operations.
- Construct shared state owners at an explicit composition root and inject them into SwiftUI environment/dependent services.
- Avoid adding abstractions that merely mirror concrete methods; each contract must define a genuine substitution, ownership, or test boundary.

### P1 — Responsibility concentration

- Split `BackendProcessSupervisor` conceptually into process lifecycle supervision, IPC request transport/session, and broker application facade. Keep process/pipe ownership centralized where required; do not split merely by file size.
- Split `MarketDataStore` into watchlist persistence/state, stream subscription coordination, and quote projection/quality state. Define one owner for each mutable state set.
- Move Capital.com screen orchestration into a focused observable presentation model or application service; keep the SwiftUI view declarative.

### P1 — Backend transport and broker use-case boundaries

- Keep `stdio-ipc.ts` responsible for transport protocol validation and dispatch mechanics.
- Inject a typed broker/application handler into the IPC server rather than constructing `CapitalComRuntime` inside the transport function.
- Keep broker-specific protocol parsing and REST/WebSocket behavior inside the Capital.com adapter. Expose provider-neutral application contracts to other modules.

### P2 — Domain and data ownership

- Move or extract market-data domain contracts/policies into a domain-owned module when a scoped refactor is approved; keep SwiftUI presentation projections separate from broker payload types.
- Complete method-level cohesion review of `CapitalComClient` and stream factory before deciding whether further decomposition is justified.
- Verify test fakes can replace client, stream, process, and persistence boundaries without static/global hooks.

### P2 — Directory and file consistency

- Establish a path-to-bounded-context inventory for all Swift and TypeScript source and test files.
- Identify misplaced files only after ownership is agreed.
- Plan any moves as explicit small migrations, updating Xcode project membership, imports, package exports, scripts, tests, and documentation together.
- Do not create empty target directories or perform cosmetic mass-renames.

## 5. Safety and trading-domain observations

- The reviewed IPC capability list and `CapitalComRuntime` expose read-only broker operations; no dealing operation was inspected as implemented in these paths.
- `RiskEngine` remains a deterministic evaluator and is not shown integrated with OMS/Execution by this review.
- No UI, strategy, or AI component may acquire dealing authority during OOP remediation.
- Every future exposure-increasing intent must still pass the centralized RiskEngine, OMS authorization, and sole Execution Gateway boundary.
- This audit does not authorize broker order submission, LIVE mode, or any real-capital activity.

## 6. Verification limits

**Verified in source:** the exact files listed above were fetched from the audit branch's base repository source; their inspected code supports the findings stated here.

**Not verified:** complete recursive file inventory; every class/type/function; local filesystem differences; Xcode compilation; XCTest; Node build/test execution during this audit; runtime behavior; accessibility; performance; security penetration; live or Demo broker behavior.

A previous repository audit recorded Node CI evidence for specific commits and test counts. That historical evidence is not a test run performed by ATP-ARCH-OOP-002 and must not be represented as such.

## 7. Required continuation plan

1. Complete repository inventory by language, bounded context, production/test status, and ownership.
2. Inspect every active source module and update the conformance matrix with path-level evidence.
3. Fetch complete relevant files where search excerpts are insufficient; inspect imports, callers, construction sites, tests, and project/package registration.
4. Prioritize P1 findings and produce a small remediation design for each affected module.
5. For every remediation, preserve behavior, add/adjust tests, update Xcode/package membership where necessary, and record exact verification.
6. Create a versioned implementation milestone for each approved refactor; do not combine unrelated module rewrites.
7. Close ATP-ARCH-OOP-002 only when all active source areas are assessed, exceptions are documented, and required P1 remediation decisions are recorded. Full OOP compliance must not be claimed merely because the audit document exists.

## 8. Current disposition

**ATP-ARCH-OOP-002: IN PROGRESS.** Initial critical-path review identifies partially conformant state/orchestration objects and confirms good encapsulation in the IPC secret channel and RiskEngine. The audit is not complete. No source code, project configuration, broker behavior, or trading permission was changed.
