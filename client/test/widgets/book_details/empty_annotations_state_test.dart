import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/book_details/empty_annotations_state.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('EmptyAnnotationsState', () {
    Widget buildWidget({
      bool isPhysical = false,
      VoidCallback? onAddAnnotation,
    }) {
      return createTestApp(
        child: EmptyAnnotationsState(
          isPhysical: isPhysical,
          onAddAnnotation: onAddAnnotation,
        ),
      );
    }

    group('rendering', () {
      testWidgets('displays highlight icon', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.highlight_outlined), findsOneWidget);
      });

      testWidgets('displays title text', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('No annotations yet'), findsOneWidget);
      });
    });

    group('digital book', () {
      testWidgets('shows digital book description', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(
          find.text('Highlight text while reading to create annotations.'),
          findsOneWidget,
        );
      });

      testWidgets('does not show add annotation button', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Add annotation'), findsNothing);
      });
    });

    group('physical book', () {
      testWidgets('shows physical book description', (tester) async {
        await tester.pumpWidget(buildWidget(isPhysical: true));

        expect(
          find.text(
            "Add passages you've highlighted or underlined in your book.",
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows add annotation button', (tester) async {
        await tester.pumpWidget(buildWidget(isPhysical: true));

        expect(find.text('Add annotation'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('add button calls onAddAnnotation', (tester) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(isPhysical: true, onAddAnnotation: () => called = true),
        );

        await tester.tap(find.text('Add annotation'));
        expect(called, true);
      });
    });
  });
}
