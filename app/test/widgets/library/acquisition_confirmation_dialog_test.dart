import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/library/acquisition_confirmation_dialog.dart';

void main() {
  testWidgets('uses the shelf-style destructive confirmation and returns true', (tester) async {
    await tester.pumpWidget(const _ConfirmationLauncher());

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Cancel downloads'), findsNWidgets(2));
    expect(find.text('Cancel 2 selected downloads?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    final destructiveAction = find.widgetWithText(FilledButton, 'Cancel downloads');
    final button = tester.widget<FilledButton>(destructiveAction);
    final colorScheme = Theme.of(tester.element(destructiveAction)).colorScheme;

    expect(button.style?.backgroundColor?.resolve(<WidgetState>{}), colorScheme.error);

    await tester.tap(destructiveAction);
    await tester.pumpAndSettle();

    expect(find.text('confirmed: true'), findsOneWidget);
  });

  testWidgets('returns false when the confirmation is cancelled', (tester) async {
    await tester.pumpWidget(const _ConfirmationLauncher());

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('confirmed: false'), findsOneWidget);
  });
}

class _ConfirmationLauncher extends StatefulWidget {
  const _ConfirmationLauncher();

  @override
  State<_ConfirmationLauncher> createState() => _ConfirmationLauncherState();
}

class _ConfirmationLauncherState extends State<_ConfirmationLauncher> {
  bool? _confirmed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () async {
                  final confirmed = await showAcquisitionConfirmationDialog(
                    context: context,
                    title: 'Cancel downloads',
                    message: 'Cancel 2 selected downloads?',
                    actionLabel: 'Cancel downloads',
                  );

                  if (mounted) {
                    setState(() => _confirmed = confirmed);
                  }
                },
                child: const Text('Open confirmation'),
              ),
              Text('confirmed: $_confirmed'),
            ],
          ),
        ),
      ),
    );
  }
}
