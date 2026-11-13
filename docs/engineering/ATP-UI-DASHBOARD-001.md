# ATP-UI-DASHBOARD-001 — Operational Dashboard

**Status:** IMPLEMENTED ON FEATURE BRANCH — TARGET-MAC BUILD AND RUNTIME VERIFICATION PENDING  
**Branch:** `feat/atp-dashboard-001-operational-dashboard`  
**Base:** `main`  
**Scope:** Native macOS Dashboard presentation only.

## Objective

Replace the former service-status-first Dashboard with an operational trading overview that makes the current implementation state visible without inventing account values, risk values, database readiness, or activity events.

## Implemented

- Reorganized the Dashboard into Account Overview, Market Watch, Operational Status, and System Activity.
- Added responsive adaptive metric and service panels using native SwiftUI layout primitives.
- Preserved the existing `MarketWatchTableView(compact: true)` consumer and its MarketDataStore source; no broker connection or quote subscription code was changed.
- Displayed account Balance, Equity, Available Margin, and Open Exposure as unavailable, with explicit explanations because account snapshots are not yet connected to this view.
- Displayed Capital.com Demo session and market-stream state from the existing MarketDataStore.
- Explicitly marked automated execution disabled and identified the missing OMS/RiskEngine/Execution integration.
- Explicitly marked local PostgreSQL as not connected because the application runtime repositories are not yet integrated.
- Replaced the misleading empty activity state with a clear statement that the event stream is not yet connected.
- Enabled text selection across the Dashboard view. The application root also retains its merged application-wide text-selection modifier.

## Preserved

- Capital.com authentication, credential handling, Keychain storage, backend process supervision, IPC, and market-data subscription.
- MarketDataStore ownership and quote display path.
- Existing DesignSystem colors, spacing, and radius tokens.
- Existing app navigation and Xcode project file membership. No new Swift source file was introduced.

## Not included

- Account snapshot service wiring.
- PostgreSQL server installation, database creation, migrations, or runtime persistence.
- OMS, RiskEngine authorization integration, broker dealing, or order submission.
- Market-data ordering/deduplication/OHLC persistence changes.
- Claims of Xcode build success or target-Mac visual verification.

## Acceptance criteria

1. Build the macOS target using the repository's supported Xcode toolchain.
2. Open Dashboard and verify the new four-section layout at both default and resized window dimensions.
3. Verify the Market Watch compact table continues to display the same broker quote observations.
4. Verify connected/disconnected and streaming/not-streaming states change with MarketDataStore.
5. Verify unavailable account/database/activity states are clearly labeled and no synthetic financial values are shown.
6. Verify Dashboard text can be selected and copied; verify editable fields elsewhere retain native paste/edit behavior.
7. Confirm no Capital.com connection or credential path changed.

## Change record

- `apps/macos/Sources/Features/Dashboard/DashboardView.swift` — operational Dashboard redesign.
- `docs/engineering/ATP-UI-DASHBOARD-001.md` — implementation and verification record.

**Versioning:** This is an additive feature-branch change. The prior `main` version remains retrievable through Git history. No release tag is created until the change is reviewed, merged, and verified on the target Mac.
