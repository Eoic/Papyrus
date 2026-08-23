# Book Import Drop Zone Implementation Plan

> Execute inline in the current feature worktree. Keep all changes uncommitted.

**Goal:** Replace the compact purple picker panel with a full-body Material 3 drop zone that supports real desktop/web drag-and-drop while preserving picker and import behavior.

**Architecture:** Keep dropped-file conversion at the widget boundary. A focused `BookImportDropZone` owns hover, focus, drag, and file-read state; it emits framework-neutral `SelectedBookFile` values and feedback to `BookImportController` through a small public command. `BookImportSelectingSection` continues to swap the empty state for the existing selected-file list.

**Tech:** Flutter Material 3, `desktop_drop`, `file_picker`, widget tests, controller unit tests.

---

## Task 1: Define dropped-selection controller behavior

**Files:**
- Modify: `app/test/widgets/add_book/book_import_controller_test.dart`
- Modify: `app/lib/widgets/add_book/book_import_controller.dart`

1. Add a failing controller test which calls the wished-for API:

```dart
controller.applyDroppedFiles(
  [SelectedBookFile(name: 'book.epub', bytes: Uint8List.fromList([1]))],
  feedback: 'Some files were skipped because their format is not supported.',
);

expect(controller.files.single.name, 'book.epub');
expect(controller.pickerError, contains('skipped'));
```

2. Run `flutter test test/widgets/add_book/book_import_controller_test.dart` from `app/` and confirm it fails because `applyDroppedFiles` does not exist.
3. Implement the minimal controller command. It must ignore calls after disposal, store an unmodifiable non-empty selection, and allow feedback without replacing the current empty state:

```dart
void applyDroppedFiles(List<SelectedBookFile> files, {String? feedback}) {
  if (_disposed) return;
  _update(() {
    if (files.isNotEmpty) _files = List.unmodifiable(files);
    _pickerError = feedback;
  });
}
```

4. Re-run the focused test and confirm it passes.

## Task 2: Add and test the Material 3 drop-zone widget

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `app/pubspec.lock` via `flutter pub get`
- Create: `app/lib/widgets/add_book/book_import_drop_zone.dart`
- Modify: `app/test/widgets/add_book/book_import_sheet_test.dart`

1. Add failing widget tests for the public drop-zone surface:
   - desktop copy is `Drag and drop book files here`;
   - mobile copy is `Choose book files`;
   - supported-format copy and `Browse files` remain visible;
   - invoking the drop conversion callback with supported and unsupported entries produces selected files plus inline feedback.
2. Run the focused widget test and confirm failure because `BookImportDropZone` does not exist.
3. Add `desktop_drop: ^0.8.0` with `apply_patch`, run `flutter pub get`, and inspect the installed package API before coding against it.
4. Implement `BookImportDropZone` as a stateful widget:
   - fill parent constraints;
   - transparent rest surface and dashed `outlineVariant` rounded border;
   - primary upload icon, `titleMedium` instruction, `bodyMedium` formats, outlined browse button;
   - hover/focus neutral state layer and visible focus border;
   - drag-over primary border, primary icon, and faint `primaryContainer` tint;
   - disabled browse activation and progress indicator while picking or reading drops;
   - keyboard activation through standard Flutter focus/actions;
   - desktop/web drop support only, with mobile retaining the identical picker layout;
   - async parallel reads of supported entries, unreadable entries represented with `bytes: null`;
   - exact unsupported-only feedback `No supported book files were dropped.` and a mixed-drop skipped warning.
5. Implement a private custom painter using `PathMetric.extractPath` to draw the rounded dashed border without another visual package.
6. Run the focused widget test and confirm it passes.

## Task 3: Wire the drop zone into the selecting section

**Files:**
- Modify: `app/lib/widgets/add_book/book_import_sheet_sections.dart`
- Modify: `app/lib/widgets/add_book/book_import_sheet.dart`
- Modify: `app/test/widgets/add_book/book_import_sheet_test.dart`

1. Add a failing sheet test proving the empty-state drop zone expands within `Spacing.lg` body insets and that a delivered dropped selection replaces it with the existing file list.
2. Replace `_BrowseArea` with `Expanded(child: BookImportDropZone(...))` inside an all-sides `Spacing.lg` inset. Keep error feedback adjacent and preserve the selected-file list unchanged.
3. Add `onDroppedFiles` to `BookImportSelectingSection` and wire it to `BookImportController.applyDroppedFiles` from `BookImportSheet`.
4. Run `flutter test test/widgets/add_book/book_import_sheet_test.dart` and fix only regressions caused by the new design.

## Task 4: Verify and review

**Files:** all modified files above.

1. Run `dart format` on modified Dart files.
2. Run `flutter analyze` from `app/`; expect no issues.
3. Run `flutter test test/widgets/add_book`; expect the add-book suite to pass.
4. Run `git diff --check` and inspect `git diff --stat` plus the focused upload-zone diff.
5. Review light/dark semantic colors, keyboard focus, 48dp touch targets, loading feedback, and narrow-window text wrapping against the approved design. Leave the result uncommitted.
