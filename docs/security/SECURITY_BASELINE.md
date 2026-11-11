# Security baseline

## Implemented in this milestone

- No credential configuration or broker integration exists.
- Backend binds to `127.0.0.1` by default and emits no account or market data.
- `.gitignore` excludes environment files, common secret files, build output, and test artifacts.
- Health responses use `Cache-Control: no-store` and disclose process health only.

## Required controls before integrations

- Never place credentials, tokens, certificates, or private keys in source code, Git history, logs, or app resources.
- Define a platform-appropriate secret store, rotation and revocation procedures, and least-privilege provider scopes before adding any broker adapter.
- Add authentication, authorization, request validation, transport security, audit events, and abuse controls before exposing the API beyond loopback.
- Keep LIVE execution disabled until safety gates, explicit user authorization, operational monitoring, reconciliation, and recovery procedures are designed and validated.
- Design emergency controls to separately stop new exposure and manage existing positions.
- Treat unknown execution outcomes as requiring reconciliation; never blindly resubmit.

## Limitations

No authentication, authorization, persistence, audit logging, remote deployment controls, or broker-facing security implementation exists yet. The development API is not intended for network exposure.
