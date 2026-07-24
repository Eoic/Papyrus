import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/acquisition/guarded_bottom_sheet_route.dart';

void main() {
  testWidgets('route follows the live busy state', (tester) async {
    final busy = ValueNotifier(false);
    addTearDown(busy.dispose);
    await tester.pumpWidget(_RouteLauncher(busy: busy));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    var sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.enableDrag, isTrue);
    expect(sheet.showDragHandle, isTrue);

    busy.value = true;
    await tester.pump();

    sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.enableDrag, isFalse);
    expect(sheet.showDragHandle, isFalse);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guarded-sheet-content')), findsOneWidget);

    busy.value = false;
    await tester.pump();

    sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.enableDrag, isTrue);
    expect(sheet.showDragHandle, isTrue);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guarded-sheet-content')), findsNothing);
  });
}

class _RouteLauncher extends StatelessWidget {
  const _RouteLauncher({required this.busy});

  final ValueNotifier<bool> busy;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                showGuardedModalBottomSheet<void>(
                  context: context,
                  busy: busy,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
                  ),
                  builder: (_) => const SizedBox(key: Key('guarded-sheet-content'), height: 200),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }
}
