# ADR-0002: Provider-neutral instrument domain model

- **Status:** Accepted for incremental domain foundation
- **Date:** 2026-11-12

## Context

AtheerAutotrade is a multi-asset platform. Backend modules need a stable representation of instruments before market-data providers, broker adapters, portfolio calculations, or strategies are integrated. Provider-specific identifiers and contract specifications must not leak into the core domain, and missing external specifications must not be replaced with invented defaults.

## Decision

- Introduce a provider-neutral `Instrument` definition in `services/backend/src/modules/trading-domain/instrument.ts`.
- Represent internal identity, symbol, display name, asset class, and explicit status.
- Treat base/quote currency and price/quantity contract specifications as optional metadata until verified source data is available.
- Represent price increments, quantity increments, and minimum quantity as positive decimal strings. Do not use JavaScript binary floating-point numbers for contract specifications.
- Validate metadata at construction time and return immutable instrument values.
- Keep provider-specific instrument IDs and mappings inside broker adapters.
- Do not add order-intent acceptance, risk evaluation, persistence, broker connectivity, or execution in this milestone.

## Consequences

The Trading Domain gains a small validated foundation without introducing runtime dependencies or provider assumptions. Downstream modules can consume normalized instrument definitions. Adapter implementations must map verified provider metadata into this contract and preserve unknown values as absent. Further domain models, including order intents, must be designed together with centralized Risk Engine and lifecycle boundaries rather than introduced as an independent execution path.
