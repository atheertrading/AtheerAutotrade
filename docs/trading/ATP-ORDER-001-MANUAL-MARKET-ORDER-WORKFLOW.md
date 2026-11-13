# ATP-ORDER-001 — Manual Market BUY/SELL Workflow

**Status:** DESIGN BASELINE RECORDED — IMPLEMENTATION NOT YET COMPLETE  
**Branch:** `feat/atp-manual-market-order-workflow`  
**Parent:** `feat/atp-new-batch-risk-engine-foundation` (ATP-EXEC-001 Batch 1)  
**Target broker:** Capital.com Demo first  
**Order type in scope:** Market BUY and Market SELL

## 1. Product requirement

The Trading workspace must provide an operator-controlled market-order ticket for a selected Capital.com instrument. The operator chooses BUY or SELL, enters quantity, defines mandatory protective stop-loss parameters, reviews the estimated execution and risk information, and explicitly confirms submission.

The ticket is an intent-entry surface only. It must not call Capital.com or submit an order directly.

## 2. Required execution topology

```text
SwiftUI Trading Ticket
        |
        | authenticated local IPC: order.intent.submit
        v
Backend Order Intake
        |
        | schema / identity / duplicate validation
        v
Durable OMS (intent journal + state machine)
        |
        | risk evaluation request
        v
Central RiskEngine
        |
        | immutable approval + reason codes
        v
Execution Gateway
        |
        | one authorized dealing request only
        v
Capital.com Demo REST API
        |
        | dealReference
        v
Broker Confirmation + Reconciliation
        |
        v
OMS terminal / non-terminal state + UI event
```

No alternative route is permitted. UI, strategy code, AI agents, and broker adapters cannot bypass the OMS, RiskEngine, or Execution Gateway.

## 3. Market BUY / SELL semantics

- BUY is an exposure-increasing long intent and is risk-priced against the current broker Ask.
- SELL is an exposure-increasing short intent and is risk-priced against the current broker Bid.
- The quote must be broker-originated, instrument-matched, timestamped, and within the configured freshness limit at the moment of risk evaluation.
- Quantity, instrument dealing rules, minimum/maximum size, step size, contract multiplier, currency conversion, and estimated initial margin must be sourced from broker instrument/account data. Missing values must reject the intent; no guessed defaults.
- A protective stop-loss is mandatory for the initial manual market-order release. Stop direction and distance must be validated against the correct side of the market.
- A market order does not guarantee its displayed quote as the fill price. The UI must distinguish reference quote, broker-confirmed level, and final position state.

## 4. OMS lifecycle

The durable OMS must record each intent before any broker submission and enforce a monotonic, auditable lifecycle. Minimum states:

1. RECEIVED
2. VALIDATING
3. RISK_REJECTED
4. RISK_APPROVED
5. AWAITING_OPERATOR_CONFIRMATION
6. AUTHORIZED
7. SUBMISSION_PENDING
8. BROKER_ACKNOWLEDGED
9. CONFIRMATION_PENDING
10. OPEN
11. REJECTED
12. PARTIALLY_FILLED (only if broker contract supports it)
13. UNKNOWN_OUTCOME
14. RECONCILIATION_REQUIRED
15. CANCELLED
16. FAILED

Every transition must include intent ID, idempotency key, correlation ID, timestamp, actor/source, and structured reason. Invalid transitions must fail closed.

## 5. Mandatory safety and failure behavior

- Every BUY/SELL exposure-increasing intent must pass the centralized RiskEngine using a fresh broker account snapshot and fresh quote.
- The existing RiskEngine is a pure evaluator only. It is not yet connected to OMS, IPC, Execution Gateway, or UI.
- Explicit operator confirmation must be recorded after risk approval and before authorization.
- The Execution Gateway is the sole component allowed to invoke a broker dealing endpoint.
- The broker adapter must not expose an order-placement method to UI or general IPC routing.
- A successful HTTP response containing a deal reference is not proof that a position is open. Retrieve the broker confirmation and reconcile the affected deal.
- If the submission request times out, disconnects, or returns an ambiguous outcome, set UNKNOWN_OUTCOME / RECONCILIATION_REQUIRED and query broker state. Never blindly retry a potentially accepted market order.
- Duplicate idempotency keys must not produce a second broker submission.
- Account state, positions, orders, and fills reported by Capital.com are authoritative.
- LIVE environment remains disabled. This workflow is first implemented and verified against Demo only. No Demo order may be submitted during automated tests.

## 6. Capital.com API integration scope

The implementation must verify the current official API contract before coding each operation. Intended operations include:

- Read account list and account preferences.
- Read open positions and working orders.
- Submit market position via the documented dealing endpoint only from Execution Gateway.
- Resolve the returned deal reference through the broker confirmation endpoint.
- Reconcile the broker-confirmed position and account snapshot.
- Close/amend positions and create/amend/cancel working orders are separate milestones, not implicit parts of the initial market-order release.

Session tokens (CST and X-SECURITY-TOKEN) remain in backend process memory. Credentials remain in macOS Keychain and use the existing encrypted local IPC transfer. No credentials or tokens may enter source control, logs, UI state, or ChatGPT.

## 7. Delivery batches and acceptance gates

### Batch 1 — Risk foundation (existing)
- Pure BUY/SELL risk evaluation.
- Freshness, stop-loss, exposure, position-count, and free-margin controls.
- Tests for approval and rejection reason codes.
- Existing implementation: ATP-EXEC-001 PR #27. Not yet wired into execution.

### Batch 2 — Broker account and OMS foundation
- Read-only account, position, and working-order snapshots.
- Normalized broker models with source timestamps.
- Durable append-only intent/event journal and idempotency enforcement.
- OMS state machine and transition tests.
- No broker dealing method in this batch.

### Batch 3 — Controlled Demo Execution Gateway
- Risk-approved + OMS-authorized intent only.
- Explicit operator confirmation token/record.
- One-shot broker submission and confirmation polling.
- Unknown-outcome reconciliation; no blind retry.
- Demo-only environment guard and integration tests using mocked HTTP responses.
- No live account capability.

### Batch 4 — SwiftUI manual market-order ticket
- Instrument selection, BUY/SELL controls, quantity, mandatory stop loss.
- Broker quote, spread, estimated risk, margin impact, and rejection reasons.
- Review/confirm step and order lifecycle display.
- UI communicates only through typed IPC methods; no broker access.

### Batch 5 — Demo operational verification
- User-controlled Demo account verification outside automated tests.
- Verify account snapshots, quotes, risk rejection, explicit confirmation, broker deal confirmation, and reconciliation.
- Record evidence and unresolved limitations before any separate LIVE governance decision.

## 8. Current implementation truth

At branch creation, the repository contains a Capital.com read-only session/market-data client and a pure RiskEngine on the parent branch. It does **not** yet contain broker account/position retrieval, durable OMS, Execution Gateway, dealing endpoints, order IPC, or the SwiftUI market-order ticket.

This document records the required design and delivery sequence. It does not claim that market orders can currently be submitted.
