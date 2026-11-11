# Module boundaries

All modules below are architectural ownership boundaries. Except for the Application Shell and minimal Backend API health route, they are planned and have no trading behavior in this milestone.

| Module | Responsibility | Boundary |
|---|---|---|
| Application Shell | Navigation, presentation, user interaction | UI components cannot execute broker orders or bypass backend controls. |
| Backend API | Input validation, authentication/authorization boundary, request routing, response contracts | Must not embed provider-specific execution logic. |
| Trading Domain | Instrument, order-intent, and lifecycle concepts | Domain rules remain independent of provider SDKs. |
| Risk Engine | Centralized pre-trade and exposure controls | Every exposure-increasing order intent must pass through this engine. AI agents cannot bypass it. |
| Order Management | Durable order intent and lifecycle coordination | Does not call broker APIs directly; delegates through the Execution Gateway. |
| Execution Gateway | Controlled boundary between accepted intent and external execution | Enforces idempotency and explicit outcome handling; no blind retry after unknown outcomes. |
| Broker Adapters | Provider-specific protocols and mapping | Isolated behind explicit interfaces; broker-confirmed data is authoritative for actual account and execution state. |
| Market Data | External quote, trade, and reference-data ingestion | Market observations are distinct from broker-confirmed account state. |
| Strategy Runtime | Strategy lifecycle and evaluation | Cannot access broker execution APIs; emits intents through controlled domain interfaces. |
| Portfolio | Account and position views and derived metrics | Actual state reconciles against broker-confirmed data. |
| Intelligence | Analytical and AI-assisted workflows | Cannot bypass the Risk Engine or gain implicit execution authority. |
| Persistence | Storage abstraction and migrations | Stores no source-controlled credentials; retention and audit needs require future design. |
| Security | Identity, authorization, secrets boundaries, audit, and safety controls | Least privilege, explicit authorization, and auditable state transitions are required. |

## Mandatory governance constraints

1. Every order intent that can increase exposure passes through the centralized Risk Engine.
2. UI components cannot directly execute broker orders.
3. AI agents cannot bypass the Risk Engine.
4. Strategy modules cannot directly access broker execution APIs.
5. Broker adapters remain isolated behind explicit interfaces.
6. Broker-confirmed data is authoritative for actual account and execution state.
7. Unknown execution outcomes must not trigger blind duplicate submissions.
8. LIVE trading remains disabled until required safety gates and explicit authorization are implemented.
9. Credentials are never stored in source code.
10. Emergency controls distinguish blocking new exposure from managing existing positions.

These constraints describe future architecture and do not authorize or implement execution functionality.
