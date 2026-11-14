# Repository Working Instructions

These instructions apply to every coding agent and automated assistant working in this repository.

## Mandatory context loading

Before planning, reviewing, or changing anything, read these files in this order:

1. `docs/engineering/ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md` — owner-approved project role, product scope, governance, trading requirements, safety, and continuity rules.
2. `docs/engineering/PROJECT_GOVERNANCE_CHARTER.md` — official owner-approved governance charter, engineering principles, team decision protocol, and repeat-error prevention controls.
3. `docs/engineering/VERSIONING_AND_RELEASE_POLICY.md` — SemVer, immutable Git tags, component versions, migration versioning, and release qualification.
4. `docs/engineering/PROJECT_CONTINUITY.md` — current handoff, owner-confirmed environment facts, active branches, and unresolved issues.
5. `docs/engineering/TASK_REGISTER.md` — milestone state and next actions.
6. `docs/engineering/IMPLEMENTATION_STATUS.md` — implemented, unimplemented, and unverified behavior.
7. The relevant accepted architecture decision records under `docs/decisions/`.
8. The relevant architecture, API contract, broker, and security documents for the task.

The custom instructions are normative project guidance. This file operationalizes them for repository work; neither this file nor an assistant's memory may silently narrow the product requirements.

The repository documents are the persistent engineering source of truth. Conversation history and model memory are supplementary and must never override verified repository records without new evidence.

## Project continuity rules

- Resume from the recorded current state. Do not restart the project or repeat completed milestones.
- Do not reopen a resolved issue unless new evidence demonstrates regression or a concrete technical dependency.
- Treat user-confirmed facts as authoritative unless contradicted by newer direct evidence.
- Distinguish verified implementation, user-reported results, agent-reported observations, assumptions, and pending validation.
- Never claim that a build, test, runtime behavior, signing operation, or portal configuration succeeded unless the corresponding result was actually observed.
- Inspect the exact files and their current contents before editing them.
- Preserve unrelated files, local-only work, user settings, and existing application behavior.
- Never use destructive synchronization or cleanup operations (including broad delete/replace operations) without explicit authorization.
- Do not reopen Git troubleshooting when the user has confirmed that the Git issue is resolved. Do not reset, force-push, rewrite history, or change branches unless explicitly authorized.
- Work on one defined milestone at a time. State scope, dependencies, acceptance criteria, and verification before implementation.
- Prefer coherent, complete changes over speculative patches. Do not add dependencies or capabilities without a demonstrated requirement.
- Update the continuity record and task register after each completed milestone or material decision.

## Product purpose and mandatory trading capability

ATHEER Trading Pro is a professional trading platform, not a read-only market-data viewer. Its required product scope includes both manual/operator-initiated and automated/strategy-initiated trading, broker-linked DEMO and LIVE environments, and the complete order lifecycle. A read-only broker adapter is permitted only as an explicitly scoped incremental milestone; it is never the permanent product architecture or an acceptable final product boundary.

- Manual and automated intents must use the same governed backend order-intake path.
- Every exposure-increasing intent must pass centralized RiskEngine validation before durable OMS authorization and Execution Gateway dispatch.
- Only the Execution Gateway may invoke broker dealing APIs. UI, strategies, and AI must never call dealing endpoints directly.
- Broker confirmation and reconciliation are required; a submission response alone does not prove a filled/open position.
- Ambiguous submission outcomes require reconciliation and must never be blindly retried.
- DEMO is the first broker-dealing qualification environment. LIVE is a required product capability but remains disabled until safeguards are implemented and verified and the owner explicitly authorizes activation.
- Do not report trading as implemented merely because an adapter method, button, mock test, or draft PR exists. The complete order path must be integrated and verified.

## Documentation and version control

Every material code or architecture change must be recorded in `docs/engineering/TASK_REGISTER.md`, `docs/engineering/IMPLEMENTATION_STATUS.md`, and, when the handoff changes, `docs/engineering/PROJECT_CONTINUITY.md`. Consequential decisions require an ADR. Use reviewed branches and pull requests; preserve history and use version tags/releases at approved milestones. Never rebuild from scratch, reset, clean, force-push, or overwrite completed work to compensate for missing context.

## Codex usage boundary

Codex is an implementation and test tool, not the project owner, architect, or source of truth.

The recorded reason for introducing Codex in the current workflow was a bounded XCTest problem. Do not silently expand that assignment into a general project audit, wholesale Xcode reconfiguration, architecture redesign, or unrelated implementation. Use Codex only for a clearly scoped task that the user has assigned or explicitly approved.

When preparing a Codex task:
- Give it the exact objective, allowed files, constraints, acceptance criteria, and verification steps.
- Require it to read this file and the continuity documents first.
- Prohibit unrelated edits and repeated tests without a new technical reason.
- Require an evidence-based report listing changed files and actual command/test results.
- Do not ask the user to run a chain of speculative commands when a single bounded task can be executed safely.

## Trading and security governance

- All future order intents must pass through the centralized Risk Engine.
- UI components, strategies, and AI services must not bypass risk controls or call broker execution APIs directly.
- Broker-confirmed account and execution state is authoritative.
- Never put credentials, API keys, tokens, certificates, or private keys in source code, Git history, logs, or ChatGPT.
- Use platform-appropriate secure storage for secrets when implemented.
- LIVE trading remains disabled until required safety controls and explicit user authorization are implemented.
- Never execute a real trade without explicit user approval.

## Completion and handoff

A task is complete only when its acceptance criteria are met and the evidence is recorded. Update:
- `docs/engineering/TASK_REGISTER.md` for task state and next action.
- `docs/engineering/IMPLEMENTATION_STATUS.md` for actual implementation and verification status.
- `docs/decisions/` with a new ADR when a consequential architectural decision is made.
- `docs/engineering/PROJECT_CONTINUITY.md` when the current handoff, environment, constraints, or active milestone changes.

Do not create duplicate status or decision documents when an authoritative document already exists.


## Project-wide OOP design standard

All new and materially changed source across the entire repository must comply with [ADR-0006](docs/decisions/ADR-0006-OBJECT-ORIENTED-DESIGN-STANDARD.md) and [OOP Design Standard](docs/architecture/OOP_DESIGN_STANDARD.md). This applies to Swift/SwiftUI, TypeScript/Node.js, tests, directories, and files.

- Design around cohesive objects, encapsulated state, explicit protocols/interfaces, composition, dependency injection, and explicit lifecycle ownership.
- Use idiomatic Swift structs/enums/protocols and TypeScript interfaces/classes according to semantics. Do not force every file/function into a class.
- Organize folders by bounded context and architectural layer; name files for their primary type/responsibility.
- Keep UI declarative and prevent UI, strategy, or intelligence code from owning broker, risk, OMS, or dealing behavior.
- Preserve existing paths and behavior. Apply conformance incrementally; no wholesale rewrite or cosmetic folder churn.
- Significant objects must document responsibility, contracts, state/lifecycle, dependencies, concurrency, failure behavior, security authority, and tests.
