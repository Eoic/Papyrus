import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/acquisition/acquisition_action_sheets.dart';

void main() {
  testWidgets('command selection uses a sheet and returns the raw command', (tester) async {
    await tester.pumpWidget(const _ActionSheetLauncher());

    await tester.tap(find.text('Open commands'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('acquisition-command-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Readarr'), findsOneWidget);
    expect(find.text('Arr integration'), findsOneWidget);
    expect(find.text('Search monitored books'), findsOneWidget);
    expect(find.text('search'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNWidgets(2));

    await tester.tap(find.text('Search monitored books'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-command-sheet')), findsNothing);
    expect(find.text('command: search'), findsOneWidget);
  });

  testWidgets('command cancellation returns null', (tester) async {
    await tester.pumpWidget(const _ActionSheetLauncher());

    await tester.tap(find.text('Open commands'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('command: null'), findsOneWidget);
  });

  testWidgets('Arr ID entry is keyboard aware and parses valid comma-separated IDs', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const _ActionSheetLauncher());

    await tester.tap(find.text('Open IDs'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('acquisition-arr-ids-sheet'));
    final animatedPadding = find.descendant(of: sheet, matching: find.byType(AnimatedPadding));
    final keyboardInset = tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    expect(sheet, findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(animatedPadding, findsOneWidget);
    expect(tester.widget<AnimatedPadding>(animatedPadding).padding, EdgeInsets.only(bottom: keyboardInset));
    expect(find.text('Run Readarr command'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Run'), findsOneWidget);
    expect(find.text('IDs'), findsOneWidget);
    expect(find.text('Comma-separated IDs from the Arr application'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '42, invalid, 84');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Run'));
    expect(find.widgetWithText(FilledButton, 'Run').hitTestable(), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(find.text('ids: [42, 84]'), findsOneWidget);
  });

  testWidgets('Arr ID cancellation returns null', (tester) async {
    await tester.pumpWidget(const _ActionSheetLauncher());

    await tester.tap(find.text('Open IDs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('ids: null'), findsOneWidget);
  });

  testWidgets('removal uses a destructive sheet and returns true', (tester) async {
    await tester.pumpWidget(const _ActionSheetLauncher());

    await tester.tap(find.text('Open removal'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('acquisition-remove-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Remove Readarr?'), findsOneWidget);
    expect(find.text('Saved credentials for this integration will be removed.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    final removeFinder = find.widgetWithText(FilledButton, 'Remove');
    expect(removeFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(removeFinder);
    final colorScheme = Theme.of(tester.element(removeFinder)).colorScheme;
    expect(button.style?.backgroundColor?.resolve(<WidgetState>{}), colorScheme.error);
    expect(button.style?.foregroundColor?.resolve(<WidgetState>{}), colorScheme.onError);

    await tester.tap(removeFinder);
    await tester.pumpAndSettle();

    expect(find.text('remove: true'), findsOneWidget);
  });

  testWidgets('removal cancellation returns false', (tester) async {
    await tester.pumpWidget(const _ActionSheetLauncher());

    await tester.tap(find.text('Open removal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('remove: false'), findsOneWidget);
  });
}

class _ActionSheetLauncher extends StatefulWidget {
  const _ActionSheetLauncher();

  @override
  State<_ActionSheetLauncher> createState() => _ActionSheetLauncherState();
}

class _ActionSheetLauncherState extends State<_ActionSheetLauncher> {
  String _commandResult = 'not-set';
  String _idsResult = 'not-set';
  String _removeResult = 'not-set';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () async {
                  final result = await showAcquisitionCommandSheet(
                    context: context,
                    endpointName: 'Readarr',
                    endpointKindLabel: 'Arr integration',
                    commands: const ['refresh', 'search'],
                    commandLabel: (command) => switch (command) {
                      'refresh' => 'Refresh metadata',
                      'search' => 'Search monitored books',
                      _ => command,
                    },
                  );

                  if (mounted) {
                    setState(() => _commandResult = result ?? 'null');
                  }
                },
                child: const Text('Open commands'),
              ),
              FilledButton(
                onPressed: () async {
                  final result = await showAcquisitionIdsSheet(context: context, title: 'Run Readarr command');

                  if (mounted) {
                    setState(() => _idsResult = result?.toString() ?? 'null');
                  }
                },
                child: const Text('Open IDs'),
              ),
              FilledButton(
                onPressed: () async {
                  final result = await showAcquisitionRemoveSheet(context: context, endpointName: 'Readarr');

                  if (mounted) {
                    setState(() => _removeResult = result?.toString() ?? 'null');
                  }
                },
                child: const Text('Open removal'),
              ),
              Text('command: $_commandResult'),
              Text('ids: $_idsResult'),
              Text('remove: $_removeResult'),
            ],
          ),
        ),
      ),
    );
  }
}
