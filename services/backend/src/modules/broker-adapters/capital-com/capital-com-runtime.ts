import {
  CapitalComClient,
  type CapitalComCredentials,
  type CapitalComEnvironment,
  type CapitalComHistoricalPrices,
  type CapitalComMarketSearchResult,
  type CapitalComAccountsSnapshot,
  type CapitalComAccountPreferences,
  type CapitalComPositionsSnapshot,
  type CapitalComWorkingOrdersSnapshot
} from "./capital-com-client.js";
import { normalizeMarketQuote } from "../../market-data/market-data-quality.js";
import {
  createCapitalComMarketDataStream,
  type CapitalComStreamOptions
} from "./capital-com-market-data-stream.js";
import {
  CapitalComAccountMonitor,
  type CapitalComAccountMonitorEmitter
} from "./capital-com-account-monitor.js";

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** Read-only Capital.com session lifecycle owned by the backend process. */
export class CapitalComRuntime {
  private credentials: CapitalComCredentials | undefined;
  private client: CapitalComClient | undefined;
  private connectedAt: string | undefined;
  private marketDataStream: ReturnType<typeof createCapitalComMarketDataStream> | undefined;
  private marketDataEpics: readonly string[] = [];
  private accountMonitor: CapitalComAccountMonitor | undefined;

  setCredentials(value: unknown): void {
    if (!isObject(value)
      || typeof value.apiKey !== "string" || !value.apiKey.trim()
      || typeof value.identifier !== "string" || !value.identifier.trim()
      || typeof value.password !== "string" || !value.password) {
      throw new TypeError("Capital.com credentials are incomplete or malformed.");
    }

    this.disconnect();
    this.credentials = Object.freeze({
      apiKey: value.apiKey,
      identifier: value.identifier,
      apiKeyPassword: value.password
    });
  }

  async connect(environment: CapitalComEnvironment = "demo"): Promise<Record<string, unknown>> {
    if (environment !== "demo") throw new Error("Only the Capital.com Demo environment is enabled.");
    if (!this.credentials) throw new Error("Capital.com credentials have not been submitted.");

    const credentials = this.credentials;
    const provider = { getCredentials: async () => credentials };
    const client = new CapitalComClient(environment, provider);
    await client.createSession();
    await client.ping();

    this.client = client;
    this.connectedAt = new Date().toISOString();

    return Object.freeze({
      connected: true,
      environment,
      authenticatedAt: this.connectedAt,
      capabilities: [
        "broker.session",
        "broker.marketSearch",
        "broker.historicalPrices",
        "broker.marketDataStream",
        "broker.accountSnapshots",
        "broker.positionsSnapshots",
        "broker.workingOrderSnapshots"
      ]
    });
  }

  status(): Record<string, unknown> {
    return Object.freeze({
      connected: this.isConnected,
      environment: this.isConnected ? "demo" : null,
      authenticatedAt: this.connectedAt ?? null,
      streaming: this.marketDataStream !== undefined,
      streamingEpics: this.marketDataEpics
    });
  }

  async startMarketDataStream(
    options: CapitalComStreamOptions,
    emit: (event: string, payload: Record<string, unknown>) => void
  ): Promise<void> {
    if (this.marketDataStream) throw new Error("Capital.com market data stream is already running.");
    const client = this.requireClient();
    const stream = createCapitalComMarketDataStream(client, {
      onQuote: (quote) => {
        try {
          emit("broker.marketData.quote", { ...normalizeMarketQuote(quote) });
        } catch {
          emit("broker.marketData.error", { message: "Capital.com quote failed market-data validation." });
        }
      },
      onOhlc: (bar) => emit("broker.marketData.ohlc", { ...bar }),
      onStatus: (status) => emit("broker.marketData.status", { status }),
      onError: () => emit("broker.marketData.error", { message: "Capital.com market data stream reported an error." })
    });
    this.marketDataStream = stream;
    this.marketDataEpics = [...options.epics];
    try {
      await stream.start(options);
    } catch (error) {
      stream.stop();
      this.marketDataStream = undefined;
      this.marketDataEpics = [];
      throw error;
    }
  }

  stopMarketDataStream(): void {
    this.marketDataStream?.stop();
    this.marketDataStream = undefined;
    this.marketDataEpics = [];
  }

  startAccountMonitor(emit: CapitalComAccountMonitorEmitter): void {
    if (this.accountMonitor) return;
    const client = this.requireClient();
    const provider = {
      ensureSession: async () => { await client.getSessionForStreaming(); },
      getAccounts: () => client.getAccounts(),
      getPositions: () => client.getPositions(),
      getWorkingOrders: () => client.getWorkingOrders()
    };
    const monitor = new CapitalComAccountMonitor(provider, emit, { intervalMs: 3_000 });
    this.accountMonitor = monitor;
    monitor.start();
  }

  stopAccountMonitor(): void {
    this.accountMonitor?.stop();
    this.accountMonitor = undefined;
  }

  async searchMarkets(searchTerm: string): Promise<CapitalComMarketSearchResult> {
    return this.requireClient().searchMarkets(searchTerm);
  }

  async getHistoricalPrices(
    epic: string,
    resolution: string,
    max: number
  ): Promise<CapitalComHistoricalPrices> {
    return this.requireClient().getHistoricalPrices(epic, {
      resolution: resolution as import("./capital-com-client.js").CapitalComResolution,
      max
    });
  }

  async getAccounts(): Promise<CapitalComAccountsSnapshot> { return this.requireClient().getAccounts(); }
  async getAccountPreferences(): Promise<CapitalComAccountPreferences> { return this.requireClient().getAccountPreferences(); }
  async getPositions(): Promise<CapitalComPositionsSnapshot> { return this.requireClient().getPositions(); }
  async getWorkingOrders(): Promise<CapitalComWorkingOrdersSnapshot> { return this.requireClient().getWorkingOrders(); }

  disconnect(): void {
    this.stopAccountMonitor();
    this.stopMarketDataStream();
    this.client?.invalidateSession();
    this.client = undefined;
    this.connectedAt = undefined;
    this.credentials = undefined;
  }

  get isConnected(): boolean {
    return this.client?.isAuthenticated === true;
  }

  private requireClient(): CapitalComClient {
    if (!this.client?.isAuthenticated) throw new Error("Capital.com is not connected.");
    return this.client;
  }
}
