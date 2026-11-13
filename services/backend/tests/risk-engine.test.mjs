import assert from "node:assert/strict";
import test from "node:test";
import { RiskEngine } from "../dist/modules/risk-engine/risk-engine.js";

const now = 1_800_000_000_000;
const intent = {
  intentId: "intent-001",
  idempotencyKey: "idem-001",
  epic: "OIL_CRUDE",
  side: "BUY",
  quantity: 1,
  contractMultiplier: 1,
  stopLossPrice: 74,
  estimatedInitialMargin: 500,
  requestedAt: now
};
const account = {
  currency: "USD",
  equity: 10_000,
  freeMargin: 8_000,
  grossExposure: 1_000,
  openPositions: 1,
  observedAt: now
};
const quote = {
  epic: "OIL_CRUDE",
  bid: 75,
  ask: 75.1,
  brokerTimestamp: now,
  receivedAt: now
};
const policy = {
  maxRiskPerTradePercent: 0.5,
  maxGrossExposurePercent: 100,
  maxOpenPositions: 5,
  minFreeMarginPercent: 10,
  maxQuoteAgeMs: 5_000,
  maxAccountSnapshotAgeMs: 5_000
};

test("approves an order within configured risk, exposure, margin, and freshness limits", () => {
  const result = new RiskEngine().evaluate(intent, account, quote, policy, now + 100);
  assert.equal(result.approved, true);
  assert.equal(result.referencePrice, 75.1);
  assert.ok(Math.abs(result.estimatedLoss - 1.1) < 1e-9);
  assert.deepEqual(result.reasons, []);
});

test("rejects quotes outside the freshness window and future-dated quotes", () => {
  const engine = new RiskEngine();
  assert.ok(engine.evaluate(intent, account, { ...quote, brokerTimestamp: now - 6_000 }, policy, now).reasons.includes("QUOTE_NOT_FRESH"));
  assert.ok(engine.evaluate(intent, account, { ...quote, brokerTimestamp: now + 1_000 }, policy, now).reasons.includes("QUOTE_NOT_FRESH"));
});

test("rejects a missing or incorrectly placed stop loss", () => {
  const engine = new RiskEngine();
  assert.ok(engine.evaluate({ ...intent, stopLossPrice: 0 }, account, quote, policy, now).reasons.includes("INVALID_INTENT"));
  assert.ok(engine.evaluate({ ...intent, stopLossPrice: 76 }, account, quote, policy, now).reasons.includes("STOP_LOSS_INVALID"));
});

test("rejects intents that exceed per-trade risk, aggregate exposure, position, or margin limits", () => {
  const engine = new RiskEngine();
  const result = engine.evaluate(
    { ...intent, quantity: 100, estimatedInitialMargin: 9_000 },
    { ...account, grossExposure: 9_500, openPositions: 5, freeMargin: 1_000 },
    quote,
    policy,
    now
  );
  assert.ok(result.reasons.includes("RISK_LIMIT_EXCEEDED"));
  assert.ok(result.reasons.includes("GROSS_EXPOSURE_LIMIT_EXCEEDED"));
  assert.ok(result.reasons.includes("POSITION_LIMIT_EXCEEDED"));
  assert.ok(result.reasons.includes("INSUFFICIENT_FREE_MARGIN"));
});

test("rejects an epic mismatch and malformed broker quote", () => {
  const engine = new RiskEngine();
  assert.ok(engine.evaluate(intent, account, { ...quote, epic: "OTHER" }, policy, now).reasons.includes("QUOTE_EPIC_MISMATCH"));
  assert.ok(engine.evaluate(intent, account, { ...quote, ask: quote.bid }, policy, now).reasons.includes("INVALID_QUOTE"));
});

test("rejects missing account facts and invalid risk policy rather than inventing defaults", () => {
  const engine = new RiskEngine();
  assert.ok(engine.evaluate(intent, { ...account, equity: Number.NaN }, quote, policy, now).reasons.includes("INVALID_ACCOUNT_SNAPSHOT"));
  assert.ok(engine.evaluate(intent, account, quote, { ...policy, maxRiskPerTradePercent: 0 }, now).reasons.includes("INVALID_POLICY"));
});

test("uses Bid for SELL and requires stop loss above the executable reference price", () => {
  const sell = { ...intent, side: "SELL", stopLossPrice: 76 };
  const result = new RiskEngine().evaluate(sell, account, quote, policy, now);
  assert.equal(result.approved, true);
  assert.equal(result.referencePrice, quote.bid);
});

test("rejects stale account snapshots and intents dated in the future", () => {
  const engine = new RiskEngine();
  assert.ok(engine.evaluate(intent, { ...account, observedAt: now - 6_000 }, quote, policy, now).reasons.includes("ACCOUNT_SNAPSHOT_STALE"));
  assert.ok(engine.evaluate({ ...intent, requestedAt: now + 1_000 }, account, quote, policy, now).reasons.includes("INVALID_INTENT"));
});
