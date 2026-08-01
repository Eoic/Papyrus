# Shelf Page Heading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the shelf books toolbar-like identity row with a compact, responsive page heading that keeps the shelf icon, title, description, and edit action visually grouped.

**Architecture:** Keep the change inside the shelf variant of `LibraryPage`. Pass an explicit compact flag from the existing mobile and desktop header builders, and let `_buildShelfIdentity` render one shared semantic structure with breakpoint-specific typography and edit controls. Search, chips, grid, navigation, filtering, and provider behavior remain unchanged.

**Tech Stack:** Flutter, Dart, Material 3, existing Papyrus design tokens

---

### Task 1: Restructure the shelf identity as a page heading

**Files:**
- Modify: `app/lib/pages/library_page.dart:277-301`
- Modify: `app/lib/pages/library_page.dart:714-765`
- Test: none, per the established request not to add or modernize tests for this work

- [ ] **Step 1: Distinguish the mobile and desktop heading treatments**

Update the two shelf-only call sites so mobile requests the compact treatment and desktop requests the full treatment:

```dart
_buildShelfIdentity(context, showBack: true, compact: true)
```

```dart
_buildShelfIdentity(context, showBack: true, compact: false)
```

Do not change the surrounding search row, Add to shelf action, chips, or selection-mode branching.

- [ ] **Step 2: Replace the toolbar-like identity row**

Change the helper signature and build a constrained content column after the existing Back and shelf-icon controls:

```dart
Widget _buildShelfIdentity(
  BuildContext context, {
  required bool showBack,
  required bool compact,
}) {
  final shelf = widget.shelf!;
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final description = shelf.description?.trim();
  final titleStyle = compact ? textTheme.titleLarge : textTheme.headlineSmall;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showBack && widget.onBack != null)
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to shelves',
        ),
      Padding(
        padding: const EdgeInsets.only(top: Spacing.sm),
        child: Icon(
          shelf.displayIcon,
          size: IconSizes.medium,
          color: shelf.color ?? colorScheme.primary,
        ),
      ),
      const SizedBox(width: Spacing.md),
      Flexible(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      shelf.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (widget.onEditShelf != null) ...[
                    const SizedBox(width: Spacing.sm),
                    if (compact)
                      IconButton(
                        onPressed: widget.onEditShelf,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit shelf',
                      )
                    else
                      TextButton.icon(
                        onPressed: widget.onEditShelf,
                        icon: const Icon(Icons.edit_outlined, size: IconSizes.small),
                        label: const Text('Edit'),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                description == null || description.isEmpty
                    ? 'Add a description'
                    : description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
```

Preserve this structure and the listed token-sized spacing. Do not add a background, border, shadow, icon container, or additional action.

- [ ] **Step 3: Format and run targeted static analysis**

Run:

```bash
dart format app/lib/pages/library_page.dart
flutter analyze app/lib/pages/library_page.dart app/lib/pages/shelf_contents_page.dart
```

Expected: formatting completes successfully and analysis reports `No issues found!`.

- [ ] **Step 4: Manually verify the responsive heading**

Check desktop and mobile/narrow layouts and confirm:

- the title uses page-heading typography;
- Edit stays within the constrained title block rather than at the viewport edge;
- the description aligns with the title, wraps to at most two lines, and ellipsizes;
- the missing-description prompt still appears;
- Back and Edit retain tooltips and accessible touch targets;
- the main Books header is unchanged;
- search, chips, grid, selection mode, and Add to shelf do not move or change behavior beyond the intentional heading-height adjustment.

- [ ] **Step 5: Check the diff and commit**

Run:

```bash
git diff --check
git diff -- app/lib/pages/library_page.dart
git add app/lib/pages/library_page.dart
git commit -m "PPR-25: Refine shelf page heading"
```

Expected: one focused production-file commit with no unrelated changes.
