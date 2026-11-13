import assert from "node:assert/strict";
import test from "node:test";
import { CapitalComAccountMonitor } from "../dist/modules/broker-adapters/capital-com/capital-com-account-monitor.js";

function provider(overrides = {}) {
  return {
    async ensureSession() {},
    async getAccounts() {
      return {
        observedAt: "2026-11-13T10:00:00.000Z",
        accounts: [{ accountId: "demo-account", balance: { balance: 1_000, available: 900 } }]
      };
    },
    async getPositions() {
      return { observedAt: "2026-11-13T10:00:00.000Z", positions: [] };
    },
    async getWorkingOrders() {
      return { observedAt: "2026-11-13T10:00:00.000Z", workingOrders: [] };
    },
    ...overrides
  };
}

test("account monitor publishes an initial account, positions and working-orders snapshot", async () => {
  const events = [];
  const monitor = new CapitalComAccountMonitor(provider(), (event, payload) => {
    events.push({ event, payload });
  }, { intervalMs: 2_000 });

  monitor.start();
  await new Promise((resolve) => setImmediate(resolve));
  monitor.stop();

  assert.ok(events.some((item) => item.event === "broker.account.sync.status" && item.payload.status === "syncing"));
  assert.ok(events.some((item) => item.event === "broker.account.snapshot" && item.payload.accounts.length === 1));
  assert.ok(events.some((item) => item.event === "broker.positions.snapshot" && item.payload.positions.length === 0));
  assert.ok(events.some((item) => item.event === "broker.workingOrders.snapshot" && item.payload.workingOrders.length === 0));
  assert.ok(events.some((item) => item.event === "broker.account.sync.status" && item.payload.status === "connected"));
  assert.equal(events.at(-1).payload.status, "disconnected");
});

test("account monitor publishes partial source failures and degraded state", async () => {
  const events = [];
  const monitor = new CapitalComAccountMonitor(provider({
    async getPositions() { throw new Error("private transport detail"); }
  }), (event, payload) => {
    events.push({ event, payload });
  }, { intervalMs: 2_000 });

  monitor.start();
  await new Promise((resolve) => setImmediate(resolve));
  monitor.stop();

  assert.ok(events.some((item) =>
    item.event === "broker.account.sync.error" &&
    item.payload.source === "positions" &&
    !String(item.payload.message).includes("private transport detail")
  ));
  assert.ok(events.some((item) => item.event === "broker.account.sync.status" && item.payload.status === "degraded"));
});

test("account monitor renews the session before each snapshot cycle", async () => {
  const events = [];
  let sessionChecks = 0;
  const monitor = new CapitalComAccountMonitor(provider({
    async ensureSession() { sessionChecks += 1; }
  }), (event, payload) => events.push({ event, payload }), { intervalMs: 2_000 });

  monitor.start();
  await new Promise((resolve) => setImmediate(resolve));
  monitor.stop();

  assert.equal(sessionChecks, 1);
});

test("account monitor rejects unsafe polling intervals", () => {
  assert.throws(
    () => new CapitalComAccountMonitor(provider(), () => {}, { intervalMs: 500 }),
    /between 2000 and 30000/
  );
});
