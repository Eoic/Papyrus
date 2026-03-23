import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late Annotation annotationWithNote;
  late Annotation annotationWithoutNote;

  setUp(() {
    annotationWithNote = Annotation(
      id: 'ann-1',
      bookId: 'book-1',
      selectedText: 'The quick brown fox jumps over the lazy dog.',
      color: HighlightColor.blue,
      location: const BookLocation(chapter: 3, pageNumber: 45),
      note: 'A classic pangram used in typography.',
      createdAt: DateTime(2025, 6, 15),
    );

    annotationWithoutNote = Annotation(
      id: 'ann-2',
      bookId: 'book-1',
      selectedText: 'To be or not to be, that is the question.',
      color: HighlightColor.pink,
      location: const BookLocation(
        chapter: 1,
        chapterTitle: 'Act III',
        pageNumber: 12,
      ),
      createdAt: DateTime(2025, 3, 10),
    );
  });

  Widget buildCard({
    Annotation? annotation,
    bool showActionMenu = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return createTestApp(
      child: AnnotationCard(
        annotation: annotation ?? annotationWithNote,
        showActionMenu: showActionMenu,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  group('AnnotationCard', () {
    group('rendering', () {
      testWidgets('displays highlight text in italic with quotes', (
        tester,
      ) async {
        await tester.pumpWidget(buildCard());

        expect(
          find.text('"The quick brown fox jumps over the lazy dog."'),
          findsOneWidget,
        );
      });

      testWidgets('displays location', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.text('Ch. 3, p. 45'), findsOneWidget);
      });

      testWidgets('displays date', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.text('Jun 15, 2025'), findsOneWidget);
      });

      testWidgets('shows note section when annotation has a note', (
        tester,
      ) async {
        await tester.pumpWidget(buildCard());

        expect(
          find.text('A classic pangram used in typography.'),
          findsOneWidget,
        );
      });

      testWidgets('hides note section when no note', (tester) async {
        await tester.pumpWidget(buildCard(annotation: annotationWithoutNote));

        expect(
          find.text('A classic pangram used in typography.'),
          findsNothing,
        );
      });

      testWidgets('shows colored left border matching highlight color', (
        tester,
      ) async {
        await tester.pumpWidget(buildCard());

        // Find the container with the left border decoration
        final container = find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            final border = decoration.border;
            if (border is Border && border.left.width == 4) {
              return border.left.color == HighlightColor.blue.accentColor;
            }
          }
          return false;
        });
        expect(container, findsOneWidget);
      });

      testWidgets('shows action menu when showActionMenu is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildCard(showActionMenu: true));

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('hides action menu when showActionMenu is false', (
        tester,
      ) async {
        await tester.pumpWidget(buildCard(showActionMenu: false));

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('displays location with chapter title when present', (
        tester,
      ) async {
        await tester.pumpWidget(buildCard(annotation: annotationWithoutNote));

        expect(find.text('Ch. 1, p. 12'), findsOneWidget);
      });
    });

    group('callbacks', () {
      testWidgets('tap calls onTap', (tester) async {
        var tapped = false;
        await tester.pumpWidget(buildCard(onTap: () => tapped = true));

        await tester.tap(find.byType(AnnotationCard));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('long press calls onLongPress', (tester) async {
        var longPressed = false;
        await tester.pumpWidget(
          buildCard(onLongPress: () => longPressed = true),
        );

        await tester.longPress(find.byType(AnnotationCard));
        await tester.pump();

        expect(longPressed, isTrue);
      });

      testWidgets('action menu button calls onLongPress', (tester) async {
        var pressed = false;
        await tester.pumpWidget(buildCard(onLongPress: () => pressed = true));

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });
  });
}
