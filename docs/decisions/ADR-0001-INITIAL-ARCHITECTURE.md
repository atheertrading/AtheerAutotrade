# ADR-0001: Initial architecture

- **Status:** Accepted for foundation milestone
- **Date:** 2026-11-11

## Context

AtheerAutotrade is a new independent automated multi-asset trading system. The first implementation needs a native macOS shell and a separately buildable backend without prematurely connecting to providers or implementing trading behavior.

## Decision

- Use a native SwiftUI macOS app with a macOS 13.0 deployment target and a universal x86_64/arm64 build configuration.
- Use a Node.js/TypeScript modular monolith for the backend.
- Begin with Node.js built-in HTTP modules and only a health endpoint.
- Pin TypeScript as an exact project-local development dependency.
- Establish explicit domain and adapter boundaries before implementation of integrations.
- Keep LIVE trading and all order execution out of scope.

## Consequences

The desktop shell can be built independently of backend services. The backend is small and has no third-party runtime dependencies. Future integrations must respect the risk, execution, broker, and security constraints in the module-boundary documentation. Universal app configuration does not replace arm64 runtime validation on Apple Silicon.
