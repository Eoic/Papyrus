# Book Import Drop Zone Design

## Goal

Replace the current compact purple file-picker panel with a responsive Material 3 drop zone that fills the available sheet body, supports real file dropping on web and desktop, and retains picker-based selection everywhere.

## Visual Design

The empty-state body contains one large drop zone inset by `Spacing.lg` on every side. It expands to fill the space between the sheet header and footer and uses the same structure on mobile and desktop.

At rest, the drop zone has no colored fill. A rounded dashed border uses `colorScheme.outlineVariant`, with a 16px-equivalent application radius. Centered content contains:

1. A primary-colored upload icon.
2. A `titleMedium` instruction.
3. Supported formats in `bodyMedium` using `onSurfaceVariant`.
4. An outlined **Browse files** button with a folder/upload icon.

Desktop and web show **Drag and drop book files here**. Android and iOS show **Choose book files**. Both show **EPUB, PDF, MOBI, AZW3, TXT, CBR, and CBZ** and the same **Browse files** action.

Hover and keyboard focus add a subtle neutral state layer. While files are dragged over the target, the dashed border and icon change to `primary` and the background receives a faint `primaryContainer` tint. Picking state replaces the icon with a progress indicator and disables repeated activation.

## Interaction and Data Flow

`desktop_drop` supplies drop-entered, drop-exited, and drop-completed events on web, Windows, macOS, and Linux. Mobile keeps the identical visual structure but uses the picker only.

Dropped entries are filtered by the same supported extension list as the picker. Supported files are read asynchronously into `SelectedBookFile` values and replace the drop zone with the existing selected-file list. The existing reset, remove, cancel, and import behavior remains unchanged.

Unsupported-only drops leave the drop zone visible and show **No supported book files were dropped.** If a mixed drop contains supported and unsupported entries, supported files are selected and an inline warning explains that unsupported files were skipped. Supported files that cannot be read appear in the existing unreadable-file state.

The controller receives dropped selections through a small public command rather than depending on `desktop_drop`; platform file conversion stays at the widget boundary.

## Components

- `BookImportSelectingSection` continues to choose between the empty drop zone and selected-file list.
- A focused stateful drop-zone widget owns hover, focus, drag-active, and file-reading presentation state.
- A small custom painter draws the dashed rounded border, avoiding a second visual dependency.
- `BookImportController` accepts dropped selections and optional picker/drop feedback using the same selection state already used by browsing.

## Accessibility

The entire drop zone remains tappable/clickable, exposes button semantics, supports keyboard activation, and retains a visible focused state. The explicit **Browse files** button avoids relying on drag-and-drop discovery. State changes use both border and background/icon changes rather than color alone.

## Testing

Add focused widget/controller coverage for:

- the drop zone filling the available body;
- desktop and mobile instruction copy;
- drag-active visual state;
- supported dropped files replacing the empty state;
- unsupported drops showing inline feedback;
- picker behavior and the existing selected-file list remaining intact.

Run formatting, whole-app analysis, and the add-book widget test suite.

## Non-goals

- Changing the selected-file cards or footer layout.
- Keeping the large drop zone visible after selection.
- Changing import processing, persistence, supported formats, or concurrency.
