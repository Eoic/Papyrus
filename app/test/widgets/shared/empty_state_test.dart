import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';

void main() {
  group('EmptyState', () {
    Widget buildEmptyState({
      IconData icon = Icons.library_books_outlined,
      String title = 'No books found',
      String? subtitle,
      Widget? action,
      double iconSize = 64,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: icon,
            title: title,
            subtitle: subtitle,
            action: action,
            iconSize: iconSize,
          ),
        ),
      );
    }

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        buildEmptyState(icon: Icons.library_books_outlined),
      );
      expect(find.byIcon(Icons.library_books_outlined), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(buildEmptyState(title: 'No books found'));
      expect(find.text('No books found'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        buildEmptyState(subtitle: 'Try adjusting your filters'),
      );
      expect(find.text('Try adjusting your filters'), findsOneWidget);
    });

    testWidgets('does not display subtitle when null', (tester) async {
      await tester.pumpWidget(buildEmptyState(subtitle: null));
      // Only title should be present, no subtitle text
      expect(find.text('No books found'), findsOneWidget);
    });

    testWidgets('displays action widget when provided', (tester) async {
      await tester.pumpWidget(
        buildEmptyState(
          action: ElevatedButton(
            onPressed: () {},
            child: const Text('Add books'),
          ),
        ),
      );
      expect(find.text('Add books'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not display action when null', (tester) async {
      await tester.pumpWidget(buildEmptyState(action: null));
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('is centered', (tester) async {
      await tester.pumpWidget(buildEmptyState());
      // EmptyState contains a Center widget
      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });

    testWidgets('uses custom icon size', (tester) async {
      await tester.pumpWidget(buildEmptyState(iconSize: 100));
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.library_books_outlined),
      );
      expect(icon.size, 100);
    });

    testWidgets('uses different icons', (tester) async {
      await tester.pumpWidget(buildEmptyState(icon: Icons.search_off));
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });
}
