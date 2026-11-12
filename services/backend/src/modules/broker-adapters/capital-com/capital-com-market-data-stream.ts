import type { CapitalComSession, CapitalComResolution } from "./capital-com-client.js";

export interface CapitalComQuote {
  readonly epic: string;
  readonly product?: string;
  readonly bid: number;
  readonly ask: number;
  readonly bidQty?: number;
  readonly askQty?: number;
  readonly timestamp: number;
}

export interface CapitalComOhlcUpdate {
  readonly epic: string;
  readonly resolution: CapitalComResolution;
  readonly type: "classic" | "heikin-ashi";
  readonly priceType: "bid" | "ask";
  readonly timestamp: number;
  readonly open: number;
  readonly high: number;
  readonly low: number;
  readonly close: number;
}

export interface CapitalComStreamCallbacks {
  readonly onQuote: (quote: CapitalComQuote) => void;
  readonly onOhlc: (bar: CapitalComOhlcUpdate) => void;
  readonly onStatus?: (status: "connecting" | "transport-connected" | "connected" | "reconnecting" | "stopped") => void;
  readonly onError?: (error: Error) => void;
}

export interface CapitalComStreamOptions {
  readonly epics: readonly string[];
  readonly resolutions: readonly CapitalComResolution[];
  readonly candleType?: "classic" | "heikin-ashi";
}

type SocketFactory = (url: string) => WebSocket;

const MAX_EPICS = 40;
const KEEPALIVE_INTERVAL_MS = 8 * 60 * 1000;
const INITIAL_CONNECT_TIMEOUT_MS = 15_000;
const STABLE_CONNECTION_RESET_MS = 30_000;
const INITIAL_RECONNECT_DELAY_MS = 1_000;
const MAX_RECONNECT_DELAY_MS = 30_000;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function finiteNumber(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new TypeError(`Capital.com stream field ${field} is not a finite number.`);
  }
  return value;
}

function validEpicList(epics: readonly string[]): string[] {
  const normalized = [...new Set(epics.map((epic) => epic.trim()))];
  if (
    normalized.length === 0 ||
    normalized.length > MAX_EPICS ||
    normalized.some((epic) => !epic || epic.length > 128 || /[\s/]/.test(epic))
  ) {
    throw new TypeError("Capital.com stream requires between 1 and 40 valid unique epics.");
  }
  return normalized;
}

function parseQuote(payload: Record<string, unknown>): CapitalComQuote {
  if (typeof payload.epic !== "string" || typeof payload.timestamp !== "number") {
    throw new TypeError("Capital.com quote update is missing its epic or timestamp.");
  }

  return Object.freeze({
    epic: payload.epic,
    bid: finiteNumber(payload.bid, "bid"),
    ask: finiteNumber(payload.ofr, "ofr"),
    timestamp: finiteNumber(payload.timestamp, "timestamp"),
    ...(typeof payload.product === "string" ? { product: payload.product } : {}),
    ...(typeof payload.bidQty === "number" ? { bidQty: payload.bidQty } : {}),
    ...(typeof payload.ofrQty === "number" ? { askQty: payload.ofrQty } : {})
  });
}

function parseOhlc(payload: Record<string, unknown>): CapitalComOhlcUpdate {
  const resolution = payload.resolution;
  const candleType = payload.type;
  const priceType = payload.priceType;

  if (
    typeof payload.epic !== "string" ||
    typeof resolution !== "string" ||
    !new Set<string>(["MINUTE", "MINUTE_5", "MINUTE_15", "MINUTE_30", "HOUR", "HOUR_4", "DAY", "WEEK"]).has(resolution) ||
    (candleType !== "classic" && candleType !== "heikin-ashi") ||
    (priceType !== "bid" && priceType !== "ask")
  ) {
    throw new TypeError("Capital.com OHLC update contains invalid identity or metadata.");
  }

  const open = finiteNumber(payload.o, "o");
  const high = finiteNumber(payload.h, "h");
  const low = finiteNumber(payload.l, "l");
  const close = finiteNumber(payload.c, "c");
  const timestamp = finiteNumber(payload.t, "t");

  if (high < Math.max(open, close, low) || low > Math.min(open, close, high)) {
    throw new TypeError("Capital.com OHLC update violates high/low price bounds.");
  }

  return Object.freeze({
    epic: payload.epic,
    resolution: resolution as CapitalComResolution,
    type: candleType,
    priceType,
    timestamp,
    open,
    high,
    low,
    close
  });
}

/**
 * Maintains Capital.com quote and OHLC subscriptions.
 *
 * It reconnects with bounded exponential backoff and re-subscribes after each
 * connection. This is a transport component, not proof of end-to-end feed
 * stability; the application must still monitor quote age and data gaps.
 */
export class CapitalComMarketDataStream {
  private socket: WebSocket | undefined;
  private stopped = true;
  private keepaliveTimer: ReturnType<typeof setInterval> | undefined;
  private reconnectTimer: ReturnType<typeof setTimeout> | undefined;
  private connectionStableTimer: ReturnType<typeof setTimeout> | undefined;
  private reconnectDelay = INITIAL_RECONNECT_DELAY_MS;
  private options: CapitalComStreamOptions | undefined;
  private readonly confirmedSubscriptions = new Set<string>();

  constructor(
    private readonly getSession: () => Promise<CapitalComSession>,
    private readonly callbacks: CapitalComStreamCallbacks,
    private readonly socketFactory: SocketFactory = (url) => new WebSocket(url),
    private readonly keepRestSessionAlive?: () => Promise<void>
  ) {}

  async start(options: CapitalComStreamOptions): Promise<void> {
    if (!this.stopped) {
      throw new Error("Capital.com market data stream is already running.");
    }

    const epics = validEpicList(options.epics);
    const resolutions = [...new Set(options.resolutions)];
    const supportedResolutions = new Set<string>([
      "MINUTE", "MINUTE_5", "MINUTE_15", "MINUTE_30",
      "HOUR", "HOUR_4", "DAY", "WEEK"
    ]);
    if (
      resolutions.length === 0 ||
      resolutions.some((resolution) => !supportedResolutions.has(resolution))
    ) {
      throw new TypeError("At least one supported Capital.com OHLC resolution is required.");
    }
    if (
      options.candleType !== undefined &&
      options.candleType !== "classic" &&
      options.candleType !== "heikin-ashi"
    ) {
      throw new TypeError("Unsupported Capital.com candle type.");
    }

    this.options = Object.freeze({
      epics: Object.freeze(epics),
      resolutions: Object.freeze(resolutions),
      candleType: options.candleType ?? "classic"
    });
    this.stopped = false;
    await this.openConnection(true);
  }

  stop(): void {
    this.stopped = true;
    this.clearTimers();
    const socket = this.socket;
    this.socket = undefined;
    if (socket && socket.readyState < WebSocket.CLOSING) {
      socket.close(1000, "Client stopped stream");
    }
    this.callbacks.onStatus?.("stopped");
  }

  private async openConnection(waitUntilOpen = false): Promise<void> {
    if (this.stopped || !this.options) return;

    this.callbacks.onStatus?.(this.reconnectDelay === INITIAL_RECONNECT_DELAY_MS
      ? "connecting"
      : "reconnecting");

    try {
      const session = await this.getSession();
      const host = session.streamingHost ?? "wss://api-streaming-capital.backend-capital.com/";
      const url = new URL("connect", host.endsWith("/") ? host : `${host}/`);
      if (
        url.protocol !== "wss:" ||
        url.hostname !== "api-streaming-capital.backend-capital.com"
      ) {
        throw new Error("Capital.com returned an untrusted streaming endpoint.");
      }
      const socket = this.socketFactory(url.toString());
      this.socket = socket;

      socket.addEventListener("open", () => {
        if (this.stopped || this.socket !== socket) return;
        this.clearStableConnectionTimer();
        this.connectionStableTimer = setTimeout(() => {
          this.reconnectDelay = INITIAL_RECONNECT_DELAY_MS;
          this.connectionStableTimer = undefined;
        }, STABLE_CONNECTION_RESET_MS);
        this.confirmedSubscriptions.clear();
        this.sendSubscriptions(socket, session);
        this.startKeepalive(socket, session);
        this.callbacks.onStatus?.("transport-connected");
      });

      socket.addEventListener("message", (event: MessageEvent) => {
        if (this.stopped || this.socket !== socket) return;
        this.handleMessage(event.data);
      });

      socket.addEventListener("error", () => {
        this.callbacks.onError?.(new Error("Capital.com WebSocket transport error."));
      });

      socket.addEventListener("close", () => {
        if (this.socket === socket) this.socket = undefined;
        this.clearStableConnectionTimer();
        this.confirmedSubscriptions.clear();
        this.clearKeepalive();
        if (!this.stopped) this.scheduleReconnect();
      });

      if (waitUntilOpen) {
        await new Promise<void>((resolve, reject) => {
          let settled = false;
          const timeout = setTimeout(() => {
            if (settled) return;
            settled = true;
            socket.close();
            reject(new Error("Capital.com WebSocket connection timed out."));
          }, INITIAL_CONNECT_TIMEOUT_MS);

          const finish = (error?: Error) => {
            if (settled) return;
            settled = true;
            clearTimeout(timeout);
            if (error) reject(error);
            else resolve();
          };

          socket.addEventListener("open", () => finish(), { once: true });
          socket.addEventListener("error", () => {
            finish(new Error("Capital.com WebSocket connection failed."));
          }, { once: true });
          socket.addEventListener("close", () => {
            finish(new Error("Capital.com WebSocket closed before opening."));
          }, { once: true });
        });
      }
    } catch (error) {
      this.callbacks.onError?.(
        error instanceof Error ? error : new Error("Capital.com stream connection failed.")
      );
      this.scheduleReconnect();
      if (waitUntilOpen) throw error;
    }
  }

  private sendSubscriptions(socket: WebSocket, session: CapitalComSession): void {
    const options = this.options;
    if (!options) return;

    const auth = {
      cst: session.cst,
      securityToken: session.securityToken
    };

    socket.send(JSON.stringify({
      destination: "marketData.subscribe",
      correlationId: "atheer-quotes",
      ...auth,
      payload: { epics: options.epics }
    }));

    socket.send(JSON.stringify({
      destination: "OHLCMarketData.subscribe",
      correlationId: "atheer-ohlc",
      ...auth,
      payload: {
        epics: options.epics,
        resolutions: options.resolutions,
        type: options.candleType
      }
    }));
  }

  private startKeepalive(socket: WebSocket, session: CapitalComSession): void {
    this.clearKeepalive();
    this.keepaliveTimer = setInterval(() => {
      if (this.stopped || this.socket !== socket || socket.readyState !== WebSocket.OPEN) return;
      socket.send(JSON.stringify({
        destination: "ping",
        correlationId: `atheer-ping-${Date.now()}`,
        cst: session.cst,
        securityToken: session.securityToken
      }));

      if (this.keepRestSessionAlive) {
        void this.keepRestSessionAlive().catch((error: unknown) => {
          this.callbacks.onError?.(
            error instanceof Error ? error : new Error("Capital.com REST keepalive failed.")
          );
          if (this.socket === socket) socket.close(4001, "REST session keepalive failed");
        });
      }
    }, KEEPALIVE_INTERVAL_MS);
  }

  private handleMessage(data: unknown): void {
    try {
      const text = typeof data === "string" ? data : String(data);
      const parsed: unknown = JSON.parse(text);
      if (!isRecord(parsed) || !isRecord(parsed.payload)) return;

      if (parsed.status === "ERROR") {
        this.callbacks.onError?.(new Error("Capital.com rejected a market data stream request."));
        return;
      }

      if (
        parsed.destination === "marketData.subscribe" ||
        parsed.destination === "OHLCMarketData.subscribe"
      ) {
        const subscriptions = parsed.payload.subscriptions;
        if (
          parsed.status !== "OK" ||
          !isRecord(subscriptions) ||
          Object.keys(subscriptions).length === 0 ||
          Object.values(subscriptions).some((status) => status !== "PROCESSED")
        ) {
          this.callbacks.onError?.(new Error("Capital.com did not confirm all market data subscriptions."));
          return;
        }

        this.confirmedSubscriptions.add(parsed.destination);
        if (
          this.confirmedSubscriptions.has("marketData.subscribe") &&
          this.confirmedSubscriptions.has("OHLCMarketData.subscribe")
        ) {
          this.callbacks.onStatus?.("connected");
        }
        return;
      }

      if (parsed.destination === "quote") {
        this.callbacks.onQuote(parseQuote(parsed.payload));
      } else if (parsed.destination === "ohlc.event") {
        this.callbacks.onOhlc(parseOhlc(parsed.payload));
      }
    } catch (error) {
      this.callbacks.onError?.(
        error instanceof Error ? error : new Error("Invalid Capital.com stream message.")
      );
    }
  }

  private scheduleReconnect(): void {
    if (this.stopped || this.reconnectTimer) return;
    this.callbacks.onStatus?.("reconnecting");
    const delay = this.reconnectDelay;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = undefined;
      void this.openConnection();
    }, delay);
    this.reconnectDelay = Math.min(this.reconnectDelay * 2, MAX_RECONNECT_DELAY_MS);
  }

  private clearKeepalive(): void {
    if (this.keepaliveTimer !== undefined) {
      clearInterval(this.keepaliveTimer);
      this.keepaliveTimer = undefined;
    }
  }

  private clearStableConnectionTimer(): void {
    if (this.connectionStableTimer !== undefined) {
      clearTimeout(this.connectionStableTimer);
      this.connectionStableTimer = undefined;
    }
  }

  private clearTimers(): void {
    this.clearKeepalive();
    this.clearStableConnectionTimer();
    if (this.reconnectTimer !== undefined) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = undefined;
    }
  }
}

/**
 * Wires stream reconnection to the REST client's session renewal and keeps
 * both REST and WebSocket session activity alive while streaming.
 */
export function createCapitalComMarketDataStream(
  client: import("./capital-com-client.js").CapitalComClient,
  callbacks: CapitalComStreamCallbacks,
  socketFactory?: SocketFactory
): CapitalComMarketDataStream {
  return new CapitalComMarketDataStream(
    () => client.getSessionForStreaming(),
    callbacks,
    socketFactory,
    () => client.ping()
  );
}
