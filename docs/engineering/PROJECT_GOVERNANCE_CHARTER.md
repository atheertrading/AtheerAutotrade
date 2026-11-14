# ATHEER Trading Pro — Official Project Governance Charter

**Authority:** Owner-approved source document supplied on 2026-11-14  
**Status:** Official governance reference; implementation status remains governed by the live repository records  
**Source:** Owner-supplied document, preserved below with a reconciliation addendum

> **Important interpretation:** This charter records the owner's approved project mission and governance principles. Historical environment paths, historical milestone descriptions, and previously reported implementation states inside the source text are records from the source document, not current implementation evidence. For current repository state, active work, verified toolchain, and next actions, always consult PROJECT_CONTINUITY.md, TASK_REGISTER.md, and IMPLEMENTATION_STATUS.md. The current source code determines what is implemented. This charter does not authorize LIVE trading.

---

ATHEER Trading Pro
Official Project Governance, Engineering Charter & AI Collaboration Instructions
Owner Approved
Official Project Documentation
Engineering Governance
Project: ATHEER Trading Pro
Document Status: Owner-approved project governance baseline
Document Purpose: Establish the authoritative project context, governance principles, engineering standards, approval status, and collaboration protocol for all project-related planning and implementation.

1. Document Authority and Owner Approval
The project owner has formally approved the ATHEER Trading Pro project and authorized its continued planning, engineering, and implementation, subject to the conditions and governance requirements established in this document.
This approval is expressly conditional upon the project being executed professionally by a suitably qualified and experienced team possessing the necessary expertise in software engineering, financial technology, algorithmic trading, automated execution systems, quantitative analysis, and trading risk management.
Before adopting or implementing any material engineering, technical, architectural, or algorithmic approach, the responsible execution team must evaluate the relevant alternatives, assess their implications, and reach a documented professional consensus regarding the proposed implementation methodology.
The agreed approach must be consistent with the project's objectives, risk controls, security requirements, technical constraints, operational requirements, and long-term maintainability.
The owner's approval supersedes any previous wording in the project documentation indicating that the project, its implementation, or its governing documentation is awaiting the owner's approval.
Approval interpretation:
The project and its governance framework are officially approved by the owner. Individual implementation decisions remain subject to appropriate engineering review, professional consensus, technical validation, and acceptance procedures.
Project approval does not constitute blanket authorization for live trading, nor does it waive security controls, testing requirements, operational safeguards, or any separate authorization required before executing real trades.

2. Project Identity and Mission
ATHEER Trading Pro is a professional, production-oriented, multi-asset trading platform designed to integrate:
* Native macOS application software.


* Real-time and historical market data.


* Advanced charting and technical analysis.


* Manual and algorithmic trading workflows.


* AI-assisted and multi-agent analytical capabilities.


* Quantitative research and strategy development.


* Backtesting and trading simulation.


* Broker connectivity and order management.


* Centralized risk management and portfolio oversight.


* Customizable, responsive, and extensible workspaces.


The platform's mission is to bring human trading expertise, disciplined automation, quantitative methodologies, and artificial intelligence into one coherent trading environment.
The system must prioritize data integrity, execution reliability, risk transparency, operational safety, and verifiable results over superficial demonstrations or unsupported performance claims.
The intended outcome is a robust, intelligent, and extensible trading ecosystem that supports informed market analysis and controlled trade execution across supported asset classes and broker services.

3. Project Knowledge Base and Source-of-Truth Hierarchy
These governance instructions and supplementary project documents are not standalone specifications.
They constitute an integrated project knowledge base and must be interpreted and utilized alongside the following resources:
3.1 Authoritative project resources
1. Atheer Q&A Repository.zip
Contains project questions, answers, clarifications, and relevant historical context.
2. Consolidated Architectural Foundation & Engineering Execution.zip
Contains consolidated architectural foundations, technical decisions, engineering specifications, and implementation guidance.
3. ATHEER Trading GitHub Repository
Contains the source code, implementation history, and actual engineering state of the application.
4. Current Project Documentation
Includes architecture records, specifications, requirements, decision logs, implementation plans, testing evidence, and operational procedures.
5. Official Project Governance Documentation
Establishes the project-wide principles, owner approval, engineering standards, and collaboration requirements.
3.2 Integrated knowledge management
All project resources must be considered collectively to maintain a unified product vision, consistent architectural direction, and coordinated implementation strategy.
The AI assistant and engineering team must not treat individual documents, archived discussions, or isolated code files as complete representations of the project.
The resources must be reviewed in context, with appropriate attention to their relationships, dependencies, historical development, and current relevance.
3.3 Authority and conflict resolution
The following principles govern the interpretation of project information:
* The actual GitHub repository and inspected source code determine what has been implemented.


* Approved requirements and documented architectural decisions determine what should be implemented.


* This governance document establishes the project's overarching engineering and collaboration principles.


* Historical Q&A and archived documentation provide context but must not silently override newer approved decisions.


* No statement in an archive, previous conversation, or generated document should be treated as proof that a feature currently exists in the application.


Whenever conflicting information is discovered:
1. Identify the conflicting statements or implementations.


2. Reference the affected documents, files, or decisions.


3. Explain the technical and architectural implications.


4. Evaluate the available alternatives.


5. Obtain the appropriate engineering decision or owner approval.


6. Update the relevant documentation to maintain consistency.


No project resource should be considered disposable, irrelevant, or superseded without first evaluating its role and dependencies.

4. Working Environment and Technical Baseline
The following information represents the recorded project environment and must be verified against the actual development machine before being treated as the current configuration.
Component	Recorded configuration
Local repository	/Users/enghossamalfahad/Developer/AtheerProject
Application platform	macOS
UI framework	SwiftUI
Bundle identifier	com.atheertrading.desktop
Primary broker	Capital.com
Backend direction	Node.js / TypeScript
Deployment target	macOS 13.0
Recorded hardware	iMac18,3 (Intel)
Recorded operating system	macOS Ventura 13.7.8
Target architectures	x86_64 and arm64, subject to feasibility and testing
4.1 Development toolchain records
The supplied project documentation contains two historical toolchain references:
Earlier recorded configuration:
* Xcode 14.3.1.


* Swift 5.8.1.


* macOS SDK 13.3.


Later recommended baseline:
- Xcode 15.2, subject to verification against the actual development environment.
These records must not be represented as one simultaneously verified configuration.
The engineering team must inspect the actual development environment and establish the current toolchain baseline.
The verification must include:
* Installed Xcode version.


* Swift compiler version.


* macOS SDK version.


* Installed macOS version.


* Supported hardware architecture.


* Project build settings.


* Successful compilation and application execution.


Until verification is completed, Xcode 15.2 remains a recorded recommendation rather than a confirmed installation.
4.2 Development toolchain policy
1. Select the newest stable Xcode version supported by the actual development Mac and its installed macOS version.


2. Do not downgrade the development toolchain merely to preserve historical project settings.


3. Do not require hardware or operating-system upgrades solely because a newer Xcode release is available.


4. Maintain macOS 13.0 as the deployment target unless a documented technical or product requirement justifies changing it.


5. Use Swift 5 language mode where necessary for compatibility and evaluate Swift 6 migration incrementally.


6. Maintain Intel x86_64 and Apple Silicon arm64 support where technically feasible and required.


7. Use native macOS APIs and availability checks appropriate to the declared deployment target.


8. Distinguish the development toolchain version from the application's minimum supported macOS version.


9. Record the exact Xcode version, Swift compiler version, SDK, architecture, build configuration, and build result for every verified milestone.


10. Reassess the toolchain whenever development hardware, macOS, dependencies, or product requirements change.


Compatibility must never be claimed without appropriate build and runtime verification.

5. Engineering Governance and Architecture Principles
The engineering team must adhere to the following principles throughout the project.
1. Continuity: Preserve project context, decisions, progress, and unresolved issues across all development sessions.
2. Inspection before modification: Inspect existing repository files, implementation, architecture, dependencies, and documentation before proposing or making changes.
3. No unnecessary reconstruction: Never recreate existing components or repeat completed tests without a clear technical justification.
4. Repository fidelity: Treat the current repository as the factual record of implementation.
5. Traceability: Maintain requirements, architectural decisions, implementation status, test evidence, and decision logs.
6. Complete deliverables: Prefer complete, coherent replacement files over fragmented patches whenever practical. For localized changes, provide precise patches with sufficient context.
7. Compatibility: Use APIs and language features supported by the verified development environment and deployment target.
8. Dependency discipline: Do not introduce dependencies without evaluating their maintenance, security, licensing, compatibility, performance, and operational implications.
9. Separation of concerns: Maintain appropriate boundaries between presentation, domain logic, data services, broker integration, strategy execution, risk management, and order routing.
10. Centralized risk enforcement: Every order intent, regardless of its origin, must pass through the centralized RiskEngine before reaching the execution layer.
11. Testability: Design components around clear interfaces, dependency injection where appropriate, deterministic testing, and observable behavior.
12. Operational resilience: Account for network interruptions, stale market data, broker errors, partial fills, rejected orders, duplicate events, application restarts, and recovery scenarios.
13. Evidence-based claims: Clearly distinguish verified implementation facts from proposals, assumptions, estimates, and untested hypotheses.
14. Incremental delivery: Implement, test, and verify one defined milestone at a time.
The architecture should prioritize modularity, SOLID principles, dependency inversion, clear ownership of state, explicit interfaces, and maintainable system boundaries.
These principles must be applied pragmatically to achieve a robust production architecture rather than treated as formalities.

6. Trading, Security, and Operational Safety
Trading safety is a foundational system requirement and must be incorporated into the architecture from the earliest development stages.
6.1 Credentials and secrets management
* Never request, expose, paste, or store broker credentials in ChatGPT conversations, source code, logs, screenshots, or ordinary configuration files.


* Store macOS application credentials securely using macOS Keychain.


* Use appropriate environment-specific secrets management for backend services.


* Redact tokens, account identifiers, and sensitive information from logs and diagnostics.


* Apply least-privilege access principles and secure credential rotation procedures.


6.2 Risk management and order execution
* All order intents must pass through the centralized RiskEngine.


* UI components, strategy modules, plugins, and AI agents must never bypass centralized risk validation.


* The execution layer must validate order parameters and applicable limits before submitting orders.


* Risk checks should account for exposure, position size, available funds or margin, instrument constraints, market conditions, and duplicate or conflicting orders.


* Risk decisions and execution outcomes must be auditable.


* Failure of a mandatory safety check must prevent the order from proceeding.


* AI agents may analyze markets, recommend strategies, evaluate opportunities, and prepare trade intents within their assigned permissions.


* AI agents must never independently override risk controls or user authorization.


6.3 Demo and live trading environments
* Demo/paper trading and live trading must be explicitly distinguished throughout the application and its backend services.


* LIVE trading must remain disabled by default.


* Enabling LIVE trading requires completion of all applicable safety controls, testing, operational readiness checks, and explicit owner authorization.


* No real trade may be executed without the explicit authorization required by the approved live-trading workflow.


* Approval of the project or this documentation must never be interpreted as blanket permission to execute real trades.


* Implement safeguards against accidental environment switching and unintended order submission.



7. Development Lifecycle and Milestone Control
Development must proceed through clearly defined, reviewable, and verifiable milestones.
Each milestone must follow this process:
1. Define its objective, scope, assumptions, dependencies, and acceptance criteria.


2. Inspect the existing implementation and relevant documentation.


3. Identify material architectural, technical, and algorithmic alternatives.


4. Evaluate the available approaches and their implications.


5. Document the recommended implementation approach and required team consensus.


6. Implement the agreed scope.


7. Execute the appropriate builds, automated tests, integration tests, and manual verification.


8. Document changed files, procedures, test results, limitations, and outstanding issues.


9. Update implementation status and the engineering decision log.


10. Obtain the required review or acceptance before proceeding to dependent milestones.


A milestone must not be considered complete simply because code has been written.
Completion requires verifiable evidence demonstrating that its acceptance criteria have been satisfied.
7.1 Standard implementation status
Use the following status terminology consistently:
Status	Meaning
Proposed	Suggested but not approved.
Approved	Accepted by the appropriate decision authority.
In Progress	Implementation has begun.
Implemented — Unverified	Implementation exists but has not passed required verification.
Verified	Required checks have passed and supporting evidence is recorded.
Blocked	Progress depends on an unresolved issue or decision.
Deprecated	Superseded by another implementation or decision, with the reason documented.
Never describe a feature as completed or verified without supporting evidence.

8. Engineering Team Competencies and Functional Responsibilities
The project requires coordinated professional expertise across the following disciplines.
This list defines the capabilities and responsibilities necessary for successful execution. It does not imply that every role must be staffed by a separate individual.
8.1 Architecture and application engineering
* Engineering Leadership and Chief Software Architecture.


* Software Architecture Engineering.


* Senior macOS Engineering.


* Swift and SwiftUI Application Engineering.


* Frontend Engineering.


* Backend and Services Engineering.


* Data Engineering.


* API and Broker Integration Engineering.


8.2 Trading and quantitative engineering
* Trading Strategy Research and Specification.


* Algorithmic Trading Engineering.


* Automated Trading Systems Engineering.


* Quantitative Research.


* Technical Indicator Engineering.


* Risk Management Engineering.


* Backtesting and Simulation Engineering.


* Professional Trading Supervision.


* Execution Analysis and Optimization.


8.3 AI and market intelligence
* AI Agent and Multi-Agent Systems Engineering.


* Agent Orchestration and Permission Management.


* AI Evaluation and Observability.


* Market Data Quality and Real-Time Monitoring.


* Strategy Comparison and Evidence-Based Decision Support.


8.4 Visualization and user experience
* Charting Systems Engineering.


* Candlestick and Market Data Visualization.


* Technical Drawing and Indicator Visualization.


* Trade Visualization.


* Market Monitoring and Heatmap Engineering.


* UI/UX and Workspace Engineering.


* Dynamic Workspace Engineering.


* Responsive Interface Engineering.


* Navigation and Information Architecture.


* Accessibility and Interaction Design.


Where one individual or team assumes multiple responsibilities, ownership of those responsibilities must remain explicitly defined and reviewable.

9. Team Collaboration and Decision Protocol
The AI assistant acts as a technical planning and engineering collaborator under the direction of the project owner.
Its responsibilities include:
* Architecture analysis.


* Technical recommendations.


* Implementation guidance.


* Code review support.


* Test planning.


* Documentation.


* Identification of technical risks.


* Evaluation of alternative approaches.


* Constructive engineering criticism.


The human execution team remains responsible for professional engineering judgment, actual code execution, independent verification, and operational decisions.
9.1 Professional consensus requirements
For material engineering, technical, architectural, or algorithmic decisions:
1. Identify the decision and the disciplines affected.


2. Evaluate viable alternatives.


3. Compare alternatives according to reliability, latency, security, trading risk, usability, scalability, maintainability, cost, and broker constraints.


4. Identify assumptions and unresolved technical questions.


5. Obtain documented consensus from the responsible execution team.


6. Escalate unresolved disagreements and material scope changes to the project owner.


7. Record the final decision, rationale, date, responsible participants or roles, and implementation consequences.


Recommendations must not be represented as approved decisions.
A proposed architecture or algorithmic approach becomes an agreed implementation direction only after the required professional review and decision process.
9.2 Communication standards
Communication must be technically precise, direct, constructive, and transparent.
The assistant should:
* Challenge unsupported assumptions respectfully.


* Identify overlooked risks and opportunities.


* Explain complex concepts clearly.


* Present practical alternatives.


* Convert decisions into actionable engineering tasks.


* Distinguish verified facts from assumptions and recommendations.


* Provide relevant conclusions and technical rationale without claiming access to unverified implementation details.



10. Documentation and Change Management
The project must maintain professional, consistent, and traceable engineering documentation.
The documentation framework should include, where applicable:
* Product requirements and scope.


* System context and architecture diagrams.


* Architecture Decision Records (ADRs).


* Component and interface specifications.


* Data models and market-data contracts.


* Broker integration specifications.


* Order lifecycle documentation.


* Trading strategy specifications.


* Risk policies and control matrices.


* Security and secrets-management procedures.


* Backtesting and simulation methodologies.


* Test plans and test reports.


* Acceptance and verification evidence.


* Deployment and monitoring procedures.


* Incident management and recovery procedures.


* Milestone plans and implementation status.


* Known issues and technical debt.


* Change history and architectural evolution.


Documentation must reflect the actual implementation or clearly identify itself as a proposal.
Where documentation and source code diverge, the discrepancy must be recorded and resolved through the established change-management process.
Changes to approved requirements or architecture must document:
1. Reason for the change.


2. Technical and product impact.


3. Affected components and documents.


4. Compatibility and migration implications.


5. Risks and required testing.


6. Required approval.



11. Initial Recorded Project Status
The supplied project documentation reports the following historical milestones:
* Native macOS Xcode project created.


* Project successfully opened in Xcode.


* Initial build succeeded.


* Application successfully launched.


* Next recorded milestone: Professional macOS application shell and workspace architecture.


These are previously reported project facts and have not been independently re-verified by this document.
Before relying on them as the current implementation state, inspect the repository and repeat only the checks necessary to establish the actual baseline.
Next development milestone
Professional macOS Application Shell and Workspace Architecture
The milestone should begin with:
1. Repository inspection.


2. Development environment verification.


3. Existing architecture assessment.


4. Application shell requirements.


5. Workspace architecture design.


6. Component boundaries and responsibilities.


7. Acceptance criteria.


8. Implementation and testing strategy.



12. Required AI Assistant Operating Instructions
When working on ATHEER Trading Pro, the assistant must operate according to the following instructions.
1. Act as a senior engineering and architecture collaborator with expertise in macOS development, financial technology, broker APIs, quantitative systems, algorithmic trading, AI agents, and risk management.
2. Review and reconcile relevant project resources before making recommendations that depend on historical decisions or existing implementation details.
3. Preserve continuity across conversations by maintaining accurate records of decisions, progress, blockers, and next steps.
4. Be proactive in identifying technical risks, missing requirements, architectural opportunities, and potential improvements.
5. Challenge assumptions constructively and explain material technical trade-offs.
6. Clearly distinguish facts, source-derived statements, recommendations, assumptions, and unresolved questions.
7. Never invent files, code changes, test results, tool versions, broker capabilities, or implementation status.
8. Never claim to have inspected, modified, built, tested, committed, or deployed anything unless the action was actually performed or reliable evidence was provided.
9. Provide implementation instructions compatible with the verified project environment.
10. Prioritize secure, modular, testable, observable, and maintainable solutions.
11. Ensure every trading path remains subject to the centralized RiskEngine and applicable authorization procedures.
12. Deliver one coherent implementation milestone at a time and define how completion will be verified.
13. Ask focused clarification questions whenever missing information materially affects technical correctness, architecture, or safety.
14. Treat the owner's approved governance framework as authoritative unless it is formally superseded.
15. Consider the project archives, GitHub repository, engineering documentation, and project instructions as interconnected components of one unified knowledge base.

13. Immediate Next Actions
The following actions establish the recommended next stage of project execution.
No.	Action	Expected outcome
1	Inspect the current GitHub repository and local project structure.	Verified implementation baseline.
2	Review Atheer Q&A Repository.zip.	Recovered project context and clarifications.
3	Review Consolidated Architectural Foundation & Engineering Execution.zip.	Consolidated architectural understanding.
4	Verify the actual development environment.	Confirmed toolchain and compatibility baseline.
5	Reconcile historical Xcode and Swift records.	Accurate environment documentation.
6	Establish the project documentation index.	Discoverable and organized knowledge base.
7	Update implementation status and decision records.	Traceable engineering progress.
8	Define the application shell and workspace architecture milestone.	Approved technical scope and acceptance criteria.
9	Obtain the execution team's professional consensus on material implementation decisions.	Agreed engineering, technical, and algorithmic direction.
10	Begin implementation and verification.	Evidence-based milestone delivery.
14. Official Project Governance Statement
ATHEER Trading Pro is an officially owner-approved project authorized to proceed through professional engineering, disciplined technical execution, and documented implementation decisions.
The project must be executed by a suitably qualified and experienced team possessing the necessary expertise in automated trading, software engineering, quantitative systems, broker integration, and financial technology.
All material engineering, technical, architectural, and algorithmic implementation approaches must undergo appropriate professional evaluation and receive documented consensus from the responsible execution team.
This document, the project archives, the consolidated architectural foundation, the current engineering documentation, and the GitHub source repository collectively constitute the integrated project knowledge base.
These resources must be used together to preserve a unified vision, consistent architectural direction, and coordinated implementation strategy.
The governing standard is professional execution:
* Clear ownership and accountability.


* Sound engineering judgment.


* Documented professional consensus.


* Rigorous technical validation.


* Secure and maintainable architecture.


* Reliable market data and broker integration.


* Centralized and enforceable risk controls.


* Evidence-based implementation milestones.


* Explicit authorization for live trading.


The ultimate objective is to develop ATHEER Trading Pro into a robust, intelligent, extensible, and professionally engineered automated trading platform in which human expertise, quantitative methodologies, artificial intelligence, and disciplined execution operate together within a secure and verifiable framework.

15. Document Adoption and Approval
ATHEER Trading Pro
Approved
Approval status: Owner-approved project governance and engineering framework.
Approval scope: Project continuation, professional engineering execution, and adoption of the governance principles established herein.
Implementation condition: Professional execution by a suitably qualified team, with documented consensus on material engineering, technical, architectural, and algorithmic decisions.
Live trading condition: Separate safety validation and explicit authorization remain mandatory.

This document supersedes prior approval-pending language concerning the project and this governance framework. It does not supersede more specific approved technical specifications unless formally amended.


Document prepared as the proposed official governance baseline for ATHEER Trading Pro.

---

## 16. Repository adoption, precedence, and error-prevention addendum

This addendum makes the charter operational inside the GitHub engineering workflow. It supplements, and does not silently replace, the owner-approved source text above.

### 16.1 Mandatory context-loading sequence

Before every project task, every coding agent or assistant must:

1. Read repository-root AGENTS.md.
2. Read this Official Project Governance Charter.
3. Read ATHEER_TRADING_PRO_CUSTOM_GPT_INSTRUCTIONS.md and VERSIONING_AND_RELEASE_POLICY.md.
4. Read PROJECT_CONTINUITY.md, TASK_REGISTER.md, and IMPLEMENTATION_STATUS.md.
5. Inspect the relevant accepted ADRs, architecture/API contracts, source files, tests, and related PRs.
6. Establish the exact GitHub base commit, branch/PR head, changed files, and relevant CI evidence before proposing or editing.

Do not rely on conversation memory, stale summaries, old PR descriptions, or an earlier branch snapshot when current repository evidence is available.

### 16.2 Repeat-error prevention controls

- **No restart by default:** resume from the latest verified repository state. Rebuilding, scaffolding, or replacing an existing component requires a documented technical reason and owner approval when material.
- **No repeated resolved troubleshooting:** do not repeat a resolved Git, Xcode, build, test, or environment procedure unless new evidence shows regression or the task requires a fresh verification.
- **No assumed access:** state clearly whether work is performed through GitHub, a connected tool, or the owner's local Mac. Never imply local Terminal/Xcode access unless actually available.
- **No stale branch work:** before editing or merging a feature branch, compare it with current main; refresh it without rewriting history, and re-check mergeability and CI at the resulting head.
- **No unreviewed main edits:** use a scoped branch and pull request for material documentation or code changes. Do not merge or close a PR unless authorized by repository policy and the owner's approval boundary.
- **No duplicate records:** update the existing authoritative task/status/continuity/ADR documents instead of creating parallel status files. Link new governance material from AGENTS.md and README.md.
- **No status inflation:** distinguish Proposed, Approved, In Progress, Implemented—Unverified, Verified, Blocked, and Deprecated. A source file, mock test, draft PR, or green CI job does not establish end-to-end operational readiness.
- **No unsupported execution claims:** record exact commands, tool versions, commit/PR heads, CI run identifiers, test counts, and outcomes only when observed. Label owner-reported results separately from independently verified results.
- **No silent conflict resolution:** when code, requirements, ADRs, continuity records, or historical archives disagree, identify the exact conflict, preserve the evidence, explain impact, and route material decisions through the documented approval process.
- **No unsafe trading shortcuts:** preserve centralized RiskEngine enforcement, durable OMS authorization, Execution Gateway ownership, broker confirmation/reconciliation, no blind retry for ambiguous outcomes, separate DEMO/LIVE environments, and explicit LIVE authorization.
- **No loss of work:** never reset, clean, force-push, rewrite history, discard local changes, or overwrite completed work to compensate for missing context.

### 16.3 Required task handoff record

At the end of every material task, update the existing records with:

- Objective, scope, and acceptance criteria.
- Base commit, branch, PR, and resulting commit/CI references.
- Files added, changed, or intentionally left untouched.
- Implementation state and evidence, including tests not run and why.
- Decisions made, assumptions, unresolved conflicts, and owner approvals required.
- Remaining blockers and one precise next action.

If no code or repository change was made, say so. Do not create a commit, release tag, or implementation claim merely to make a task appear complete.

### 16.4 Authority and change control

The owner-approved project mission and governance principles are normative. Specific accepted ADRs and approved requirements govern their respective technical domains. The current repository establishes implementation facts. Current continuity, task, and implementation records establish the working handoff. Any proposed amendment must preserve history, state its rationale and impact, and follow the applicable review and approval process.

The charter is persistent project guidance. It must be read at the start of future work, and it must be updated only through a traceable documentation change.
