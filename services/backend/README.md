# Backend foundation

This service is a TypeScript modular monolith using Node.js built-in HTTP modules. The current runtime surface is deliberately limited to `GET /health` and structured 404 handling. It binds to loopback by default and accepts `HOST` and `PORT` configuration.

The small set of Node built-in APIs currently used has narrow local ambient declarations under `src/types/`; expand these deliberately or adopt a pinned `@types/node` dependency if backend API usage grows.

## Build and test

Run `npm ci`, `npm run build`, and `npm test`. The test suite uses Node.js built-in `node:test` and exercises an ephemeral local HTTP server.

## Boundaries

Module folders define future ownership and dependency boundaries. They contain no trading implementation in this milestone. The API must not directly connect to broker adapters, strategies, persistence, or credentials. Any future exposure-increasing intent is subject to the centralized risk-engine boundary described in `docs/architecture/MODULE_BOUNDARIES.md`.
