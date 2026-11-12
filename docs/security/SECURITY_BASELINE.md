# Security baseline

## Implemented in this milestone

- Backend binds to `127.0.0.1` by default and exposes only process health; it emits no account or market data through HTTP.
- The Capital.com adapter under review accepts an injected credentials provider and keeps CST/X-SECURITY-TOKEN in process memory only.
- The adapter does not read credentials from environment variables, files, source-controlled configuration, or logs.
- No broker credential provider or desktop-to-backend authentication boundary is implemented yet.
- `.gitignore` excludes environment files, common secret files, build output, and test artifacts.
- Health responses use `Cache-Control: no-store` and disclose process health only.

## Required controls before account integration

- Implement a macOS Keychain-backed credentials provider with rotation and revocation procedures.
- Establish an authenticated, least-privilege local application-to-backend boundary before exposing broker operations through HTTP or IPC.
- Never place credentials, tokens, certificates, or private keys in source code, Git history, logs, or app resources.
- Keep broker session tokens memory-only and redact authentication material from all errors and diagnostics.
- Add request validation, transport security, audit events, and abuse controls before exposing the API beyond loopback.
- Keep LIVE execution disabled until safety gates, explicit user authorization, operational monitoring, reconciliation, and recovery procedures are designed and validated.
- Design emergency controls to separately stop new exposure and manage existing positions.
- Treat unknown execution outcomes as requiring reconciliation; never blindly resubmit.

## Limitations

No Keychain provider, application/backend authentication, authorization, persistence, audit logging, remote deployment controls, or broker account session has been verified. The development API is not intended for network exposure.
