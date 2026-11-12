export const ASSET_CLASSES = [
  "forex",
  "equity",
  "index",
  "commodity",
  "cryptocurrency",
  "bond",
  "other"
] as const;

export type AssetClass = (typeof ASSET_CLASSES)[number];

export const INSTRUMENT_STATUSES = [
  "active",
  "suspended",
  "delisted",
  "unknown"
] as const;

export type InstrumentStatus = (typeof INSTRUMENT_STATUSES)[number];

/**
 * Exact decimal text is used for contract increments and minimum quantities.
 * This avoids binary floating-point rounding in instrument specifications.
 */
export type PositiveDecimal = string & { readonly __brand: "PositiveDecimal" };

export interface InstrumentInput {
  readonly id: string;
  readonly symbol: string;
  readonly name: string;
  readonly assetClass: AssetClass;
  readonly status: InstrumentStatus;
  readonly baseCurrency?: string;
  readonly quoteCurrency?: string;
  readonly priceIncrement?: string;
  readonly quantityIncrement?: string;
  readonly minimumQuantity?: string;
}

export interface Instrument {
  readonly id: string;
  readonly symbol: string;
  readonly name: string;
  readonly assetClass: AssetClass;
  readonly status: InstrumentStatus;
  readonly baseCurrency?: string;
  readonly quoteCurrency?: string;
  readonly priceIncrement?: PositiveDecimal;
  readonly quantityIncrement?: PositiveDecimal;
  readonly minimumQuantity?: PositiveDecimal;
}

export class InstrumentValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InstrumentValidationError";
  }
}

const assetClassSet: ReadonlySet<string> = new Set(ASSET_CLASSES);
const statusSet: ReadonlySet<string> = new Set(INSTRUMENT_STATUSES);
const positiveDecimalPattern = /^(?:0|[1-9]\d*)(?:\.\d+)?$/;
const currencyCodePattern = /^[A-Z]{3}$/;

function requiredText(value: string, field: string, maxLength: number): string {
  if (typeof value !== "string") {
    throw new InstrumentValidationError(`${field} must be a string.`);
  }

  const normalized = value.trim();
  if (normalized.length === 0 || normalized.length > maxLength) {
    throw new InstrumentValidationError(
      `${field} must contain between 1 and ${maxLength} characters.`
    );
  }

  return normalized;
}

function optionalCurrency(value: string | undefined, field: string): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "string" || !currencyCodePattern.test(value)) {
    throw new InstrumentValidationError(`${field} must be a three-letter uppercase currency code.`);
  }
  return value;
}

function optionalPositiveDecimal(
  value: string | undefined,
  field: string
): PositiveDecimal | undefined {
  if (value === undefined) return undefined;
  if (
    typeof value !== "string" ||
    !positiveDecimalPattern.test(value) ||
    /^0(?:\.0+)?$/.test(value)
  ) {
    throw new InstrumentValidationError(
      `${field} must be a positive decimal string without exponent notation.`
    );
  }
  return value as PositiveDecimal;
}

/**
 * Creates a validated, immutable, provider-neutral instrument definition.
 *
 * Missing contract specifications remain absent. They are never inferred or
 * replaced with defaults; adapters must supply verified provider metadata.
 */
export function createInstrument(input: InstrumentInput): Instrument {
  if (input === null || typeof input !== "object") {
    throw new InstrumentValidationError("Instrument input must be an object.");
  }

  const id = requiredText(input.id, "id", 128);
  const symbol = requiredText(input.symbol, "symbol", 64);
  const name = requiredText(input.name, "name", 160);

  if (!assetClassSet.has(input.assetClass)) {
    throw new InstrumentValidationError("assetClass is not supported.");
  }
  if (!statusSet.has(input.status)) {
    throw new InstrumentValidationError("status is not supported.");
  }

  const baseCurrency = optionalCurrency(input.baseCurrency, "baseCurrency");
  const quoteCurrency = optionalCurrency(input.quoteCurrency, "quoteCurrency");
  const priceIncrement = optionalPositiveDecimal(input.priceIncrement, "priceIncrement");
  const quantityIncrement = optionalPositiveDecimal(input.quantityIncrement, "quantityIncrement");
  const minimumQuantity = optionalPositiveDecimal(input.minimumQuantity, "minimumQuantity");

  return Object.freeze({
    id,
    symbol,
    name,
    assetClass: input.assetClass,
    status: input.status,
    ...(baseCurrency === undefined ? {} : { baseCurrency }),
    ...(quoteCurrency === undefined ? {} : { quoteCurrency }),
    ...(priceIncrement === undefined ? {} : { priceIncrement }),
    ...(quantityIncrement === undefined ? {} : { quantityIncrement }),
    ...(minimumQuantity === undefined ? {} : { minimumQuantity })
  });
}
