# ATHEER Trading Pro — Baseline and Versioning Policy

**Document ID:** ATP-REL-001  
**Status:** Owner-directed project control; proposed documentation change pending review  
**Recorded:** 2026-11-14  
**Repository:** `atheertrading/AtheerAutotrade`  
**Product:** ATHEER Trading Pro

## 1. Purpose and authority

This document establishes the immutable source reference for the current preserved project snapshot and the mandatory version-control and release-recording process for subsequent work.

The baseline identifies a recoverable repository state. It does **not** certify that the product is complete, production-ready, connected to a live broker, or authorized to trade. Requirements, accepted architecture decisions, implementation evidence, and verification status remain governed by their respective repository records.

## 2. Established baseline

| Item | Recorded value |
|---|---|
| Baseline version label | `v1.0.0-baseline` |
| Annotated Git tag | `v1.0.0-baseline` |
| Baseline branch | `baseline/local-stable-v1` |
| Baseline commit | `264b445fa5657ebd91b9eda197ff0654c2402c5a` |
| Baseline commit message | `docs: establish local stable baseline instructions` |
| Baseline tag target | `264b445fa5657ebd91b9eda197ff0654c2402c5a` |
| Tag publication | Pushed to GitHub; remote annotated tag was verified to dereference to the baseline commit |
| Baseline origin | User-designated authoritative local stable repository snapshot, published to GitHub |
| Baseline purpose | Recovery, comparison, and controlled continuation |

The annotated tag is the immutable recovery reference. Do not move, delete, or recreate it. The baseline branch is retained as the named reference branch; new development must not be committed directly to it.

Repository links:
- [Baseline branch](https://github.com/atheertrading/AtheerAutotrade/tree/baseline/local-stable-v1)
- [Baseline commit](https://github.com/atheertrading/AtheerAutotrade/commit/264b445fa5657ebd91b9eda197ff0654c2402c5a)
- [Baseline tag](https://github.com/atheertrading/AtheerAutotrade/releases/tag/v1.0.0-baseline)

## 3. What the baseline means

The baseline preserves the repository tree at the commit above, including the existing application/backend source, engineering records, and repository working instructions present at that revision. It is a snapshot of the code and documentation actually committed at that point—not a claim that all previously discussed work, local-only changes, unmerged pull requests, or external project archives are included.

The baseline does not silently promote any draft branch or open pull request into the accepted implementation. A capability is considered implemented or verified only to the extent supported by the source, merged history, and recorded test/runtime evidence.

The baseline does not authorize:
- real-money trading or LIVE broker execution;
- bypassing the centralized Risk Engine or future OMS/Execution Gateway controls;
- changing broker credentials, accounts, or external trading settings;
- force-pushing, rewriting history, deleting branches/tags, or replacing existing implementation.

## 4. Branching and change-control rules

1. Keep `baseline/local-stable-v1` and `v1.0.0-baseline` unchanged.
2. Start each bounded milestone on a clearly named feature, fix, or documentation branch from the latest approved integration point. For recovery or baseline comparison, use the exact baseline tag/commit.
3. Do not develop directly on the baseline tag or baseline branch.
4. Preserve existing code and history. Prefer additive, incremental changes; no rebuild-from-scratch or wholesale replacement without a documented, reviewed technical necessity and owner approval.
5. Submit changes through a pull request. The PR must state scope, rationale, affected paths, dependencies, acceptance criteria, verification evidence, unresolved risks, and documentation updates.
6. Do not merge a PR, change the repository default branch, or alter protected/recovery references without the required review and owner authorization.
7. For each material implementation change, update the task register, implementation status, and continuity record as applicable. Add or update an ADR for consequential architecture decisions.
8. Record the exact commit SHA associated with every approved milestone and release.

## 5. Sequential version numbering

Use Semantic Versioning: `MAJOR.MINOR.PATCH`.

- **MAJOR** — incompatible public interfaces, architecture contracts, data formats, or migration changes requiring coordinated adoption.
- **MINOR** — backward-compatible product capabilities or significant additive functionality.
- **PATCH** — backward-compatible corrections, reliability/security fixes, and narrowly scoped maintenance.

The existing `v1.0.0-baseline` is the immutable baseline marker and a pre-release-style baseline label; it is not a production release or a declaration of production readiness.

The next release number must be selected from the actual accepted change set and release scope. Do not assign or publish a version merely because a branch or PR was created. Examples:
- `v1.0.0` — first qualified 1.0 release, only after its release gates are met;
- `v1.0.1` — compatible patch after 1.0.0;
- `v1.1.0` — compatible additive feature release;
- `v2.0.0` — approved breaking release.

For pre-release qualification, use SemVer identifiers such as `v1.1.0-alpha.1`, `v1.1.0-beta.1`, or `v1.1.0-rc.1`. Increment the pre-release identifier monotonically. Never reuse a published tag.

## 6. Release qualification and immutable records

A release tag may be created only for an approved milestone after:
- the pull request has been reviewed and merged to the approved integration branch;
- the documented acceptance criteria have been met;
- required CI/build/test results are recorded with links or run identifiers;
- target-machine, broker, security, packaging, and operational checks applicable to the release are explicitly classified as passed, failed, or pending;
- implementation status and continuity documentation match the shipped source;
- known limitations and owner approvals are recorded.

Create an annotated Git tag pointing to the exact approved commit. Publish a GitHub Release only when the owner-approved release process calls for one. Tags are immutable; corrections require a new version, not moving an old tag.

A release record must include:
- version and tag;
- exact commit SHA and target branch;
- milestone/PR references;
- summary of additions, fixes, and breaking changes;
- changed components and migration/compatibility notes;
- CI, build, test, security, and runtime evidence;
- known limitations, deferred work, and rollback/recovery reference;
- approval state and release date.

## 7. Recovery and rollback

To recover the preserved baseline, check out or branch from the exact commit `264b445fa5657ebd91b9eda197ff0654c2402c5a` or tag `v1.0.0-baseline`. Recovery should normally create a new branch; do not reset or force-update shared branches as a shortcut.

For a regression after a later release, prefer a reviewed revert or a forward fix. Keep the affected release tag and commit available for audit and comparison.

## 8. Initial baseline publication record

Verified actions recorded for this baseline:
- The local stable repository snapshot was committed on `baseline/local-stable-v1`.
- The branch was pushed to `origin/baseline/local-stable-v1`.
- Local and remote branch commit IDs were verified as `264b445fa5657ebd91b9eda197ff0654c2402c5a`.
- Annotated tag `v1.0.0-baseline` was created at that commit and pushed to GitHub.
- Remote tag verification confirmed the annotated tag resolves to the same commit.
- The baseline branch working tree was reported clean at the time of verification.
- No changes were made to `main`, and no existing feature branch was merged as part of baseline publication.

This record documents the baseline publication operation. It does not claim that a new Xcode build, backend test suite, broker connection, or live-trading validation was performed during that operation.

## 9. Maintenance

Update this policy only through a reviewed documentation change. Each later release must append its release evidence to the project release history or a dedicated release record, while preserving this original baseline record and tag.
