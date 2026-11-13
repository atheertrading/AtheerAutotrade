# ATHEER Trading Pro — Project-Wide OOP Design Standard

**Applies to:** every source-code module, directory, file, test, and implementation team.  
**Decision authority:** ADR-0006.  
**Status:** Accepted project standard; legacy-code conformance is incremental and must be evidenced.

## 1. Core rule

Object-Oriented Programming is the default design paradigm throughout ATHEER Trading Pro. New and materially changed code must use clear object responsibilities, encapsulated state, explicit contracts, composition, and dependency injection.

This is a design standard, not a requirement to turn every function, file, or data structure into a class. Idiomatic Swift and TypeScript constructs are selected according to semantics. A value type, protocol, interface, enum, or pure function can be part of a sound object-oriented design.

## 2. Universal design principles

- **Single responsibility:** each object has one cohesive reason to change.
- **Encapsulation:** mutable state is private or narrowly exposed; invariants are enforced by the owning object.
- **Abstraction:** consumers depend on protocols/interfaces rather than concrete infrastructure.
- **Composition:** assemble behavior from collaborating objects; avoid deep inheritance.
- **Dependency inversion:** high-level domain/application policies do not import concrete broker, database, UI, or operating-system implementations.
- **Explicit lifecycle:** creation, startup, shutdown, cancellation, and disposal are owned and observable.
- **Least authority:** an object receives only the capabilities required for its responsibility.
- **Testability:** dependencies can be replaced by deterministic fakes at defined boundaries.
- **No hidden global state:** avoid mutable module globals and service locators.
- **Cohesive domain behavior:** keep business invariants with domain objects/policies; use application services for use-case coordination.

## 3. Directory and file conventions

Directories represent bounded contexts and architectural layers, not programming paradigms. Use consistent domain-oriented naming across the repository.

- Group code by business capability first: Markets, Brokers, Risk, Orders, Execution, Portfolio, Security.
- Within a capability, separate Domain, Application, Infrastructure, and Presentation where those layers exist.
- Keep each file focused on a primary type or a tightly related group of small types.
- Name files after their primary type, for example CapitalComSessionManager.swift, MarketDataRepository.ts, OrderIntent.ts.
- Keep interfaces/protocols near the owning domain/application contract, not buried in a provider-specific implementation folder.
- Place provider-specific implementations under the provider adapter; never leak provider types into provider-neutral domain objects.
- Keep tests aligned with the module and primary object under test.
- Do not create empty folders or move existing files solely for cosmetic consistency. Use scoped migrations with updated project membership/imports and tests.

## 4. Swift and SwiftUI rules

| Concern | Standard |
|---|---|
| Domain identity / reference lifecycle | final class where reference identity and shared lifecycle are required |
| Immutable data / value semantics | struct |
| Closed states and variants | enum |
| Service boundaries | protocol |
| Service implementation | Focused final class or value type when appropriate |
| UI | Small declarative View structs |
| State ownership | Explicit observable model/coordinator with a documented owner |
| Dependencies | Initializer injection or explicit composition root |
| Concurrency | Explicit actor/main-thread isolation and Sendable decisions where applicable |

Additional requirements:
- Do not make SwiftUI Views responsible for networking, broker session management, risk, persistence, or order execution.
- Keep UI state separate from authoritative broker/domain state.
- Use final by default for classes unless inheritance is a documented extension point.
- Do not use a class where a struct provides safer value semantics.
- Avoid oversized View files; extract cohesive subviews and behavior owners without fragmenting trivial markup.

## 5. TypeScript and Node.js rules

- Use classes for stateful services, adapters, repositories, engines, supervisors, and lifecycle owners.
- Define consumer-facing contracts using interfaces and narrow constructor-injected dependencies.
- Prefer narrow interfaces; avoid interfaces that simply mirror every method of a concrete class without a real substitution boundary.
- Use private fields or methods to protect internal mutable state.
- Use explicit startup/shutdown methods for lifecycle-owning services.
- Use pure functions for deterministic calculations, mapping, schema validation, and policies when no object identity/state is needed.
- Keep composition in a composition root; do not instantiate infrastructure dependencies inside domain objects.
- Avoid static mutable state, singleton registries, and broad Utils classes.
- Enable strict TypeScript compiler checks and validate boundary data at runtime.

## 6. Trading-domain object boundaries

- Instrument, quote, account snapshot, position, order intent, risk decision, order, execution, and portfolio concepts must have explicit domain contracts and invariants.
- Broker adapters translate provider payloads into provider-neutral domain types.
- Market-data services own ordering, deduplication, freshness, gaps, and candle integrity.
- RiskEngine owns pre-trade policy evaluation; it must not be bypassed.
- OMS owns durable intent/order lifecycle and idempotency.
- Execution Gateway is the sole broker dealing boundary and accepts only an OMS-authorized intent with a Risk decision bound to the immutable intent.
- Strategy and Intelligence objects may propose signals/intents but have no dealing authority.
- UI objects present state and collect operator intent; they never call broker dealing APIs.
- Broker-confirmed state remains authoritative; ambiguous submission outcomes require reconciliation, never blind retry.

## 7. Object contract template

For a significant new service/domain object, document its bounded-context owner; single responsibility; public interface/protocol and invariants; owned state and lifecycle; constructor dependencies; concurrency model; failure and recovery semantics; side effects and persistence; authorization/capabilities; and unit, contract, integration, and failure-path tests.

## 8. Review checklist

Reject or request revision when:
- UI code performs broker/network/database work directly.
- Domain logic imports provider SDK/API response types.
- Stateful services hide dependencies in globals or constructors instantiate concrete infrastructure.
- Mutable state is exposed without ownership or invariants.
- Inheritance is used where composition is simpler.
- A class is added only to wrap a single pure function without a domain reason.
- A folder/file reorganization breaks Xcode project membership, package exports, imports, or tests.
- Risk, OMS, or Execution boundaries are bypassed.

## 9. Adoption and conformance reporting

Assess each bounded context as Conformant, Partially conformant, Not assessed, or Blocked. Record evidence (paths, tests, review date) in implementation status. Do not label the entire project OOP-conformant until all active source areas have been inspected and exceptions documented.

Apply this standard to new code immediately. Refactor existing code only as part of an approved milestone, preserving working functionality and version history.
