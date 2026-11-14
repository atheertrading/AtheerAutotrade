# ATP-EXEC-002 — Capital.com Market Dealing Adapter

**Status:** IMPLEMENTED IN SOURCE — BACKEND CI PENDING  
**Branch:** `feat/atp-exec-002-capital-com-dealing-adapter`  
**Product requirement:** ADR-0007 and ATP-ORDER-001  
**Broker:** Capital.com; DEMO target for first operational qualification

## Scope implemented

- Added typed market-position request and submission contracts to the existing CapitalComClient.
- Added the documented authenticated `POST /api/v1/positions` call.
- Requires a valid epic, BUY/SELL direction, positive size, and mandatory positive stop-loss level. Optional take-profit level is passed only when supplied.
- Rejects LIVE dealing even if a client is constructed with the live environment; the first adapter release is DEMO-only. Rejects a missing local session before any network request.
- Added typed `GET /api/v1/confirms/{dealReference}` parsing, including affected-deal identifiers and broker statuses.
- Added `CapitalComSubmissionUnknownError`. Transport failures, HTTP 5xx responses, invalid JSON, and malformed successful submission responses are treated as unknown outcomes; callers must reconcile and must not retry automatically.
- HTTP 4xx responses remain explicit broker API rejections.
- Added deterministic mock tests. No real broker order is submitted by tests.

## Deliberate exposure boundary

These methods are broker-adapter infrastructure capabilities only. They are not exposed through `StdioIpcBroker`, IPC capabilities, HTTP routes, SwiftUI, strategy runtime, or AI. The production order path remains unavailable until the durable OMS, mandatory RiskEngine authorization, Execution Gateway, and reconciliation path are implemented. This prevents a direct broker-call bypass while adding the missing broker dealing capability to the codebase.

## Acceptance criteria still open

1. Backend TypeScript build and all tests pass in CI.
2. Contract tests cover request validation, authenticated POST, deal-reference response, missing-session and LIVE rejection, 4xx rejection, ambiguous outcomes, and confirmation parsing.
3. Durable PostgreSQL migrations and repository implementation are executed and integration-tested before OMS dispatch can be enabled.
4. OMS enforces immutable intent, scoped idempotency, state transitions, and transactional outbox.
5. Execution Gateway accepts only OMS-authorized, RiskEngine-approved intents.
6. DEMO integration verifies actual broker confirmation and subsequent position reconciliation under explicit operator control.
7. Manual order ticket and automated strategy intents use the same backend order-intake path.
8. LIVE remains disabled until separate qualification and explicit owner authorization.

## Files

- `services/backend/src/modules/broker-adapters/capital-com/capital-com-client.ts`
- `services/backend/tests/capital-com-dealing-client.test.mjs`
- `docs/decisions/ADR-0007-TRADING-CAPABILITY-AND-CONTROLLED-EXECUTION.md`
- `docs/engineering/ATP-EXEC-002-CAPITAL-COM-DEALING-ADAPTER.md`

## Verification record

- Source changes authored on the feature branch.
- No local Terminal command, Xcode build, backend build, CI result, database operation, or live/demo broker order is claimed at this stage.
