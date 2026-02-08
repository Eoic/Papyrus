import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/book_details/book_progress_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BookProgressBar', () {
    Widget buildWidget({
      double progress = 0.5,
      int? currentPage,
      int? totalPages,
      bool showLabel = true,
      VoidCallback? onTap,
    }) {
      return createTestApp(
        child: BookProgressBar(
          progress: progress,
          currentPage: currentPage,
          totalPages: totalPages,
          showLabel: showLabel,
          onTap: onTap,
        ),
      );
    }

    group('rendering', () {
      testWidgets('displays a LinearProgressIndicator', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows percentage label by default', (tester) async {
        await tester.pumpWidget(buildWidget(progress: 0.42));

        expect(find.text('42%'), findsOneWidget);
      });

      testWidgets('shows page numbers when provided', (tester) async {
        await tester.pumpWidget(
          buildWidget(progress: 0.5, currentPage: 150, totalPages: 300),
        );

        expect(find.text('150 / 300 (50%)'), findsOneWidget);
      });

      testWidgets('hides label when showLabel is false', (tester) async {
        await tester.pumpWidget(buildWidget(progress: 0.5, showLabel: false));

        expect(find.text('50%'), findsNothing);
      });
    });

    group('progress formatting', () {
      testWidgets('0% progress', (tester) async {
        await tester.pumpWidget(buildWidget(progress: 0.0));
        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('100% progress', (tester) async {
        await tester.pumpWidget(buildWidget(progress: 1.0));
        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('rounds to nearest percentage', (tester) async {
        await tester.pumpWidget(buildWidget(progress: 0.335));
        expect(find.text('34%'), findsOneWidget);
      });
    });

    group('onTap', () {
      testWidgets('wraps in GestureDetector when onTap provided', (
        tester,
      ) async {
        var called = false;
        await tester.pumpWidget(buildWidget(onTap: () => called = true));

        expect(find.byType(GestureDetector), findsOneWidget);

        await tester.tap(find.byType(GestureDetector));
        expect(called, true);
      });

      testWidgets('does not wrap in GestureDetector when onTap is null', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(GestureDetector), findsNothing);
      });
    });
  });
}
