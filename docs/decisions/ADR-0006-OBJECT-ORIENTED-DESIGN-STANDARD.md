# ADR-0006 — Object-Oriented Design Standard Across ATHEER Trading Pro

- **Status:** Accepted
- **Date:** 2026-11-14
- **Decision owners:** Project owner and engineering architecture
- **Scope:** Entire repository: native macOS client, backend, broker adapters, market data, domain, persistence, risk, OMS, execution, strategies, intelligence, tests, and tooling.

## Context

The project owner requires Object-Oriented Programming (OOP) as the project-wide programming paradigm, reflected consistently in source organization, directories, files, types, and implementation. Existing architecture separates module ownership and trust boundaries, but does not establish one explicit OOP coding standard for every team.

This must not be misinterpreted as making every source file a class or introducing inheritance-heavy designs. Swift and TypeScript have language-specific idioms. The standard adopts object-oriented design as the default: encapsulated state, explicit responsibilities, abstraction through interfaces/protocols, composition, dependency injection, and controlled object lifecycles. Pure functions and immutable value types remain appropriate where they improve correctness and testability.

## Decision

Adopt the repository-wide OOP standard in docs/architecture/OOP_DESIGN_STANDARD.md.

1. Model business capabilities as cohesive objects with explicit responsibilities and lifecycle.
2. Encapsulate mutable state; expose behavior through methods and narrow interfaces.
3. Prefer composition and dependency injection over deep inheritance and global mutable state.
4. Define module contracts using Swift protocols and TypeScript interfaces/abstract contracts.
5. Use immutable value objects and domain entities deliberately. Swift structs/enums are valid OOP-compatible value abstractions and must not be replaced with classes solely to satisfy a keyword-level interpretation.
6. Keep provider-specific behavior behind adapter objects and provider-neutral domain contracts.
7. Use application services/use-case objects to orchestrate domain objects; keep UI views declarative and free of business, broker, risk, and execution authority.
8. Make stateful services explicit, testable, and owned by a composition root. Avoid hidden service locators and unbounded singletons.
9. Use pure functions for deterministic calculations, validation helpers, transformations, and policies when state or identity is not required. This is a deliberate supporting technique, not a competing architecture.
10. Organize folders by bounded context and architectural layer, then files by object/type responsibility. Directory names describe ownership; they are not themselves OOP constructs.
11. Align tests with production module boundaries and verify object contracts, lifecycle, invariants, failure behavior, and interaction boundaries.
12. Do not perform a wholesale rewrite. Apply the standard incrementally as each module is touched, recording deviations and migration work.

## Language-specific application

### Swift / SwiftUI
- Use protocols for service and repository boundaries; inject dependencies through initializers or explicit composition.
- Use classes for identity-bearing reference objects, long-lived coordinators, observable state owners, process supervisors, and services where reference semantics are required.
- Use structs for immutable domain values, request/response models, configuration snapshots, and view composition.
- Use enums for closed state machines and discriminated states.
- Keep SwiftUI View types declarative. Extract stateful behavior into focused model/coordinator/service objects. Views must not own broker calls, risk decisions, OMS transitions, or dealing logic.
- Prefer value semantics for data and explicit ownership for mutable reference state.

### TypeScript / Node.js
- Use classes for stateful adapters, repositories, application services, managers, engines, supervisors, and lifecycle-owning components.
- Define contracts with interfaces and narrow constructor-injected dependencies.
- Use explicit domain entities/value objects where identity, invariants, or behavior justify them.
- Avoid static mutable state, broad utility classes, inheritance trees, and module-global service instances.
- Keep pure functions for deterministic risk calculations and data normalization when easier to reason about and test.
- Instantiate the object graph in a composition root; do not instantiate concrete infrastructure dependencies inside domain logic.

## Required project structure

Follow bounded-context and layer ownership. This is a target pattern, not authorization to move existing files without a scoped migration:

    apps/macos/
      Sources/
        App/                         # composition root and app lifecycle
        Core/
          Domain/
          Application/
          Infrastructure/
          DesignSystem/
        Features/
          Markets/{Domain,Application,Infrastructure,Presentation}/
          Brokers/{Domain,Application,Infrastructure,Presentation}/
          Trading/{Domain,Application,Infrastructure,Presentation}/

    services/backend/src/
      composition/
      shared/{domain,application,infrastructure}/
      modules/
        trading-domain/{domain,application}/
        broker-adapters/capital-com/{domain,application,infrastructure}/
        market-data/{domain,application,infrastructure}/
        risk-engine/{domain,application}/
        order-management/{domain,application,infrastructure}/
        execution/{application,infrastructure}/
        portfolio/
        persistence/
        security/
        api/

Existing paths may differ. Preserve them until a milestone explicitly authorizes a safe migration. Do not create empty folders merely to imitate this tree.

## Required object design checklist

Every new or materially refactored module must document responsibility and ownership; public protocol/interface and invariants; state ownership and lifecycle; constructor dependencies and composition-root registration; error semantics; concurrency/thread-safety; persistence and event side effects; tests; security/authorization boundary; and, for trading modules, the centralized RiskEngine → OMS → Execution Gateway constraints.

## Consequences

**Benefits:** consistent object ownership, testable boundaries, clearer lifecycle/dependency management, easier broker-provider substitution, and less coupling between UI, domain, and infrastructure.

**Trade-offs:** contracts and object types can become ceremony if applied mechanically. This standard requires cohesive behavior and explicit justification, not a class-per-file or class-per-function rule.

**Migration:** existing source is not automatically compliant merely because this ADR is accepted. Implementation status and task register must identify modules not yet assessed. Apply the standard incrementally and preserve working functionality.

## Acceptance

- This ADR and the OOP Design Standard are committed.
- Root engineering instructions require compliance for all future source changes.
- Module-boundary documentation links to the standard.
- Existing code is assessed module-by-module; no claim of full OOP compliance is made until audit and remediation are complete.
