# Advanced Filter Sheet Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Advanced filters use the standard Papyrus bottom-sheet width and consistent 24px horizontal content insets.

**Architecture:** Keep the change entirely inside `LibraryAdvancedFilterSheet`. Remove its modal-level custom width override so Flutter’s shared Material sheet constraints match other sheets, then update only the outer horizontal padding for the header, scrollable body, and sticky footer.

**Tech Stack:** Flutter, Dart, Material 3, Papyrus design tokens

---

### Task 1: Align advanced-filter sheet sizing and content insets

**Files:**
- Modify: `app/lib/widgets/library/library_advanced_filter_sheet.dart:34-77`
- Modify: `app/lib/widgets/library/library_advanced_filter_sheet.dart:200-350`
- Test: none, following the established request not to add or modernize tests for this feature work

- [ ] **Step 1: Remove the custom desktop width override**

Delete the locally calculated 760px maximum width:

```dart
final maxWidth = MediaQuery.sizeOf(context).width.clamp(0, 760).toDouble();
```

Remove this argument from `showModalBottomSheet`:

```dart
constraints: BoxConstraints(maxWidth: maxWidth),
```

Keep `useRootNavigator`, `useSafeArea`, `isScrollControlled`, the transparent background, draggable sizes, snapping, decorated surface, clipping, and border radius unchanged.

- [ ] **Step 2: Increase all outer horizontal insets to `Spacing.lg`**

Change the scrollable filter-body padding to:

```dart
padding: const EdgeInsets.fromLTRB(
  Spacing.lg,
  Spacing.sm,
  Spacing.lg,
  Spacing.xl,
),
```

Change the header padding to:

```dart
padding: const EdgeInsets.fromLTRB(
  Spacing.lg,
  Spacing.md,
  Spacing.lg,
  Spacing.md,
),
```

Change the sticky action-bar padding to:

```dart
padding: const EdgeInsets.symmetric(
  horizontal: Spacing.lg,
  vertical: Spacing.md,
),
```

Do not modify padding internal to individual facet cards, search fields, chips, date controls, or range controls.

- [ ] **Step 3: Format and run targeted static analysis**

Run:

```bash
dart format app/lib/widgets/library/library_advanced_filter_sheet.dart
flutter analyze \
  app/lib/widgets/library/library_advanced_filter_sheet.dart \
  app/lib/pages/library_page.dart
```

Expected: formatting succeeds and analysis reports `No issues found!`.

- [ ] **Step 4: Verify responsive sheet behavior**

Confirm through code inspection and the running app where available:

- desktop width matches standard bottom sheets such as the book context menu;
- mobile still uses the available width;
- header title, body sections, and footer actions share 24px left/right edges;
- the narrower desktop sheet does not overflow facet controls or footer actions;
- dragging, snapping, scrolling, header/footer persistence, close, reset, cancel, preview count, and apply behavior are unchanged.

- [ ] **Step 5: Check the diff and commit**

Run:

```bash
git diff --check
git diff -- app/lib/widgets/library/library_advanced_filter_sheet.dart
git add app/lib/widgets/library/library_advanced_filter_sheet.dart
git commit -m "PPR-25: Align advanced filter sheet sizing"
```

Expected: one focused production-file commit with no unrelated changes.
