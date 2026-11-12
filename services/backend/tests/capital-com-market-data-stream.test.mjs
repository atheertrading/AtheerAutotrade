import assert from "node:assert/strict";
import test from "node:test";
import { CapitalComMarketDataStream } from "../dist/modules/broker-adapters/capital-com/capital-com-market-data-stream.js";

class FakeSocket {
  readyState = 0;
  sent = [];
  listeners = new Map();

  addEventListener(type, listener) {
    const entries = this.listeners.get(type) ?? [];
    entries.push(listener);
    this.listeners.set(type, entries);
  }

  emit(type, event = {}) {
    for (const listener of this.listeners.get(type) ?? []) listener(event);
  }

  open() {
    this.readyState = 1;
    this.emit("open");
  }

  message(payload) {
    this.emit("message", { data: JSON.stringify(payload) });
  }

  send(value) {
    this.sent.push(JSON.parse(value));
  }

  close() {
    this.readyState = 3;
    this.emit("close");
  }
}

const session = {
  cst: "cst-test",
  securityToken: "security-test",
  streamingHost: "wss://api-streaming-capital.backend-capital.com/",
  createdAt: Date.now()
};

test("stream subscribes to quotes and OHLC after WebSocket opens", async () => {
  const socket = new FakeSocket();
  const statuses = [];
  const stream = new CapitalComMarketDataStream(
    async () => session,
    { onQuote() {}, onOhlc() {}, onStatus: (status) => statuses.push(status) },
    (url) => {
      assert.equal(
        url,
        "wss://api-streaming-capital.backend-capital.com/connect"
      );
      return socket;
    }
  );

  const startPromise = stream.start({
    epics: ["OIL_CRUDE", "EURUSD"],
    resolutions: ["MINUTE", "MINUTE_5"]
  });
  await Promise.resolve();
  socket.open();
  await startPromise;

  assert.equal(socket.sent.length, 2);
  assert.equal(socket.sent[0].destination, "marketData.subscribe");
  assert.deepEqual(socket.sent[0].payload.epics, ["OIL_CRUDE", "EURUSD"]);
  assert.equal(socket.sent[1].destination, "OHLCMarketData.subscribe");
  assert.deepEqual(socket.sent[1].payload.resolutions, ["MINUTE", "MINUTE_5"]);
  assert.equal(socket.sent[1].payload.type, "classic");
  assert.equal(socket.sent[0].cst, "cst-test");
  assert.equal(statuses.includes("transport-connected"), true);
  assert.equal(statuses.includes("connected"), false);

  socket.message({
    status: "OK",
    destination: "marketData.subscribe",
    payload: { subscriptions: { OIL_CRUDE: "PROCESSED", EURUSD: "PROCESSED" } }
  });
  assert.equal(statuses.includes("connected"), false);
  socket.message({
    status: "OK",
    destination: "OHLCMarketData.subscribe",
    payload: {
      subscriptions: {
        "OIL_CRUDE:MINUTE:classic": "PROCESSED",
        "OIL_CRUDE:MINUTE_5:classic": "PROCESSED",
        "EURUSD:MINUTE:classic": "PROCESSED",
        "EURUSD:MINUTE_5:classic": "PROCESSED"
      }
    }
  });
  assert.equal(statuses.at(-1), "connected");
  stream.stop();
});

test("stream normalizes live quote and OHLC updates", async () => {
  const socket = new FakeSocket();
  const quotes = [];
  const bars = [];
  const stream = new CapitalComMarketDataStream(
    async () => session,
    {
      onQuote: (quote) => quotes.push(quote),
      onOhlc: (bar) => bars.push(bar)
    },
    () => socket
  );

  const startPromise = stream.start({ epics: ["OIL_CRUDE"], resolutions: ["MINUTE_5"] });
  await Promise.resolve();
  socket.open();
  await startPromise;
  socket.message({
    status: "OK",
    destination: "quote",
    payload: {
      epic: "OIL_CRUDE",
      product: "CFD",
      bid: 75.1,
      ofr: 75.2,
      bidQty: 10,
      ofrQty: 12,
      timestamp: 1794470400000
    }
  });
  socket.message({
    status: "OK",
    destination: "ohlc.event",
    payload: {
      epic: "OIL_CRUDE",
      resolution: "MINUTE_5",
      type: "classic",
      priceType: "bid",
      t: 1794470400000,
      o: 75.0,
      h: 75.4,
      l: 74.9,
      c: 75.2
    }
  });

  assert.equal(quotes.length, 1);
  assert.equal(quotes[0].ask, 75.2);
  assert.equal(quotes[0].timestamp, 1794470400000);
  assert.equal(bars.length, 1);
  assert.equal(bars[0].resolution, "MINUTE_5");
  assert.deepEqual(
    [bars[0].open, bars[0].high, bars[0].low, bars[0].close],
    [75.0, 75.4, 74.9, 75.2]
  );
  stream.stop();
});

test("stream rejects more than 40 unique epics before opening a socket", async () => {
  let socketCreated = false;
  const stream = new CapitalComMarketDataStream(
    async () => session,
    { onQuote() {}, onOhlc() {} },
    () => {
      socketCreated = true;
      return new FakeSocket();
    }
  );

  const epics = Array.from({ length: 41 }, (_, index) => `EPIC_${index}`);
  await assert.rejects(
    stream.start({ epics, resolutions: ["MINUTE"] }),
    /between 1 and 40/
  );
  assert.equal(socketCreated, false);
  stream.stop();
});

test("stream reports malformed market data without forwarding it", async () => {
  const socket = new FakeSocket();
  const errors = [];
  const quotes = [];
  const stream = new CapitalComMarketDataStream(
    async () => session,
    {
      onQuote: (quote) => quotes.push(quote),
      onOhlc() {},
      onError: (error) => errors.push(error)
    },
    () => socket
  );

  const startPromise = stream.start({ epics: ["OIL_CRUDE"], resolutions: ["MINUTE"] });
  await Promise.resolve();
  socket.open();
  await startPromise;
  socket.message({
    destination: "quote",
    payload: { epic: "OIL_CRUDE", bid: "75.1", ofr: 75.2, timestamp: 1 }
  });

  assert.equal(quotes.length, 0);
  assert.equal(errors.length, 1);
  stream.stop();
});
