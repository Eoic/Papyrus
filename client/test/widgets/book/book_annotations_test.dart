import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/widgets/book/book_annotations.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late List<Annotation> testAnnotations;

  setUp(() {
    testAnnotations = [
      Annotation(
        id: 'ann-1',
        bookId: 'book-1',
        selectedText: 'Knowledge is power.',
        color: HighlightColor.yellow,
        location: const BookLocation(chapter: 1, pageNumber: 10),
        note: 'A foundational concept',
        createdAt: DateTime(2025, 6, 1),
      ),
      Annotation(
        id: 'ann-2',
        bookId: 'book-1',
        selectedText: 'Practice makes perfect.',
        color: HighlightColor.blue,
        location: const BookLocation(chapter: 3, pageNumber: 55),
        createdAt: DateTime(2025, 5, 15),
      ),
      Annotation(
        id: 'ann-3',
        bookId: 'book-1',
        selectedText:
            'The journey of a thousand miles begins with a single step.',
        color: HighlightColor.green,
        location: const BookLocation(chapter: 2, pageNumber: 30),
        note: 'Great motivational quote',
        createdAt: DateTime(2025, 7, 10),
      ),
      Annotation(
        id: 'ann-4',
        bookId: 'book-1',
        selectedText: 'To thine own self be true.',
        color: HighlightColor.pink,
        location: const BookLocation(chapter: 5, pageNumber: 88),
        createdAt: DateTime(2025, 4, 20),
      ),
    ];
  });

  Widget buildAnnotations({
    List<Annotation>? annotations,
    Function(Annotation)? onAnnotationTap,
    Function(Annotation)? onAnnotationActions,
    Size screenSize = const Size(400, 800),
  }) {
    return createTestApp(
      screenSize: screenSize,
      child: BookAnnotations(
        annotations: annotations ?? testAnnotations,
        onAnnotationTap: onAnnotationTap,
        onAnnotationActions: onAnnotationActions,
      ),
    );
  }

  group('BookAnnotations', () {
    group('rendering', () {
      testWidgets('displays search field with hint text', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        expect(find.text('Search annotations...'), findsOneWidget);
      });

      testWidgets('displays sort button', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        expect(find.byIcon(Icons.sort), findsOneWidget);
      });

      testWidgets('renders AnnotationCard for each annotation', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        expect(find.byType(AnnotationCard), findsNWidgets(4));
      });

      testWidgets('shows empty state when annotations list is empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildAnnotations(annotations: []));

        expect(find.text('No annotations yet'), findsOneWidget);
        expect(find.byIcon(Icons.highlight_outlined), findsOneWidget);
      });
    });

    group('search', () {
      testWidgets('filters by highlight text', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.enterText(find.byType(TextField), 'Knowledge');
        await tester.pump();

        expect(find.byType(AnnotationCard), findsOneWidget);
      });

      testWidgets('filters by note content', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.enterText(find.byType(TextField), 'foundational');
        await tester.pump();

        expect(find.byType(AnnotationCard), findsOneWidget);
      });

      testWidgets('filters by location', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        // BookLocation.displayLocation for ann-1: "Chapter 1, Page 10"
        await tester.enterText(find.byType(TextField), 'Page 55');
        await tester.pump();

        expect(find.byType(AnnotationCard), findsOneWidget);
      });

      testWidgets('shows no results when no matches', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.enterText(find.byType(TextField), 'zzzznonexistent');
        await tester.pump();

        expect(find.text('No annotations found'), findsOneWidget);
      });

      testWidgets('clearing search restores all', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.enterText(find.byType(TextField), 'Knowledge');
        await tester.pump();
        expect(find.byType(AnnotationCard), findsOneWidget);

        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        expect(find.byType(AnnotationCard), findsNWidgets(4));
      });
    });

    group('sorting', () {
      testWidgets('sort menu shows 4 options', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        expect(find.text('Newest first'), findsOneWidget);
        expect(find.text('Oldest first'), findsOneWidget);
        expect(find.text('By position'), findsOneWidget);
        expect(find.text('By color'), findsOneWidget);
      });

      testWidgets('default is newest first', (tester) async {
        await tester.pumpWidget(buildAnnotations());

        // Newest first: ann-3 (Jul), ann-1 (Jun), ann-2 (May), ann-4 (Apr)
        final items = tester.widgetList<AnnotationCard>(
          find.byType(AnnotationCard),
        );
        expect(items.first.annotation.id, 'ann-3');
        expect(items.last.annotation.id, 'ann-4');
      });

      testWidgets('selecting by position reorders by page number', (
        tester,
      ) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();
        await tester.tap(find.text('By position'));
        await tester.pumpAndSettle();

        // By page: ann-1 (p10), ann-3 (p30), ann-2 (p55), ann-4 (p88)
        final items = tester.widgetList<AnnotationCard>(
          find.byType(AnnotationCard),
        );
        expect(items.first.annotation.id, 'ann-1');
        expect(items.last.annotation.id, 'ann-4');
      });

      testWidgets('selecting by color reorders by color enum index', (
        tester,
      ) async {
        await tester.pumpWidget(buildAnnotations());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();
        await tester.tap(find.text('By color'));
        await tester.pumpAndSettle();

        // By color index: yellow(0), green(1), blue(2), pink(3)
        final items = tester.widgetList<AnnotationCard>(
          find.byType(AnnotationCard),
        );
        expect(items.first.annotation.color, HighlightColor.yellow);
        expect(items.last.annotation.color, HighlightColor.pink);
      });
    });

    group('callbacks', () {
      testWidgets('tap calls onAnnotationTap', (tester) async {
        Annotation? tappedAnnotation;
        await tester.pumpWidget(
          buildAnnotations(onAnnotationTap: (a) => tappedAnnotation = a),
        );

        await tester.tap(find.byType(AnnotationCard).first);
        await tester.pump();

        expect(tappedAnnotation, isNotNull);
      });

      testWidgets('long press calls onAnnotationActions', (tester) async {
        Annotation? actionAnnotation;
        await tester.pumpWidget(
          buildAnnotations(onAnnotationActions: (a) => actionAnnotation = a),
        );

        await tester.longPress(find.byType(AnnotationCard).first);
        await tester.pump();

        expect(actionAnnotation, isNotNull);
      });
    });

    group('responsive', () {
      testWidgets('desktop layout shows action menu on items', (tester) async {
        await tester.pumpWidget(
          buildAnnotations(screenSize: const Size(1200, 800)),
        );

        expect(find.byIcon(Icons.more_vert), findsAtLeastNWidgets(1));
      });

      testWidgets('mobile layout hides action menu on items', (tester) async {
        await tester.pumpWidget(
          buildAnnotations(screenSize: const Size(400, 800)),
        );

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });
    });
  });
}
