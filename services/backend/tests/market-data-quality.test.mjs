import assert from "node:assert/strict";
import test from "node:test";
import {
  MarketQuoteValidationError,
  normalizeMarketQuote
} from "../dist/modules/market-data/market-data-quality.js";

const quote = {
  epic: "OIL_CRUDE",
  bid: 75.1,
  ask: 75.2,
  timestamp: 1_800_000_000_000
};

test("normalizes Bid/Ask and derives Mid and Spread for a fresh quote", () => {
  const result = normalizeMarketQuote(quote, quote.timestamp + 2_000);
  assert.equal(result.source, "capital.com");
  assert.equal(result.mid, 75.15);
  assert.ok(Math.abs(result.spread - 0.1) < 1e-10);
  assert.equal(result.ageMs, 2_000);
  assert.equal(result.quality, "FRESH");
});

test("classifies delayed, degraded, and stale quotes using the approved thresholds", () => {
  assert.equal(normalizeMarketQuote(quote, quote.timestamp + 7_000).quality, "DELAYED");
  assert.equal(normalizeMarketQuote(quote, quote.timestamp + 12_000).quality, "DEGRADED");
  assert.equal(normalizeMarketQuote(quote, quote.timestamp + 16_000).quality, "STALE");
});

test("does not call a future-dated broker quote fresh", () => {
  const result = normalizeMarketQuote(quote, quote.timestamp - 1_000);
  assert.equal(result.quality, "UNKNOWN");
  assert.equal(result.ageMs, -1_000);
});

test("rejects invalid or inverted Bid/Ask without fabricating a replacement", () => {
  assert.throws(
    () => normalizeMarketQuote({ ...quote, bid: 75.2, ask: 75.1 }),
    MarketQuoteValidationError
  );
  assert.throws(
    () => normalizeMarketQuote({ ...quote, bid: 0 }),
    MarketQuoteValidationError
  );
});
