import {
  CapitalComClient,
  type CapitalComCredentials,
  type CapitalComEnvironment,
  type CapitalComHistoricalPrices,
  type CapitalComMarketSearchResult
} from "./capital-com-client.js";

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** Read-only Capital.com session lifecycle owned by the backend process. */
export class CapitalComRuntime {
  private credentials: CapitalComCredentials | undefined;
  private client: CapitalComClient | undefined;
  private connectedAt: string | undefined;

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
      capabilities: ["broker.session", "broker.marketSearch", "broker.historicalPrices"]
    });
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

  disconnect(): void {
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
