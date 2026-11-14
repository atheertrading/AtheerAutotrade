# ADR-0007: End-to-End Trading Capability and Controlled Broker Execution

- **Status:** Accepted — product requirement and execution authority boundary
- **Date:** 2026-11-14
- **Supersedes:** Any interpretation of ADR-0003 that treats read-only broker connectivity as the permanent product scope

## Context

ATHEER Trading Pro is a professional trading platform. Its core product capability includes both operator-initiated manual trading and strategy-initiated automated trading, with broker-linked DEMO and LIVE account environments. Market-data display alone does not satisfy the product requirement.

ADR-0003 established read-only Capital.com connectivity as the first incremental broker-integration milestone. Its temporary exclusions for order dealing were intended to constrain that milestone, not to redefine the product as a read-only application. ATP-ORDER-001 separately records the required manual market BUY/SELL workflow.

Capital.com officially supports market-position creation through `POST /api/v1/positions` and deal confirmation through `GET /api/v1/confirms/{dealReference}`. A successful create response returns a deal reference and is not, by itself, proof that the position opened. Unknown submission outcomes require broker reconciliation and must never trigger a blind retry.

## Decision

1. **Product capability:** Manual and automated trading are mandatory product capabilities. Both must support the governed DEMO and LIVE account models. The existence of a DEMO-first implementation gate must not be interpreted as permanent DEMO-only product scope.
2. **One execution path:** Manual, strategy, and AI-assisted intents enter through the same authenticated backend order-intake and OMS path. No UI, strategy, AI agent, or broker adapter may independently call a dealing endpoint.
3. **Mandatory risk authority:** Every exposure-increasing BUY/SELL intent must be evaluated by the centralized RiskEngine using fresh broker-originated quote and account observations, broker instrument dealing rules, and a versioned risk policy. Missing or stale inputs fail closed.
4. **Durable OMS before dispatch:** The immutable intent, scoped idempotency identity, lifecycle event, risk decision, operator authorization where applicable, and dispatch outbox record must be durably committed before any dealing request can be sent.
5. **Execution Gateway exclusivity:** The Execution Gateway is the only component authorized to call Capital.com dealing methods. It accepts only a durable OMS dispatch whose risk approval and authorization are bound to the exact immutable intent.
6. **Manual authorization:** A manual order requires an explicit operator review and confirmation after risk evaluation. The confirmation is recorded against the intent. Automated orders require a separately governed strategy authorization and must not impersonate manual confirmation.
7. **Broker confirmation:** After submission, the system records the broker deal reference and retrieves the broker confirmation. The confirmed affected-deal identifiers and status are reconciled with broker-authoritative positions and working orders before the OMS reports an open/accepted state.
8. **Unknown outcome:** Network timeout, connection loss, server error, or malformed success response after submission is treated as an unknown outcome. The intent moves to reconciliation-required; the same order is not automatically submitted again.
9. **Environment isolation:** DEMO and LIVE use explicit, separately validated environments and account identity. This ADR establishes LIVE as a required product capability, but does not authorize enabling it. LIVE remains disabled until its security, risk, OMS, execution, reconciliation, recovery, and operational qualification gates pass and the owner separately authorizes activation.
10. **Incremental implementation:** Broker adapter methods may be implemented and tested in isolation, but must not be exposed through general IPC or user-facing order controls until the complete RiskEngine → durable OMS → Execution Gateway → broker confirmation path is implemented and verified.

## Consequences

- Read-only market connectivity is a completed/continuing subsystem, not the product's final trading scope.
- The manual and automated trading capabilities share the same controlled execution infrastructure.
- The first broker dealing implementation targets Capital.com DEMO. Automated tests use mocked HTTP and persistence boundaries; they do not submit real broker orders.
- PostgreSQL schema and migration execution, durable OMS, scoped idempotency, transactional outbox, order IPC, SwiftUI order ticket, Execution Gateway, confirmation/reconciliation, and DEMO operational qualification remain separate acceptance gates until each is implemented and evidenced.
- No LIVE trade or account action is authorized by this ADR.
