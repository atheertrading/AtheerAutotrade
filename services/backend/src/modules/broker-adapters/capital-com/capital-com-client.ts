export type CapitalComEnvironment = "demo" | "live";

export type CapitalComResolution =
  | "MINUTE"
  | "MINUTE_5"
  | "MINUTE_15"
  | "MINUTE_30"
  | "HOUR"
  | "HOUR_4"
  | "DAY"
  | "WEEK";

export interface CapitalComCredentials {
  readonly identifier: string;
  readonly apiKey: string;
  readonly apiKeyPassword: string;
}

/**
 * The adapter never reads credentials from process.env or source-controlled
 * configuration. A platform-specific secret provider must supply them.
 */
export interface CapitalComCredentialsProvider {
  getCredentials(): Promise<CapitalComCredentials>;
}

export interface CapitalComSession {
  readonly cst: string;
  readonly securityToken: string;
  readonly streamingHost?: string;
  readonly createdAt: number;
}

export interface CapitalComPriceSnapshot {
  readonly snapshotTime: string;
  readonly snapshotTimeUTC: string;
  readonly openPrice: { readonly bid: number; readonly ask: number };
  readonly closePrice: { readonly bid: number; readonly ask: number };
  readonly highPrice: { readonly bid: number; readonly ask: number };
  readonly lowPrice: { readonly bid: number; readonly ask: number };
  readonly lastTradedVolume?: number;
}

export interface CapitalComHistoricalPrices {
  readonly prices: readonly CapitalComPriceSnapshot[];
  readonly instrumentType?: string;
}

export interface CapitalComMarketSearchResult {
  readonly markets: readonly unknown[];
}

export interface CapitalComAccount {
  readonly accountId: string; readonly accountName: string; readonly status: string;
  readonly accountType: string; readonly preferred: boolean; readonly currency: string;
  readonly symbol: string;
  readonly balance: { readonly balance: number; readonly deposit: number; readonly profitLoss: number; readonly available: number };
}
export interface CapitalComAccountsSnapshot { readonly observedAt: string; readonly accounts: readonly CapitalComAccount[]; }
export interface CapitalComPosition {
  readonly position: {
    readonly dealId: string; readonly dealReference?: string; readonly size: number;
    readonly direction: "BUY" | "SELL"; readonly level: number; readonly currency: string;
    readonly leverage?: number; readonly upl?: number; readonly createdDateUTC?: string; readonly guaranteedStop?: boolean;
  };
  readonly market: {
    readonly epic: string; readonly instrumentName: string; readonly instrumentType?: string;
    readonly marketStatus?: string; readonly bid?: number; readonly offer?: number;
    readonly lotSize?: number; readonly updateTimeUTC?: string;
  };
}
export interface CapitalComPositionsSnapshot { readonly observedAt: string; readonly positions: readonly CapitalComPosition[]; }
export interface CapitalComWorkingOrder {
  readonly workingOrderData: {
    readonly dealId: string; readonly direction: "BUY" | "SELL"; readonly epic: string;
    readonly orderSize: number; readonly orderLevel: number; readonly orderType: string;
    readonly timeInForce: string; readonly currencyCode: string; readonly leverage?: number;
    readonly createdDateUTC?: string; readonly goodTillDateUTC?: string; readonly guaranteedStop?: boolean;
  };
  readonly marketData: {
    readonly epic: string; readonly instrumentName: string; readonly instrumentType?: string;
    readonly marketStatus?: string; readonly bid?: number; readonly offer?: number;
    readonly lotSize?: number; readonly updateTimeUTC?: string;
  };
}
export interface CapitalComWorkingOrdersSnapshot { readonly observedAt: string; readonly workingOrders: readonly CapitalComWorkingOrder[]; }
export interface CapitalComAccountPreferences {
  readonly observedAt: string; readonly hedgingMode: boolean;
  readonly leverages: Readonly<Record<string, { readonly current: number; readonly available: readonly number[] }>>;
}

export class CapitalComApiError extends Error {
  constructor(
    readonly status: number,
    readonly operation: string
  ) {
    super(`Capital.com request failed during ${operation} (HTTP ${status}).`);
    this.name = "CapitalComApiError";
  }
}

export class CapitalComProtocolError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CapitalComProtocolError";
  }
}

const REQUEST_TIMEOUT_MS = 15_000;

const BASE_URLS: Readonly<Record<CapitalComEnvironment, string>> = Object.freeze({
  demo: "https://demo-api-capital.backend-capital.com",
  live: "https://api-capital.backend-capital.com"
});

const RESOLUTIONS = new Set<CapitalComResolution>([
  "MINUTE", "MINUTE_5", "MINUTE_15", "MINUTE_30",
  "HOUR", "HOUR_4", "DAY", "WEEK"
]);

type FetchFunction = typeof fetch;

interface SessionResponse {
  readonly streamingHost?: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function requiredHeader(headers: Headers, name: string): string {
  const value = headers.get(name);
  if (!value) {
    throw new CapitalComProtocolError(`Capital.com session response omitted ${name}.`);
  }
  return value;
}

function validateEpic(epic: string): string {
  const normalized = epic.trim();
  if (!normalized || normalized.length > 128 || /[\s/]/.test(normalized)) {
    throw new TypeError("epic must be a non-empty Capital.com market epic.");
  }
  return normalized;
}


function parsePriceLevel(value: unknown, field: string): { readonly bid: number; readonly ask: number } {
  if (!isRecord(value)) {
    throw new CapitalComProtocolError(`Capital.com historical price omitted ${field}.`);
  }
  const bid = value.bid;
  const ask = value.ask;
  if (
    typeof bid !== "number" || !Number.isFinite(bid) ||
    typeof ask !== "number" || !Number.isFinite(ask)
  ) {
    throw new CapitalComProtocolError(`Capital.com historical ${field} values are invalid.`);
  }
  return Object.freeze({ bid, ask });
}

function parseHistoricalSnapshot(value: unknown): CapitalComPriceSnapshot {
  if (!isRecord(value)) {
    throw new CapitalComProtocolError("Capital.com returned a malformed historical candle.");
  }
  if (
    typeof value.snapshotTime !== "string" ||
    typeof value.snapshotTimeUTC !== "string" ||
    !Number.isFinite(Date.parse(`${value.snapshotTimeUTC}Z`))
  ) {
    throw new CapitalComProtocolError("Capital.com historical candle timestamp is invalid.");
  }

  const openPrice = parsePriceLevel(value.openPrice, "openPrice");
  const closePrice = parsePriceLevel(value.closePrice, "closePrice");
  const highPrice = parsePriceLevel(value.highPrice, "highPrice");
  const lowPrice = parsePriceLevel(value.lowPrice, "lowPrice");

  for (const side of ["bid", "ask"] as const) {
    if (
      highPrice[side] < Math.max(openPrice[side], closePrice[side], lowPrice[side]) ||
      lowPrice[side] > Math.min(openPrice[side], closePrice[side], highPrice[side])
    ) {
      throw new CapitalComProtocolError(`Capital.com historical candle has invalid ${side} OHLC bounds.`);
    }
  }

  const lastTradedVolume = value.lastTradedVolume;
  if (
    lastTradedVolume !== undefined &&
    (typeof lastTradedVolume !== "number" || !Number.isFinite(lastTradedVolume) || lastTradedVolume < 0)
  ) {
    throw new CapitalComProtocolError("Capital.com historical candle volume is invalid.");
  }

  return Object.freeze({
    snapshotTime: value.snapshotTime,
    snapshotTimeUTC: value.snapshotTimeUTC,
    openPrice,
    closePrice,
    highPrice,
    lowPrice,
    ...(typeof lastTradedVolume === "number" ? { lastTradedVolume } : {})
  });
}

function requiredRecord(value: unknown, field: string): Record<string, unknown> {
  if (!isRecord(value)) throw new CapitalComProtocolError(`Capital.com response omitted ${field}.`);
  return value;
}
function requiredString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new CapitalComProtocolError(`Capital.com response contains an invalid ${field}.`);
  return value;
}
function requiredFiniteNumber(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) throw new CapitalComProtocolError(`Capital.com response contains an invalid ${field}.`);
  return value;
}
function optionalFiniteNumber(value: unknown, field: string): number | undefined {
  return value === undefined ? undefined : requiredFiniteNumber(value, field);
}
function optionalString(value: unknown, field: string): string | undefined {
  return value === undefined ? undefined : requiredString(value, field);
}
function optionalBoolean(value: unknown, field: string): boolean | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "boolean") throw new CapitalComProtocolError(`Capital.com response contains an invalid ${field}.`);
  return value;
}
function parseDirection(value: unknown, field: string): "BUY" | "SELL" {
  if (value !== "BUY" && value !== "SELL") throw new CapitalComProtocolError(`Capital.com response contains an invalid ${field}.`);
  return value;
}
function parseAccount(value: unknown): CapitalComAccount {
  const account = requiredRecord(value, "account"), balance = requiredRecord(account.balance, "account.balance");
  if (typeof account.preferred !== "boolean") throw new CapitalComProtocolError("Capital.com response contains an invalid account.preferred.");
  return Object.freeze({
    accountId: requiredString(account.accountId, "account.accountId"),
    accountName: requiredString(account.accountName, "account.accountName"),
    status: requiredString(account.status, "account.status"),
    accountType: requiredString(account.accountType, "account.accountType"),
    preferred: account.preferred,
    currency: requiredString(account.currency, "account.currency"),
    symbol: requiredString(account.symbol, "account.symbol"),
    balance: Object.freeze({
      balance: requiredFiniteNumber(balance.balance, "account.balance.balance"),
      deposit: requiredFiniteNumber(balance.deposit, "account.balance.deposit"),
      profitLoss: requiredFiniteNumber(balance.profitLoss, "account.balance.profitLoss"),
      available: requiredFiniteNumber(balance.available, "account.balance.available")
    })
  });
}
function parsePosition(value: unknown): CapitalComPosition {
  const item = requiredRecord(value, "position item"), p = requiredRecord(item.position, "position"), m = requiredRecord(item.market, "market");
  const leverage=optionalFiniteNumber(p.leverage,"position.leverage"), upl=optionalFiniteNumber(p.upl,"position.upl");
  const created=optionalString(p.createdDateUTC,"position.createdDateUTC"), guaranteed=optionalBoolean(p.guaranteedStop,"position.guaranteedStop");
  const instrumentType=optionalString(m.instrumentType,"market.instrumentType"), marketStatus=optionalString(m.marketStatus,"market.marketStatus");
  const bid=optionalFiniteNumber(m.bid,"market.bid"), offer=optionalFiniteNumber(m.offer,"market.offer");
  const lotSize=optionalFiniteNumber(m.lotSize,"market.lotSize"), update=optionalString(m.updateTimeUTC,"market.updateTimeUTC");
  return Object.freeze({
    position:Object.freeze({
      dealId:requiredString(p.dealId,"position.dealId"),
      ...(p.dealReference===undefined?{}:{dealReference:requiredString(p.dealReference,"position.dealReference")}),
      size:requiredFiniteNumber(p.size,"position.size"), direction:parseDirection(p.direction,"position.direction"),
      level:requiredFiniteNumber(p.level,"position.level"), currency:requiredString(p.currency,"position.currency"),
      ...(leverage===undefined?{}:{leverage}), ...(upl===undefined?{}:{upl}),
      ...(created===undefined?{}:{createdDateUTC:created}), ...(guaranteed===undefined?{}:{guaranteedStop:guaranteed})
    }),
    market:Object.freeze({
      epic:requiredString(m.epic,"market.epic"), instrumentName:requiredString(m.instrumentName,"market.instrumentName"),
      ...(instrumentType===undefined?{}:{instrumentType}), ...(marketStatus===undefined?{}:{marketStatus}),
      ...(bid===undefined?{}:{bid}), ...(offer===undefined?{}:{offer}),
      ...(lotSize===undefined?{}:{lotSize}), ...(update===undefined?{}:{updateTimeUTC:update})
    })
  });
}
function parseWorkingOrder(value: unknown): CapitalComWorkingOrder {
  const item=requiredRecord(value,"working order item"), o=requiredRecord(item.workingOrderData,"workingOrderData"), m=requiredRecord(item.marketData,"marketData");
  const leverage=optionalFiniteNumber(o.leverage,"workingOrderData.leverage");
  const created=optionalString(o.createdDateUTC,"workingOrderData.createdDateUTC");
  const goodTill=optionalString(o.goodTillDateUTC,"workingOrderData.goodTillDateUTC");
  const guaranteed=optionalBoolean(o.guaranteedStop,"workingOrderData.guaranteedStop");
  const instrumentType=optionalString(m.instrumentType,"marketData.instrumentType"), marketStatus=optionalString(m.marketStatus,"marketData.marketStatus");
  const bid=optionalFiniteNumber(m.bid,"marketData.bid"), offer=optionalFiniteNumber(m.offer,"marketData.offer");
  const lotSize=optionalFiniteNumber(m.lotSize,"marketData.lotSize"), update=optionalString(m.updateTimeUTC,"marketData.updateTimeUTC");
  return Object.freeze({
    workingOrderData:Object.freeze({
      dealId:requiredString(o.dealId,"workingOrderData.dealId"), direction:parseDirection(o.direction,"workingOrderData.direction"),
      epic:requiredString(o.epic,"workingOrderData.epic"), orderSize:requiredFiniteNumber(o.orderSize,"workingOrderData.orderSize"),
      orderLevel:requiredFiniteNumber(o.orderLevel,"workingOrderData.orderLevel"), orderType:requiredString(o.orderType,"workingOrderData.orderType"),
      timeInForce:requiredString(o.timeInForce,"workingOrderData.timeInForce"), currencyCode:requiredString(o.currencyCode,"workingOrderData.currencyCode"),
      ...(leverage===undefined?{}:{leverage}), ...(created===undefined?{}:{createdDateUTC:created}),
      ...(goodTill===undefined?{}:{goodTillDateUTC:goodTill}), ...(guaranteed===undefined?{}:{guaranteedStop:guaranteed})
    }),
    marketData:Object.freeze({
      epic:requiredString(m.epic,"marketData.epic"), instrumentName:requiredString(m.instrumentName,"marketData.instrumentName"),
      ...(instrumentType===undefined?{}:{instrumentType}), ...(marketStatus===undefined?{}:{marketStatus}),
      ...(bid===undefined?{}:{bid}), ...(offer===undefined?{}:{offer}),
      ...(lotSize===undefined?{}:{lotSize}), ...(update===undefined?{}:{updateTimeUTC:update})
    })
  });
}

/**
 * Read-only Capital.com REST adapter. Account, position, and working-order
 * retrieval is permitted; no dealing or account/position mutation is exposed.
 * Session tokens remain in memory and are never logged.
 */
export class CapitalComClient {
  private session: CapitalComSession | undefined;

  constructor(
    private readonly environment: CapitalComEnvironment,
    private readonly credentialsProvider: CapitalComCredentialsProvider,
    private readonly fetcher: FetchFunction = fetch
  ) {}

  get baseUrl(): string {
    return BASE_URLS[this.environment];
  }

  get isAuthenticated(): boolean {
    return this.session !== undefined;
  }

  async getSessionForStreaming(): Promise<CapitalComSession> {
    if (!this.session) return this.createSession();

    try {
      await this.ping();
      return this.session ?? this.createSession();
    } catch (error) {
      if (error instanceof CapitalComApiError && (error.status === 401 || error.status === 403)) {
        return this.createSession();
      }
      throw error;
    }
  }

  async createSession(): Promise<CapitalComSession> {
    const credentials = await this.credentialsProvider.getCredentials();
    this.assertCredentials(credentials);

    const response = await this.fetcher(`${this.baseUrl}/api/v1/session`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "X-CAP-API-KEY": credentials.apiKey
      },
      body: JSON.stringify({
        identifier: credentials.identifier,
        password: credentials.apiKeyPassword,
        encryptedPassword: false
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
    });

    if (!response.ok) {
      throw new CapitalComApiError(response.status, "create-session");
    }

    let payload: SessionResponse = {};
    try {
      const parsed: unknown = await response.json();
      if (isRecord(parsed)) {
        const streamingHost =
          typeof parsed.streamingHost === "string"
            ? parsed.streamingHost
            : typeof parsed.streamEndpoint === "string"
              ? parsed.streamEndpoint
              : undefined;
        if (streamingHost) payload = { streamingHost };
      }
    } catch {
      // Session tokens are returned in response headers; an empty body is valid.
    }

    const session: CapitalComSession = Object.freeze({
      cst: requiredHeader(response.headers, "CST"),
      securityToken: requiredHeader(response.headers, "X-SECURITY-TOKEN"),
      ...(payload.streamingHost ? { streamingHost: payload.streamingHost } : {}),
      createdAt: Date.now()
    });

    this.session = session;
    return session;
  }

  async ping(): Promise<void> {
    await this.authenticatedRequest("/api/v1/ping", "GET", "session-ping");
  }

  async searchMarkets(searchTerm: string): Promise<CapitalComMarketSearchResult> {
    const normalized = searchTerm.trim();
    if (!normalized || normalized.length > 100) {
      throw new TypeError("searchTerm must contain between 1 and 100 characters.");
    }

    const query = new URLSearchParams({ searchTerm: normalized });
    const result = await this.authenticatedJson<unknown>(
      `/api/v1/markets?${query.toString()}`,
      "market-search"
    );

    if (!isRecord(result) || !Array.isArray(result.markets)) {
      throw new CapitalComProtocolError("Capital.com market search returned an unexpected payload.");
    }

    return Object.freeze({ markets: result.markets });
  }

  async getHistoricalPrices(
    epic: string,
    options: {
      readonly resolution?: CapitalComResolution;
      readonly max?: number;
      readonly from?: string;
      readonly to?: string;
    } = {}
  ): Promise<CapitalComHistoricalPrices> {
    const marketEpic = validateEpic(epic);
    const resolution = options.resolution ?? "MINUTE";
    const max = options.max ?? 100;

    if (!RESOLUTIONS.has(resolution)) {
      throw new TypeError("Unsupported Capital.com price resolution.");
    }
    if (!Number.isInteger(max) || max < 1 || max > 1000) {
      throw new TypeError("max must be an integer between 1 and 1000.");
    }
    if (options.from && !this.isApiDateTime(options.from)) {
      throw new TypeError("from must use YYYY-MM-DDTHH:mm:ss.");
    }
    if (options.to && !this.isApiDateTime(options.to)) {
      throw new TypeError("to must use YYYY-MM-DDTHH:mm:ss.");
    }
    if (options.from && options.to && options.from > options.to) {
      throw new TypeError("from must not be later than to.");
    }

    const query = new URLSearchParams({
      resolution,
      max: String(max)
    });
    if (options.from) query.set("from", options.from);
    if (options.to) query.set("to", options.to);

    const result = await this.authenticatedJson<unknown>(
      `/api/v1/prices/${encodeURIComponent(marketEpic)}?${query.toString()}`,
      "historical-prices"
    );

    if (!isRecord(result) || !Array.isArray(result.prices)) {
      throw new CapitalComProtocolError("Capital.com historical prices returned an unexpected payload.");
    }

    return Object.freeze({
      prices: Object.freeze(result.prices.map(parseHistoricalSnapshot)),
      ...(typeof result.instrumentType === "string"
        ? { instrumentType: result.instrumentType }
        : {})
    });
  }

  async getAccounts(): Promise<CapitalComAccountsSnapshot> {
    const result=await this.authenticatedJson<unknown>("/api/v1/accounts","accounts");
    if (!isRecord(result)||!Array.isArray(result.accounts)) throw new CapitalComProtocolError("Capital.com accounts returned an unexpected payload.");
    return Object.freeze({observedAt:new Date().toISOString(),accounts:Object.freeze(result.accounts.map(parseAccount))});
  }

  async getAccountPreferences(): Promise<CapitalComAccountPreferences> {
    const result=await this.authenticatedJson<unknown>("/api/v1/accounts/preferences","account-preferences");
    if (!isRecord(result)||typeof result.hedgingMode!=="boolean"||!isRecord(result.leverages)) throw new CapitalComProtocolError("Capital.com account preferences returned an unexpected payload.");
    const leverages:Record<string,{readonly current:number;readonly available:readonly number[]}>={};
    for(const [assetClass,value] of Object.entries(result.leverages)){
      const item=requiredRecord(value,`leverages.${assetClass}`);
      if(!Array.isArray(item.available)) throw new CapitalComProtocolError(`Capital.com response contains invalid leverages.${assetClass}.available.`);
      leverages[assetClass]=Object.freeze({
        current:requiredFiniteNumber(item.current,`leverages.${assetClass}.current`),
        available:Object.freeze(item.available.map((v,i)=>requiredFiniteNumber(v,`leverages.${assetClass}.available[${i}]`)))
      });
    }
    return Object.freeze({observedAt:new Date().toISOString(),hedgingMode:result.hedgingMode,leverages:Object.freeze(leverages)});
  }

  async getPositions(): Promise<CapitalComPositionsSnapshot> {
    const result=await this.authenticatedJson<unknown>("/api/v1/positions","positions");
    if(!isRecord(result)||!Array.isArray(result.positions)) throw new CapitalComProtocolError("Capital.com positions returned an unexpected payload.");
    return Object.freeze({observedAt:new Date().toISOString(),positions:Object.freeze(result.positions.map(parsePosition))});
  }

  async getWorkingOrders(): Promise<CapitalComWorkingOrdersSnapshot> {
    const result=await this.authenticatedJson<unknown>("/api/v1/workingorders","working-orders");
    if(!isRecord(result)||!Array.isArray(result.workingOrders)) throw new CapitalComProtocolError("Capital.com working orders returned an unexpected payload.");
    return Object.freeze({observedAt:new Date().toISOString(),workingOrders:Object.freeze(result.workingOrders.map(parseWorkingOrder))});
  }

  invalidateSession(): void {
    this.session = undefined;
  }

  private async authenticatedJson<T>(path: string, operation: string): Promise<T> {
    const response = await this.authenticatedRequest(path, "GET", operation);
    try {
      return await response.json() as T;
    } catch {
      throw new CapitalComProtocolError(`Capital.com returned invalid JSON during ${operation}.`);
    }
  }

  private async authenticatedRequest(
    path: string,
    method: "GET",
    operation: string
  ): Promise<Response> {
    const session = this.session;
    if (!session) {
      throw new Error("Capital.com session is not established.");
    }

    const response = await this.fetcher(`${this.baseUrl}${path}`, {
      method,
      headers: {
        CST: session.cst,
        "X-SECURITY-TOKEN": session.securityToken
      },
      cache: "no-store",
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
    });

    if (response.status === 401 || response.status === 403) {
      this.invalidateSession();
    }
    if (!response.ok) {
      throw new CapitalComApiError(response.status, operation);
    }
    return response;
  }

  private assertCredentials(value: CapitalComCredentials): void {
    if (
      !value ||
      typeof value.identifier !== "string" || !value.identifier.trim() ||
      typeof value.apiKey !== "string" || !value.apiKey.trim() ||
      typeof value.apiKeyPassword !== "string" || !value.apiKeyPassword
    ) {
      throw new TypeError("Capital.com credentials provider returned incomplete credentials.");
    }
  }

  private isApiDateTime(value: string): boolean {
    return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(value) &&
      Number.isFinite(Date.parse(`${value}Z`));
  }
}
