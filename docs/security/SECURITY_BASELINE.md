# Security baseline

**Product:** ATHEER Trading Pro  
**Repository identifier:** AtheerAutotrade (temporary technical name)

## Implemented in the current foundation

- Backend binds to `127.0.0.1` by default and exposes process health only; it does not expose broker/account operations.
- The Capital.com adapter source accepts an injected credentials provider and keeps CST/X-SECURITY-TOKEN in process memory only.
- The adapter source does not read credentials from environment variables, files, source-controlled configuration, or logs.
- No concrete broker credential provider or desktop-to-backend authentication boundary is implemented.
- `.gitignore` excludes environment files, common secret files, build output, and test artifacts.
- Health responses use `Cache-Control: no-store` and disclose process health only.

These are repository/source observations. They do not establish a verified Keychain integration, broker session, or production security posture.

## Required controls before broker account integration

- Implement a macOS Keychain-backed credential provider with documented ownership, access controls, rotation, revocation, and migration behavior.
- Establish an authenticated, least-privilege local application-to-backend boundary before exposing broker operations through HTTP or IPC.
- Do not treat loopback binding, an unguessable URL, or obscurity as client authentication.
- Select the IPC/transport and credential-handoff mechanism through a dedicated threat-modelled ADR. Validate process identity, authorization, replay resistance, token lifecycle, crash/restart behavior, and revocation.
- Never place credentials, API keys, CST, X-SECURITY-TOKEN, certificates, or private keys in source code, Git history, logs, crash reports, process arguments, app resources, or ChatGPT.
- Keep broker session tokens memory-only and redact authentication material from all errors and diagnostics.
- Add request validation, authorization, audit events, and abuse controls before exposing any API beyond a tightly controlled local boundary.
- Separate Demo and Live environments and credentials. Live endpoint support does not authorize live account onboarding or dealing.
- Keep LIVE dealing disabled until safety gates, explicit user authorization, monitoring, reconciliation, and recovery procedures are implemented and verified.
- Design emergency controls to separately stop new exposure and manage existing positions.
- Treat unknown execution outcomes as requiring reconciliation; never blindly resubmit.

## Required execution controls

- UI, Strategy, and Intelligence components have no direct broker dealing interface.
- All exposure-increasing intents pass through the centralized Risk Engine.
- OMS owns the durable intent lifecycle.
- Execution Gateway is the only component allowed to call broker dealing operations and must require an OMS-authorized intent with a valid Risk decision bound to the immutable intent identity.
- Broker-confirmed account and execution state is authoritative.

## Current limitations

No concrete Keychain provider, authenticated application/backend boundary, authorization service, durable audit log, persistence/recovery, operational monitoring, broker account session, or execution safety chain has been verified. The development API is not intended for network exposure.

See [ADR-0004 — Production Architecture Baseline](../decisions/ADR-0004-ATHEER-PRODUCTION-ARCHITECTURE.md) for accepted system-level security and execution invariants.
