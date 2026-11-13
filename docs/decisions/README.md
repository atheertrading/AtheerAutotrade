# Architecture decisions

Decision records document consequential architecture choices and their trade-offs.

## Accepted baseline

- [ADR-0001 — Initial Architecture](ADR-0001-INITIAL-ARCHITECTURE.md)
- [ADR-0002 — Provider-Neutral Instrument Domain Model](ADR-0002-PROVIDER-NEUTRAL-INSTRUMENT-DOMAIN.md)
- [ADR-0003 — Capital.com Read-Only Market Connectivity](ADR-0003-CAPITAL-COM-MARKET-CONNECTIVITY.md)
- [ADR-0004 — ATHEER Trading Pro Production Architecture Baseline](ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md)
- [ADR-0005 — Secure macOS Client-to-Backend IPC](ADR-0005-SECURE-MACOS-IPC.md)

ADR-0004 establishes the product identity and reconciles the modular-monolith target architecture, execution authority, broker/data lifecycle, security boundary, and runtime readiness model. Earlier ADRs remain applicable except where ADR-0004 explicitly reconciles their context.

ADR-0005 selects parent-owned anonymous standard-I/O pipes for the macOS desktop/backend process boundary. It does not authorize broker credential transfer or trading operations.


- [ADR-0006 — Object-Oriented Design Standard Across ATHEER Trading Pro](ADR-0006-OBJECT-ORIENTED-DESIGN-STANDARD.md)

ADR-0006 establishes OOP as the default design paradigm across the complete repository, with idiomatic Swift/TypeScript rules, explicit object contracts, and incremental conformance. It does not mandate class-per-file or class-per-function design.
