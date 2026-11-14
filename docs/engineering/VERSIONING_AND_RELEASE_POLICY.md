# ATHEER Trading Pro — Versioning and Release Policy

**Status:** Normative engineering policy  
**Applies to:** macOS application, backend, APIs/contracts, database migrations, and release artifacts  
**Effective baseline:** 2026-11-14

## 1. Product release versioning

Use Semantic Versioning for integrated product releases:

`MAJOR.MINOR.PATCH`

Until the first production-ready release, remain in the `0.x.y` development series:

- **0.MINOR.PATCH:** increment MINOR for a completed, owner-accepted milestone or a materially expanded pre-1.0 capability set.
- **PATCH:** increment PATCH for compatible corrections, hardening, and defects that do not redefine the milestone.
- **1.0.0:** only after the owner approves the first production release and the complete release qualification criteria are satisfied.
- **MAJOR:** increment for incompatible public contract or product changes after 1.0.

Pre-release identifiers follow SemVer: `-alpha.N`, `-beta.N`, and `-rc.N`. Do not call an unqualified development branch a release.

## 2. Git tags and immutable baselines

- Tag only a commit already merged into `main`.
- Use annotated tags named `vMAJOR.MINOR.PATCH` (or the exact pre-release form).
- A release tag is immutable. Never move or overwrite an existing tag; create a new patch/pre-release tag.
- Every tag must point to a documented release record containing the exact commit SHA, included PRs, change summary, verification evidence, known limitations, and rollback notes.
- Preserve all prior tags and commit history. Do not force-push shared branches or rewrite released history.
- A branch or PR is not a release. Draft PRs and CI-only milestones must not receive production release tags.
- The first baseline tag is to be created only when the owner approves a named milestone and its acceptance evidence. This policy does not invent a current product version or claim a tag exists.

## 3. Component version alignment

- The macOS app's `CFBundleShortVersionString` follows the approved product SemVer version.
- The macOS app's `CFBundleVersion` is a monotonically increasing build number for distributed builds; it is not a substitute for the product version.
- The backend package version follows the same product release line when shipped as part of the integrated product. Internal package/API compatibility versions may evolve independently when documented.
- IPC protocol versions, broker adapter contract versions, database `schema_version` fields, and migration sequence numbers are separate compatibility/version domains. Never overload the product SemVer value for these.
- Each public API/IPC contract must define its compatibility and deprecation policy before incompatible changes.

## 4. Database migration versioning

- Migration files use monotonically ordered, unique version identifiers and immutable checksums.
- Never edit or delete a migration that has been applied to any environment.
- Correct unapplied migrations only before first application and record the decision; after application, use a new forward migration.
- Record applied version and checksum, and reject checksum drift.
- Database rollback is handled by a tested forward migration or a verified backup/restore procedure; do not assume arbitrary reverse SQL is safe.

## 5. Release qualification record

A release record must include:

1. Product version and tag.
2. Main commit SHA and merged PR list.
3. macOS/Xcode/Swift versions and target build result.
4. Backend toolchain and complete CI/test results.
5. Database migration versions and integration/restore evidence.
6. Broker environments and capabilities qualified (SIM/DEMO/LIVE), with no credentials or account secrets.
7. RiskEngine, OMS, Execution Gateway, reconciliation, recovery, and operational safety acceptance.
8. Known issues, limitations, and rollback procedure.
9. Owner release approval.

A release tag or successful build does not authorize LIVE trading. LIVE remains disabled until all safety gates pass and the owner separately authorizes activation.

## 6. Current status

- This policy defines the versioning scheme; it does not claim that a product release tag has been created.
- No version number should be fabricated or assigned to the current unqualified application baseline.
- The first approved milestone tag must be created after the owner accepts the milestone and its documented verification evidence.
