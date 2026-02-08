import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

void main() {
  group('BottomSheetHeader', () {
    Widget buildHeader({
      String title = 'Test title',
      VoidCallback? onCancel,
      VoidCallback? onSave,
      String saveLabel = 'Save',
      bool canSave = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BottomSheetHeader(
            title: title,
            onCancel: onCancel ?? () {},
            onSave: onSave ?? () {},
            saveLabel: saveLabel,
            canSave: canSave,
          ),
        ),
      );
    }

    testWidgets('renders title, cancel, and save buttons', (tester) async {
      await tester.pumpWidget(buildHeader(title: 'Edit bookmark'));

      expect(find.text('Edit bookmark'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('cancel button calls onCancel', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(buildHeader(onCancel: () => cancelled = true));

      await tester.tap(find.text('Cancel'));
      expect(cancelled, isTrue);
    });

    testWidgets('save button calls onSave', (tester) async {
      var saved = false;
      await tester.pumpWidget(buildHeader(onSave: () => saved = true));

      await tester.tap(find.text('Save'));
      expect(saved, isTrue);
    });

    testWidgets('save button is disabled when canSave is false', (
      tester,
    ) async {
      var saved = false;
      await tester.pumpWidget(
        buildHeader(canSave: false, onSave: () => saved = true),
      );

      await tester.tap(find.text('Save'));
      expect(saved, isFalse);
    });

    testWidgets('uses custom save label', (tester) async {
      await tester.pumpWidget(buildHeader(saveLabel: 'Done'));

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('save button is a FilledButton', (tester) async {
      await tester.pumpWidget(buildHeader());

      final filledButton = find.ancestor(
        of: find.text('Save'),
        matching: find.byType(FilledButton),
      );
      expect(filledButton, findsOneWidget);
    });
  });
}
