import assert from "node:assert/strict";
import test from "node:test";
import {
  createInstrument,
  InstrumentValidationError
} from "../dist/modules/trading-domain/instrument.js";

const validInput = {
  id: "instrument:eurusd",
  symbol: "EURUSD",
  name: "Euro / US Dollar",
  assetClass: "forex",
  status: "active",
  baseCurrency: "EUR",
  quoteCurrency: "USD",
  priceIncrement: "0.00001",
  quantityIncrement: "0.01",
  minimumQuantity: "0.01"
};

test("creates a validated provider-neutral instrument", () => {
  const instrument = createInstrument(validInput);
  assert.equal(instrument.id, "instrument:eurusd");
  assert.equal(instrument.symbol, "EURUSD");
  assert.equal(instrument.assetClass, "forex");
  assert.equal(instrument.priceIncrement, "0.00001");
  assert.equal(instrument.minimumQuantity, "0.01");
});

test("trims identity and display text without changing symbol case", () => {
  const instrument = createInstrument({
    ...validInput,
    id: "  instrument:custom  ",
    symbol: "  cfd:US500  ",
    name: "  US 500 Index  "
  });
  assert.equal(instrument.id, "instrument:custom");
  assert.equal(instrument.symbol, "cfd:US500");
  assert.equal(instrument.name, "US 500 Index");
});

test("does not invent absent provider contract specifications", () => {
  const instrument = createInstrument({
    id: "instrument:unknown",
    symbol: "UNKNOWN",
    name: "Unspecified Instrument",
    assetClass: "other",
    status: "unknown"
  });
  assert.equal("priceIncrement" in instrument, false);
  assert.equal("quantityIncrement" in instrument, false);
  assert.equal("minimumQuantity" in instrument, false);
  assert.equal("quoteCurrency" in instrument, false);
});

test("returns an immutable instrument", () => {
  const instrument = createInstrument(validInput);
  assert.equal(Object.isFrozen(instrument), true);
});

test("rejects empty identifiers", () => {
  assert.throws(
    () => createInstrument({ ...validInput, id: "  " }),
    InstrumentValidationError
  );
});

test("rejects unsupported asset classes and statuses", () => {
  assert.throws(
    () => createInstrument({ ...validInput, assetClass: "unknown-class" }),
    InstrumentValidationError
  );
  assert.throws(
    () => createInstrument({ ...validInput, status: "trading" }),
    InstrumentValidationError
  );
});

test("rejects malformed currency codes", () => {
  assert.throws(
    () => createInstrument({ ...validInput, quoteCurrency: "usd" }),
    InstrumentValidationError
  );
  assert.throws(
    () => createInstrument({ ...validInput, baseCurrency: "US" }),
    InstrumentValidationError
  );
});

test("rejects non-positive, numeric, or exponent-form contract values", () => {
  for (const value of ["0", "0.0", "-0.01", "1e-5", "01.2", "1."]) {
    assert.throws(
      () => createInstrument({ ...validInput, priceIncrement: value }),
      InstrumentValidationError
    );
  }
  assert.throws(
    () => createInstrument({ ...validInput, quantityIncrement: 0.01 }),
    InstrumentValidationError
  );
});
