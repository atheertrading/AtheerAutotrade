# Risk Engine

The backend now contains a pure, deterministic pre-trade evaluation component for exposure-increasing BUY/SELL market intents.

## Implemented source

- Validates immutable intent identity, idempotency key, instrument epic, side, quantity, contract multiplier, stop-loss level, and broker-provided initial-margin estimate.
- Requires a matching broker quote with valid Bid/Ask, broker timestamp, and local receipt timestamp.
- Uses Ask as the BUY reference price and Bid as the SELL reference price.
- Rejects stale/future quote observations and stale/future account snapshots.
- Evaluates estimated stop-loss monetary risk, aggregate gross exposure, maximum open-position count, and minimum free-margin reserve.
- Returns immutable decisions with machine-readable rejection codes.
- Rejects missing or malformed facts; it does not invent account, market, contract, or margin values.

## Boundaries and limitations

- This component is not yet wired into an order-intake service, OMS, Execution Gateway, IPC method, strategy runtime, or UI.
- Inputs must be normalized by trusted backend services. Monetary values and the contract multiplier must be expressed consistently in the account currency.
- Broker-derived estimated initial margin and account snapshots are required; no margin model or currency conversion is inferred here.
- No Capital.com dealing endpoint is called by this module.
- No order is submitted and LIVE remains disabled.

## Verification

Focused Node tests are included in `services/backend/tests/risk-engine.test.mjs`. GitHub Actions Backend CI run 43350570347 passed TypeScript compilation and the backend test command for the initial PR revision. The subsequent freshness-hardening commit triggered a new CI run; its result must be checked before merge.
