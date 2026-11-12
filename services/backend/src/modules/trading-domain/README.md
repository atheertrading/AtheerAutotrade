# Trading Domain

## Implemented foundation

The module currently provides a provider-neutral instrument definition and runtime validation:

- Stable internal instrument identifier, symbol, display name, asset class, and explicit status.
- Optional base/quote currency codes.
- Optional price and quantity increments and minimum quantity represented as exact decimal strings.
- Immutable values and validation errors for malformed metadata.
- Missing provider contract specifications remain absent; no market or broker values are fabricated.

## Boundaries

This module does not connect to a broker, ingest market data, create order intents, evaluate risk, persist records, or submit orders. Provider-specific identifiers and mappings belong in broker adapters. All future exposure-increasing intents remain subject to the centralized Risk Engine.
