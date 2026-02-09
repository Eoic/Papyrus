# Fix: File Import Sheet Layout

## Problem
The `file_import_sheet.dart` `build()` method uses `CustomScrollView` + slivers which is
broken inside `DraggableScrollableSheet`:
- Unconstrained cross-axis width during initialization causes `OutlinedButton` crash
- `LayoutBuilder` guard means footer buttons sometimes never appear
- Previous attempt to switch to `ListView` caused modal height to shrink and elements to spill

## Root Cause
`DraggableScrollableSheet` passes unconstrained constraints during its first layout frame.
`SliverFillRemaining` + Material widgets with intrinsic width (like `OutlinedButton`) crash.

## Approach: TDD
1. Write widget tests that render `_ImportContent` in all 3 states (picking, processing, review)
   inside realistic constraints (both mobile DraggableScrollableSheet and desktop Dialog)
2. See tests fail against the current broken layout
3. Fix the layout to make tests pass
4. Refactor if needed

## Key Decisions
- Made `_ImportContent` public as `ImportContent` with `@visibleForTesting`
- Added `autoPick` param to skip file picker in tests
- Added `setTestState()` to `AddBookProvider` for setting internal state in tests
- No mocking library needed — pre-configure provider state directly

## Test Strategy
- Render `ImportContent` inside `DraggableScrollableSheet` (mobile) and `ConstrainedBox` (desktop)
- For each state (picking, processing, review), provide a pre-configured `AddBookProvider`
- Use `tester.scrollUntilVisible()` to verify footer buttons are reachable by scrolling
- Assert: no exceptions, expected widgets present, footer buttons visible

## Findings During TDD
- `ListView(shrinkWrap: true)` for desktop was wrong: when expanded card metadata form
  exceeds the `ConstrainedBox(maxHeight)`, content gets clipped and footer buttons disappear
- Fix: remove `shrinkWrap` entirely — `ListView` fills the bounded height from the parent
  `ConstrainedBox` and scrolls. Works for both mobile (DraggableScrollableSheet gives bounds)
  and desktop (Dialog's ConstrainedBox gives bounds)
- `ListView` lazily builds children — `skipOffstage: false` doesn't help find unbuilt children.
  Use `scrollUntilVisible` to scroll to the footer before asserting
- Card's date field suffix (2 IconButtons) causes 10px overflow on narrow (400px) viewports —
  pre-existing bug unrelated to this fix, tested with 420px width to avoid
