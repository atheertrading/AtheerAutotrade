# ATP-ARCH-OOP-003 — Backend IPC Composition Boundary

**Status:** MERGED — BACKEND CI VERIFIED; TARGET-MAC RUNTIME VERIFICATION PENDING  
**Date:** 2026-11-14  
**Branch:** `refactor/atp-arch-oop-003-stdio-composition`  
**Merged into main:** PR #47, merge commit `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`  
**Related standard:** ADR-0006 / `docs/architecture/OOP_DESIGN_STANDARD.md`  
**Related audit:** ATP-ARCH-OOP-002

## 1. Objective

Remove concrete Capital.com runtime construction from the stdio IPC transport and make backend object composition explicit, while preserving the existing protocol and read-only broker behavior.

## 2. Design

- `StdioIpcBroker` defines the broker capabilities required by the stdio IPC handler.
- `serveStdioIpc` requires an injected broker implementation; it no longer creates a concrete runtime through a default parameter.
- `server.ts` is the composition root for production stdio mode and explicitly creates `CapitalComRuntime`.
- IPC unit tests inject deterministic broker doubles. The production child-process test still starts the actual backend entry point.

This is a narrow first step. The contract remains Capital.com-shaped because the current IPC capability surface is Capital.com-specific. This is a deliberate short-term boundary, not proof of provider-neutral application decoupling. Review it against ATP-ARCH-036 before expanding broker/provider scope.

## 3. Changed files

- `services/backend/src/api/stdio-ipc.ts`
  - Removed concrete runtime import/default construction.
  - Added the explicit `StdioIpcBroker` contract.
  - Made broker injection mandatory.
- `services/backend/src/server.ts`
  - Added concrete runtime construction at the composition root.
  - Supplies the runtime to `serveStdioIpc`.
- `services/backend/tests/stdio-ipc.test.mjs`
  - Added a deterministic broker fixture for IPC unit tests.
  - Preserved the child-process production composition test.
- `docs/engineering/ATP-ARCH-OOP-002-SOURCE-CONFORMANCE-AUDIT.md`
  - Recorded the first remediation and its verification limits.
- `docs/engineering/TASK_REGISTER.md`
- `docs/engineering/IMPLEMENTATION_STATUS.md`
- `docs/engineering/PROJECT_CONTINUITY.md`

## 4. Preserved behavior and safety

- IPC protocol remains version 2.
- Frame limits, UUID correlation, duplicate detection, capability negotiation, strict payload validation, and safe error mapping remain unchanged.
- Credential transfer remains one-shot and encrypted over the existing X25519/HKDF-SHA256/AES-256-GCM channel.
- Broker capabilities remain read-only: session, market search/history, market-data streaming, and account/position/working-order snapshots.
- Disconnect cleanup remains owned by the IPC session lifecycle.
- No dealing, order submission, OMS, Execution Gateway, or LIVE capability was added.

## 5. Verification

- **Verified:** source and test changes merged through PR #47 into main at `64025fd5fc088e9b7aea3ebe4ff455c6ef5829ed`.
- **Verified:** GitHub Actions Backend CI run 43528019119 on Node.js 24.22.2; TypeScript compilation passed and 51/51 Node tests passed.
- **Not performed:** local Node commands, Xcode build, app packaging, target-Mac runtime, or real Capital.com Demo session.
- Do not mark this milestone verified until CI evidence is inspected.

## 6. Next steps

1. Retain the passing CI evidence for the merged commit; rerun CI if this code changes.
2. During the completion of ATP-ARCH-OOP-002 and ATP-ARCH-036, review whether this Capital.com-shaped broker contract belongs at the transport boundary or should be replaced by a provider-neutral application contract.
3. Do not broaden this interface or add broker dealing capabilities as part of this milestone.
4. Continue the next bounded implementation only after the source-of-truth and active-branch reconciliation is complete.
