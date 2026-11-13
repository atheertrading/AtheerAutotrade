export type TradeSide = "BUY" | "SELL";

export interface RiskOrderIntent {
  readonly intentId: string;
  readonly idempotencyKey: string;
  readonly epic: string;
  readonly side: TradeSide;
  readonly quantity: number;
  readonly contractMultiplier: number;
  readonly stopLossPrice: number;
  readonly estimatedInitialMargin: number;
  readonly requestedAt: number;
}

export interface RiskQuote {
  readonly epic: string;
  readonly bid: number;
  readonly ask: number;
  readonly brokerTimestamp: number;
  readonly receivedAt: number;
}

export interface RiskAccountSnapshot {
  readonly currency: string;
  readonly equity: number;
  readonly freeMargin: number;
  readonly grossExposure: number;
  readonly openPositions: number;
}

export interface RiskPolicy {
  readonly maxRiskPerTradePercent: number;
  readonly maxGrossExposurePercent: number;
  readonly maxOpenPositions: number;
  readonly minFreeMarginPercent: number;
  readonly maxQuoteAgeMs: number;
}

export type RiskRejectionCode =
  | "INVALID_INTENT"
  | "INVALID_ACCOUNT_SNAPSHOT"
  | "INVALID_QUOTE"
  | "QUOTE_EPIC_MISMATCH"
  | "QUOTE_NOT_FRESH"
  | "STOP_LOSS_INVALID"
  | "RISK_LIMIT_EXCEEDED"
  | "GROSS_EXPOSURE_LIMIT_EXCEEDED"
  | "POSITION_LIMIT_EXCEEDED"
  | "INSUFFICIENT_FREE_MARGIN"
  | "INVALID_POLICY";

export interface RiskDecision {
  readonly approved: boolean;
  readonly intentId: string;
  readonly evaluatedAt: number;
  readonly referencePrice?: number;
  readonly estimatedLoss?: number;
  readonly estimatedGrossExposure?: number;
  readonly reasons: readonly RiskRejectionCode[];
}

/**
 * Pure pre-trade risk boundary for exposure-increasing market intents.
 * All monetary inputs must already be expressed in the account currency.
 * The caller must provide broker-derived account and quote observations;
 * missing observations are rejected rather than defaulted.
 */
export class RiskEngine {
  evaluate(
    intent: RiskOrderIntent,
    account: RiskAccountSnapshot,
    quote: RiskQuote,
    policy: RiskPolicy,
    evaluatedAt = Date.now()
  ): RiskDecision {
    const reasons: RiskRejectionCode[] = [];

    if (!intent || !isText(intent.intentId) || !isText(intent.idempotencyKey)
      || !isText(intent.epic) || (intent.side !== "BUY" && intent.side !== "SELL")
      || !isPositive(intent.quantity) || !isPositive(intent.contractMultiplier)
      || !isPositive(intent.stopLossPrice) || !isNonNegative(intent.estimatedInitialMargin)
      || !isPositive(intent.requestedAt)) {
      reasons.push("INVALID_INTENT");
    }

    if (!account || !isText(account.currency) || !isPositive(account.equity)
      || !isNonNegative(account.freeMargin) || !isNonNegative(account.grossExposure)
      || !Number.isInteger(account.openPositions) || account.openPositions < 0) {
      reasons.push("INVALID_ACCOUNT_SNAPSHOT");
    }

    if (!quote || !isText(quote.epic) || !isPositive(quote.bid) || !isPositive(quote.ask)
      || quote.bid >= quote.ask || !isPositive(quote.brokerTimestamp)
      || !isPositive(quote.receivedAt) || !isPositive(evaluatedAt)) {
      reasons.push("INVALID_QUOTE");
    }

    if (!policy || !isPositive(policy.maxRiskPerTradePercent)
      || policy.maxRiskPerTradePercent > 100
      || !isPositive(policy.maxGrossExposurePercent)
      || !Number.isInteger(policy.maxOpenPositions) || policy.maxOpenPositions < 1
      || !isNonNegative(policy.minFreeMarginPercent) || policy.minFreeMarginPercent > 100
      || !isPositive(policy.maxQuoteAgeMs)) {
      reasons.push("INVALID_POLICY");
    }

    if (reasons.length > 0) return decision(intent?.intentId ?? "", evaluatedAt, reasons);

    if (intent.epic !== quote.epic) reasons.push("QUOTE_EPIC_MISMATCH");

    const quoteAge = quote.receivedAt - quote.brokerTimestamp;
    if (quoteAge < 0 || quoteAge > policy.maxQuoteAgeMs
      || evaluatedAt < quote.receivedAt
      || evaluatedAt - quote.receivedAt > policy.maxQuoteAgeMs) {
      reasons.push("QUOTE_NOT_FRESH");
    }

    const referencePrice = intent.side === "BUY" ? quote.ask : quote.bid;
    const stopIsValid = intent.side === "BUY"
      ? intent.stopLossPrice < referencePrice
      : intent.stopLossPrice > referencePrice;
    if (!stopIsValid) reasons.push("STOP_LOSS_INVALID");

    const estimatedLoss = Math.abs(referencePrice - intent.stopLossPrice)
      * intent.quantity * intent.contractMultiplier;
    const estimatedGrossExposure = referencePrice * intent.quantity * intent.contractMultiplier;

    if (estimatedLoss > account.equity * policy.maxRiskPerTradePercent / 100) {
      reasons.push("RISK_LIMIT_EXCEEDED");
    }
    if (account.grossExposure + estimatedGrossExposure
      > account.equity * policy.maxGrossExposurePercent / 100) {
      reasons.push("GROSS_EXPOSURE_LIMIT_EXCEEDED");
    }
    if (account.openPositions + 1 > policy.maxOpenPositions) {
      reasons.push("POSITION_LIMIT_EXCEEDED");
    }
    const requiredFreeMargin = account.equity * policy.minFreeMarginPercent / 100;
    if (account.freeMargin - intent.estimatedInitialMargin < requiredFreeMargin) {
      reasons.push("INSUFFICIENT_FREE_MARGIN");
    }

    return Object.freeze({
      approved: reasons.length === 0,
      intentId: intent.intentId,
      evaluatedAt,
      referencePrice,
      estimatedLoss,
      estimatedGrossExposure,
      reasons: Object.freeze(reasons)
    });
  }
}

function decision(
  intentId: string,
  evaluatedAt: number,
  reasons: RiskRejectionCode[]
): RiskDecision {
  return Object.freeze({
    approved: false,
    intentId,
    evaluatedAt,
    reasons: Object.freeze(reasons)
  });
}

function isText(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function isPositive(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value > 0;
}

function isNonNegative(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
}
