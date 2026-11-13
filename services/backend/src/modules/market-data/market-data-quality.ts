export type MarketQuoteQuality = "FRESH" | "DELAYED" | "DEGRADED" | "STALE" | "UNKNOWN";

export interface MarketQuoteInput {
  readonly epic: string;
  readonly bid: number;
  readonly ask: number;
  readonly timestamp: number;
}

export interface NormalizedMarketQuote {
  readonly epic: string;
  readonly source: "capital.com";
  readonly bid: number;
  readonly ask: number;
  readonly mid: number;
  readonly spread: number;
  readonly brokerTimestamp: number;
  readonly receivedAt: number;
  readonly ageMs: number;
  readonly quality: MarketQuoteQuality;
}

export class MarketQuoteValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MarketQuoteValidationError";
  }
}

/**
 * Normalizes a broker quote without substituting or smoothing its prices.
 * Capital.com stream timestamps are epoch milliseconds.
 */
export function normalizeMarketQuote(
  value: MarketQuoteInput,
  receivedAt = Date.now()
): NormalizedMarketQuote {
  if (
    !value ||
    typeof value.epic !== "string" ||
    !value.epic.trim() ||
    !Number.isFinite(value.bid) ||
    !Number.isFinite(value.ask) ||
    !Number.isFinite(value.timestamp) ||
    !Number.isFinite(receivedAt)
  ) {
    throw new MarketQuoteValidationError("The broker quote is incomplete or non-finite.");
  }

  if (value.bid <= 0 || value.ask <= 0 || value.bid >= value.ask) {
    throw new MarketQuoteValidationError("The broker Bid/Ask relationship is invalid.");
  }

  if (value.timestamp <= 0 || receivedAt <= 0) {
    throw new MarketQuoteValidationError("The broker quote timestamp is invalid.");
  }

  const ageMs = receivedAt - value.timestamp;
  const quality: MarketQuoteQuality = ageMs < 0
    ? "UNKNOWN"
    : ageMs <= 5_000
      ? "FRESH"
      : ageMs <= 10_000
        ? "DELAYED"
        : ageMs <= 15_000
          ? "DEGRADED"
          : "STALE";

  return Object.freeze({
    epic: value.epic,
    source: "capital.com",
    bid: value.bid,
    ask: value.ask,
    mid: (value.bid + value.ask) / 2,
    spread: value.ask - value.bid,
    brokerTimestamp: value.timestamp,
    receivedAt,
    ageMs,
    quality
  });
}
