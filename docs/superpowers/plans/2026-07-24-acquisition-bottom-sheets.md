# Acquisition Bottom Sheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every dialog-style acquisition overlay with a Papyrus-styled bottom sheet without changing acquisition behavior.

**Architecture:** Keep the endpoint form in its focused widget and make its launcher use one bottom-sheet path at every width. Add a focused acquisition action-sheets module for command selection, Arr ID entry, and removal confirmation, then keep the page methods thin by delegating presentation to those helpers.

**Tech Stack:** Flutter, Material 3, Provider-backed acquisition page, `flutter_test`

---

## File Map

- Modify `app/lib/widgets/acquisition/acquisition_endpoint_editor.dart` to remove the wide-screen dialog branch.
- Modify `app/test/widgets/acquisition/acquisition_endpoint_editor_test.dart` to require the same sheet behavior at phone and desktop widths.
- Create `app/lib/widgets/acquisition/acquisition_action_sheets.dart` for command, ID-entry, and remove-confirmation sheets.
- Create `app/test/widgets/acquisition/acquisition_action_sheets_test.dart` for direct sheet behavior and keyboard-layout tests.
- Modify `app/lib/pages/acquisition_page.dart` to delegate all auxiliary overlays to the new sheet helpers.
- Modify `app/test/pages/acquisition_page_test.dart` to prove page triggers and API results remain wired correctly.

### Task 1: Use the Integration Editor Sheet at Every Width

**Files:**
- Modify: `app/test/widgets/acquisition/acquisition_endpoint_editor_test.dart`
- Modify: `app/lib/widgets/acquisition/acquisition_endpoint_editor.dart`

- [ ] **Step 1: Replace the wide-dialog expectation with a failing wide-sheet test**

Replace the current `uses a constrained dialog on wide windows` test with:

```dart
testWidgets('uses the same bottom sheet on wide windows', (tester) async {
  await _setWindowSize(tester, const Size(900, 900));
  await tester.pumpWidget(const _EditorLauncher());

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  final sheet = find.byKey(const Key('acquisition-endpoint-sheet'));
  expect(sheet, findsOneWidget);
  expect(find.byKey(const Key('acquisition-endpoint-dialog')), findsNothing);
  expect(
    find.descendant(
      of: sheet,
      matching: find.byWidgetPredicate(
        (widget) => widget is FractionallySizedBox && widget.heightFactor == .92,
      ),
    ),
    findsOneWidget,
  );
  expect(find.ancestor(of: sheet, matching: find.byType(SafeArea)), findsOneWidget);
});
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
cd app
flutter test --no-pub test/widgets/acquisition/acquisition_endpoint_editor_test.dart \
  --plain-name "uses the same bottom sheet on wide windows"
```

Expected: FAIL because a 900-pixel window still renders `acquisition-endpoint-dialog`.

- [ ] **Step 3: Remove the responsive dialog branch**

Replace the body of `showAcquisitionEndpointEditor` after the `editor` assignment with one bottom-sheet return:

```dart
return showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  useSafeArea: true,
  showDragHandle: false,
  builder: (context) => KeyedSubtree(
    key: const Key('acquisition-endpoint-sheet'),
    child: AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: .92,
        child: editor,
      ),
    ),
  ),
);
```

Delete the `MediaQuery.sizeOf(context).width < Breakpoints.tablet` condition and the `showDialog` branch. Keep all form state, validation, busy-state `PopScope`, callbacks, and keys unchanged.

- [ ] **Step 4: Run the editor suite and verify GREEN**

Run:

```bash
cd app
flutter test --no-pub test/widgets/acquisition/acquisition_endpoint_editor_test.dart
```

Expected: all editor tests pass, including phone and desktop sheet rendering and pending-operation dismissal protection.

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/acquisition/acquisition_endpoint_editor.dart \
  app/test/widgets/acquisition/acquisition_endpoint_editor_test.dart
git commit -m "fix: use acquisition editor sheet on every screen"
```

### Task 2: Add Focused Acquisition Action Sheets

**Files:**
- Create: `app/lib/widgets/acquisition/acquisition_action_sheets.dart`
- Create: `app/test/widgets/acquisition/acquisition_action_sheets_test.dart`

- [ ] **Step 1: Write failing tests for the three sheet helpers**

Create `app/test/widgets/acquisition/acquisition_action_sheets_test.dart` with a `MaterialApp` launcher and these behaviors:

```dart
testWidgets('command selection uses a titled bottom sheet', (tester) async {
  String? selected;
  await tester.pumpWidget(
    _SheetLauncher(
      onOpen: (context) async {
        selected = await showAcquisitionCommandSheet(
          context: context,
          endpointName: 'Readarr',
          endpointKindLabel: 'Readarr',
          commands: const ['BookSearch'],
          commandLabel: (_) => 'Search books',
        );
      },
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('acquisition-command-sheet')), findsOneWidget);
  expect(find.byType(Dialog), findsNothing);
  expect(find.text('Readarr'), findsOneWidget);

  await tester.tap(find.text('Search books'));
  await tester.pumpAndSettle();
  expect(selected, 'BookSearch');
});

testWidgets('Arr IDs use a keyboard-aware form sheet', (tester) async {
  List<int>? ids;
  await tester.pumpWidget(
    _SheetLauncher(
      onOpen: (context) async {
        ids = await showAcquisitionIdsSheet(
          context: context,
          title: 'Search books',
        );
      },
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  final sheet = find.byKey(const Key('acquisition-arr-ids-sheet'));
  expect(sheet, findsOneWidget);
  expect(find.byType(AlertDialog), findsNothing);
  expect(find.descendant(of: sheet, matching: find.byType(AnimatedPadding)), findsOneWidget);

  await tester.enterText(find.widgetWithText(TextField, 'IDs'), '42, invalid, 84');
  await tester.tap(find.widgetWithText(FilledButton, 'Run'));
  await tester.pumpAndSettle();
  expect(ids, [42, 84]);
});

testWidgets('remove confirmation uses a destructive bottom sheet', (tester) async {
  bool? confirmed;
  await tester.pumpWidget(
    _SheetLauncher(
      onOpen: (context) async {
        confirmed = await showAcquisitionRemoveSheet(
          context: context,
          endpointName: 'Prowlarr',
        );
      },
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('acquisition-remove-sheet')), findsOneWidget);
  expect(find.byType(AlertDialog), findsNothing);
  expect(find.text('Saved credentials for this integration will be removed.'), findsOneWidget);

  await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
  await tester.pumpAndSettle();
  expect(confirmed, isTrue);
});
```

Define `_SheetLauncher` as a small stateless test widget that accepts `Future<void> Function(BuildContext)` and calls it from an `Open` button.

- [ ] **Step 2: Run the new test file and verify RED**

Run:

```bash
cd app
flutter test --no-pub test/widgets/acquisition/acquisition_action_sheets_test.dart
```

Expected: compilation fails because the action-sheet helpers do not exist.

- [ ] **Step 3: Implement the action-sheet module**

Create `app/lib/widgets/acquisition/acquisition_action_sheets.dart` with these public APIs:

```dart
typedef AcquisitionCommandLabel = String Function(String command);

Future<String?> showAcquisitionCommandSheet({
  required BuildContext context,
  required String endpointName,
  required String endpointKindLabel,
  required List<String> commands,
  required AcquisitionCommandLabel commandLabel,
});

Future<List<int>?> showAcquisitionIdsSheet({
  required BuildContext context,
  required String title,
});

Future<bool?> showAcquisitionRemoveSheet({
  required BuildContext context,
  required String endpointName,
});
```

Implement the command selector with `showModalBottomSheet<String>`, `useSafeArea: true`, key `acquisition-command-sheet`, `BottomSheetHandle`, `BottomSheetHeader` with no save action, and the existing command `ListTile` rows:

```dart
return showModalBottomSheet<String>(
  context: context,
  useSafeArea: true,
  builder: (sheetContext) => Padding(
    key: const Key('acquisition-command-sheet'),
    padding: const EdgeInsets.all(Spacing.md),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: Spacing.md),
        BottomSheetHeader(
          title: endpointName,
          onCancel: () => Navigator.pop(sheetContext),
        ),
        Text(endpointKindLabel),
        const SizedBox(height: Spacing.sm),
        for (final command in commands)
          ListTile(
            leading: const Icon(Icons.play_arrow_outlined),
            title: Text(commandLabel(command)),
            subtitle: Text(command),
            onTap: () => Navigator.pop(sheetContext, command),
          ),
      ],
    ),
  ),
);
```

Implement the ID form with `showModalBottomSheet<List<int>>`, `isScrollControlled: true`, `useSafeArea: true`, an `AnimatedPadding` using `MediaQuery.viewInsetsOf(sheetContext).bottom`, key `acquisition-arr-ids-sheet`, `BottomSheetHandle`, and `BottomSheetHeader(saveLabel: 'Run')`. Keep `enteredIds` as a local string updated by `TextField.onChanged`, and parse it with:

```dart
final ids = enteredIds
    .split(',')
    .map((value) => int.tryParse(value.trim()))
    .whereType<int>()
    .toList();
Navigator.pop(sheetContext, ids);
```

Implement removal with `showModalBottomSheet<bool>`, `useSafeArea: true`, key `acquisition-remove-sheet`, `BottomSheetHandle`, the exact warning copy, Cancel, and a `FilledButton` styled from the current color scheme:

```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: colorScheme.error,
    foregroundColor: colorScheme.onError,
  ),
  onPressed: () => Navigator.pop(sheetContext, true),
  child: const Text('Remove'),
)
```

- [ ] **Step 4: Run the new test suite and verify GREEN**

Run:

```bash
cd app
flutter test --no-pub test/widgets/acquisition/acquisition_action_sheets_test.dart
```

Expected: all command, ID, cancellation, and removal sheet tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/acquisition/acquisition_action_sheets.dart \
  app/test/widgets/acquisition/acquisition_action_sheets_test.dart
git commit -m "feat: add acquisition action sheets"
```

### Task 3: Route Acquisition Page Overlays Through Sheets

**Files:**
- Modify: `app/lib/pages/acquisition_page.dart`
- Modify: `app/test/pages/acquisition_page_test.dart`

- [ ] **Step 1: Add failing page-level overlay tests**

Extend `_FakeAcquisitionApiClient` with:

```dart
final deletedEndpointIds = <String>[];

@override
Future<void> deleteEndpoint({
  required String accessToken,
  required String endpointId,
}) async {
  deletedEndpointIds.add(endpointId);
}
```

In the active Arr flow test, after selecting `Run action`, assert the command and ID overlays use the new keys and no dialogs:

```dart
expect(find.byKey(const Key('acquisition-command-sheet')), findsOneWidget);
expect(find.byType(AlertDialog), findsNothing);

await tester.tap(find.text('Search books'));
await tester.pumpAndSettle();

expect(find.byKey(const Key('acquisition-arr-ids-sheet')), findsOneWidget);
expect(find.byType(AlertDialog), findsNothing);
```

Add a removal test:

```dart
testWidgets('remove action confirms through a bottom sheet', (tester) async {
  final apiClient = _FakeAcquisitionApiClient()
    ..endpointsResult = [_indexerOne];

  await tester.pumpWidget(await _buildPage(apiClient));
  await tester.pumpAndSettle();

  _selectEndpointMenu(tester, _indexerOne, 'delete');
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('acquisition-remove-sheet')), findsOneWidget);
  expect(find.byType(AlertDialog), findsNothing);

  await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
  await tester.pumpAndSettle();

  expect(apiClient.deletedEndpointIds, ['indexer-1']);
});
```

- [ ] **Step 2: Run the page tests and verify RED**

Run:

```bash
cd app
flutter test --no-pub test/pages/acquisition_page_test.dart
```

Expected: FAIL because Arr IDs and removal still use `AlertDialog`, and the expected sheet keys are absent.

- [ ] **Step 3: Delegate the page methods to the new helpers**

Import:

```dart
import 'package:papyrus/widgets/acquisition/acquisition_action_sheets.dart';
```

Replace `_pickArrCommand` with:

```dart
Future<String?> _pickArrCommand(
  AcquisitionEndpoint endpoint,
  List<String> commands,
) {
  return showAcquisitionCommandSheet(
    context: context,
    endpointName: endpoint.name,
    endpointKindLabel: endpoint.kind.label,
    commands: commands,
    commandLabel: _arrCommandLabel,
  );
}
```

Replace `_askForIds` with:

```dart
Future<List<int>?> _askForIds(String command) {
  return showAcquisitionIdsSheet(
    context: context,
    title: _arrCommandLabel(command),
  );
}
```

Replace the confirmation creation at the start of `_deleteEndpoint` with:

```dart
final confirmed = await showAcquisitionRemoveSheet(
  context: context,
  endpointName: endpoint.name,
);
```

Keep the `confirmed != true` guard, authenticated delete, reload, and snackbar error handling unchanged.

- [ ] **Step 4: Run page and focused acquisition tests**

Run:

```bash
cd app
flutter test --no-pub \
  test/pages/acquisition_page_test.dart \
  test/widgets/acquisition/acquisition_action_sheets_test.dart \
  test/widgets/acquisition/acquisition_endpoint_editor_test.dart \
  test/widgets/acquisition/acquisition_settings_section_test.dart
```

Expected: all focused acquisition tests pass with no dialog-based acquisition overlays.

- [ ] **Step 5: Commit**

```bash
git add app/lib/pages/acquisition_page.dart \
  app/test/pages/acquisition_page_test.dart
git commit -m "fix: use sheets for acquisition actions"
```

### Task 4: Final Verification of the Full Flutter Suite

**Files:**
- Verify all changed production and test files.

- [ ] **Step 1: Check formatting**

Run:

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
```

Expected: exit 0 and zero changed files.

- [ ] **Step 2: Run the analyzer**

Run:

```bash
cd app
flutter analyze --no-pub
```

Expected: `No issues found!`

- [ ] **Step 3: Run the focused UI suite**

Run:

```bash
cd app
flutter test --no-pub \
  test/pages/profile_storage_sync_test.dart \
  test/pages/acquisition_page_test.dart \
  test/widgets/acquisition/acquisition_action_sheets_test.dart \
  test/widgets/acquisition/acquisition_endpoint_editor_test.dart \
  test/widgets/acquisition/acquisition_settings_section_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 4: Run the complete Flutter suite**

Run:

```bash
cd app
flutter test --no-pub
```

Expected: all non-skipped tests pass.

- [ ] **Step 5: Verify repository state**

Run:

```bash
git diff --check
git status --short --branch
```

Expected: no whitespace errors and a clean `feature/torrent-acquisition` branch containing only the planned commits.
