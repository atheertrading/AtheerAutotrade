# ATP-UX-001 — conflict resolution record

**Date:** 2026-11-14  
**Repository:** `atheertrading/AtheerAutotrade`  
**Pull request:** [#52](https://github.com/atheertrading/AtheerAutotrade/pull/52)  
**Feature branch:** `feat/atp-ux-001-current-main`

## Reconciliation inputs

- Current `main` before reconciliation: `de293d552f48b5df4282ef92f5be1e241d930a6f`
- Feature branch head before reconciliation: `f54ef430191cf5ffd47b6a7d3b2bc9150dcc1489`
- The branch had diverged from current main (32 commits ahead and 63 behind in the GitHub comparison). GitHub reported the PR as non-mergeable.

## Resolution strategy

A merge commit is created with current `main` and the existing feature head as its two parents. The resulting tree is based on current `main`, then applies the five reviewed SwiftUI files from the feature branch and retains the UX audit.

This is a non-destructive merge: both histories remain reachable; no force-push, rebase, reset, or branch-history rewrite is used.

## File disposition

**Retained from ATP-UX-001 feature branch:**
- `apps/macos/Sources/Features/Brokers/CapitalComBrokerView.swift`
- `apps/macos/Sources/Features/Dashboard/DashboardView.swift`
- `apps/macos/Sources/Features/Dashboard/SidebarView.swift`
- `apps/macos/Sources/Features/Markets/MarketWatchView.swift`
- `apps/macos/Sources/Features/Workspace/WorkspacePanelView.swift`
- `docs/ux/ATHEER_UI_UX_AUDIT_2026-11-13.md` (with this reconciliation note appended)

**Retained from current `main`:**
- `AGENTS.md`, including mandatory owner-approved Governance Charter loading.
- `README.md`.
- `docs/engineering/ATP-PERSIST-004-SCHEMA-OWNERSHIP-PROPOSAL.md`.
- `docs/engineering/IMPLEMENTATION_STATUS.md`.
- `docs/engineering/PROJECT_CONTINUITY.md`.
- `docs/engineering/TASK_REGISTER.md`.
- `docs/engineering/VERSIONING_AND_RELEASE_POLICY.md`.

The seven documentation paths above were changed on both sides or included in the PR comparison; they are not asserted to be GitHub's exact low-level conflict-file list. Current-main copies are authoritative for this reconciliation because they contain later governance and project-state updates. The schema proposal remains proposed and owner-approval-pending.

## Scope and safety

- No database schema or migration is changed.
- No backend, broker API, OMS, RiskEngine, Execution Gateway, order submission, or LIVE permission is added or modified.
- No local files are overwritten.
- No target-Mac build or runtime result is claimed.

## Verification still required

1. Confirm GitHub reports the updated PR branch mergeable and not dirty.
2. Confirm the PR diff contains the five intended SwiftUI files and UX audit, without reverting current-main governance/status files.
3. Run target-Mac Xcode build and the UI acceptance criteria in PR #52.
4. Keep PR #52 Draft until owner-side Xcode/UI acceptance is recorded.
