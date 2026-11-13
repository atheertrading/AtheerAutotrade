import type {
  CapitalComAccountsSnapshot,
  CapitalComPositionsSnapshot,
  CapitalComWorkingOrdersSnapshot
} from "./capital-com-client.js";

/**
 * Narrow read-only port consumed by the account monitor.
 * The monitor owns scheduling; CapitalComClient remains the API adapter.
 */
export interface CapitalComAccountDataProvider {
  ensureSession?(): Promise<void>;
  getAccounts(): Promise<CapitalComAccountsSnapshot>;
  getPositions(): Promise<CapitalComPositionsSnapshot>;
  getWorkingOrders(): Promise<CapitalComWorkingOrdersSnapshot>;
}

export type CapitalComAccountMonitorEvent =
  | "broker.account.sync.status"
  | "broker.account.snapshot"
  | "broker.positions.snapshot"
  | "broker.workingOrders.snapshot"
  | "broker.account.sync.error";

export type CapitalComAccountMonitorEmitter = (
  event: CapitalComAccountMonitorEvent,
  payload: Record<string, unknown>
) => void;

export interface CapitalComAccountMonitorOptions {
  readonly intervalMs?: number;
}

const DEFAULT_INTERVAL_MS = 3_000;
const MIN_INTERVAL_MS = 2_000;
const MAX_INTERVAL_MS = 30_000;

/**
 * Continuously reconciles the authoritative Capital.com account, positions,
 * and working-order REST snapshots and publishes them to local application
 * consumers. Capital.com documents WebSocket subscriptions for market quotes
 * and OHLC, not account-balance events; this monitor therefore uses bounded,
 * non-overlapping REST polling.
 */
export class CapitalComAccountMonitor {
  private timer: ReturnType<typeof setInterval> | undefined;
  private stopped = true;
  private refreshInFlight = false;
  private cycle = 0;

  private readonly intervalMs: number;

  constructor(
    private readonly provider: CapitalComAccountDataProvider,
    private readonly emit: CapitalComAccountMonitorEmitter,
    options: CapitalComAccountMonitorOptions = {}
  ) {
    const intervalMs = options.intervalMs ?? DEFAULT_INTERVAL_MS;
    if (!Number.isInteger(intervalMs) || intervalMs < MIN_INTERVAL_MS || intervalMs > MAX_INTERVAL_MS) {
      throw new RangeError(`Account monitor interval must be between ${MIN_INTERVAL_MS} and ${MAX_INTERVAL_MS} ms.`);
    }
    this.intervalMs = intervalMs;
  }

  start(): void {
    if (!this.stopped) return;
    this.stopped = false;
    this.emit("broker.account.sync.status", {
      status: "syncing",
      intervalMs: this.intervalMs,
      observedAt: new Date().toISOString()
    });
    void this.refresh();
    this.timer = setInterval(() => {
      void this.refresh();
    }, this.intervalMs);
  }

  stop(): void {
    if (this.stopped) return;
    this.stopped = true;
    if (this.timer !== undefined) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
    this.emit("broker.account.sync.status", {
      status: "disconnected",
      observedAt: new Date().toISOString()
    });
  }

  private async refresh(): Promise<void> {
    if (this.stopped || this.refreshInFlight) return;
    this.refreshInFlight = true;
    const cycleId = ++this.cycle;
    const observedAt = new Date().toISOString();

    try {
      try {
        await this.provider.ensureSession?.();
      } catch {
        if (!this.stopped) {
          this.emitFailure("accounts");
          this.emitFailure("positions");
          this.emitFailure("workingOrders");
          this.emit("broker.account.sync.status", {
            status: "degraded",
            cycleId,
            failedSources: 3,
            intervalMs: this.intervalMs,
            observedAt: new Date().toISOString()
          });
        }
        return;
      }

      const [accounts, positions, workingOrders] = await Promise.allSettled([
        this.provider.getAccounts(),
        this.provider.getPositions(),
        this.provider.getWorkingOrders()
      ]);

      if (this.stopped) return;

      let failedSources = 0;
      if (accounts.status === "fulfilled") {
        this.emit("broker.account.snapshot", {
          cycleId,
          observedAt: accounts.value.observedAt,
          accounts: accounts.value.accounts
        });
      } else {
        failedSources += 1;
        this.emitFailure("accounts");
      }

      if (positions.status === "fulfilled") {
        this.emit("broker.positions.snapshot", {
          cycleId,
          observedAt: positions.value.observedAt,
          positions: positions.value.positions
        });
      } else {
        failedSources += 1;
        this.emitFailure("positions");
      }

      if (workingOrders.status === "fulfilled") {
        this.emit("broker.workingOrders.snapshot", {
          cycleId,
          observedAt: workingOrders.value.observedAt,
          workingOrders: workingOrders.value.workingOrders
        });
      } else {
        failedSources += 1;
        this.emitFailure("workingOrders");
      }

      this.emit("broker.account.sync.status", {
        status: failedSources === 0 ? "connected" : "degraded",
        cycleId,
        failedSources,
        intervalMs: this.intervalMs,
        observedAt
      });
    } finally {
      this.refreshInFlight = false;
    }
  }

  private emitFailure(source: "accounts" | "positions" | "workingOrders"): void {
    this.emit("broker.account.sync.error", {
      source,
      message: `Capital.com ${source} snapshot could not be refreshed.`,
      observedAt: new Date().toISOString()
    });
  }
}
