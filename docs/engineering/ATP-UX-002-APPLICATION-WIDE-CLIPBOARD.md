# ATP-UX-002 — Application-wide text selection and clipboard baseline

**Status:** Implemented on feature branch; target-macOS verification pending.  
**Owner requirement:** Text content throughout the application must be selectable and copyable; editable fields must preserve native paste behavior.

## Change

- Apply SwiftUI `.textSelection(.enabled)` at the root `NavigationSplitView` in `ApplicationShellView`.
- This removes the previous requirement to add selection modifiers to individual labels and values in each feature screen.
- Native editable controls (TextField, SecureField, and TextEditor) retain their standard macOS editing and paste behavior.
- The requirement is recorded beside the root modifier in source so future screens inherit the behavior.

## Acceptance checks on the target Mac

1. Select and copy text from Dashboard, sidebar, Brokers, Market Watch, Trading Workspace, and placeholder destinations.
2. Verify Command-C and the standard Edit > Copy action where text is selected.
3. Paste into editable TextField/SecureField controls using Command-V.
4. Confirm password fields remain secure and credentials are not exposed by copy affordances.
5. Confirm table values can be selected without interfering with row actions or resizing controls.

## Scope boundary

This change enables native text selection/copy and preserves native paste in editable controls. It does not add a custom clipboard history, copy buttons for every structured record, or programmatic access to secure credential values. Structured record copy/export actions will be added with their respective account/order/position screens.

## Change log

- 2026-11-13: Added application-root text selection to make copy behavior consistent across all current and future destinations.
