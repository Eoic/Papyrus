import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/widgets/book_details/note_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late Note noteWithLocation;
  late Note noteWithoutLocation;

  setUp(() {
    noteWithLocation = Note(
      id: 'note-1',
      bookId: 'book-1',
      title: 'Key Takeaways',
      content:
          'The author emphasizes the importance of consistent practice over natural talent. '
          'This is a longer content that should be truncated in preview mode.',
      location: const BookLocation(chapter: 5, pageNumber: 120),
      tags: ['summary', 'important'],
      createdAt: DateTime(2025, 4, 20),
    );

    noteWithoutLocation = Note(
      id: 'note-2',
      bookId: 'book-1',
      title: 'General Thoughts',
      content: 'A well-written book with practical examples.',
      tags: [],
      createdAt: DateTime(2025, 5, 10),
      updatedAt: DateTime(2025, 5, 15),
    );
  });

  Widget buildCard({
    Note? note,
    bool showActionMenu = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return createTestApp(
      child: NoteCard(
        note: note ?? noteWithLocation,
        showActionMenu: showActionMenu,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  group('NoteCard', () {
    group('rendering', () {
      testWidgets('displays note title', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.text('Key Takeaways'), findsOneWidget);
      });

      testWidgets('displays content preview', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.text(noteWithLocation.preview), findsOneWidget);
      });

      testWidgets('displays tags as chips', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.widgetWithText(Chip, 'summary'), findsOneWidget);
        expect(find.widgetWithText(Chip, 'important'), findsOneWidget);
      });

      testWidgets('displays location with icon when present', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
        expect(find.text('Ch. 5, p. 120'), findsOneWidget);
      });

      testWidgets('hides location when not set', (tester) async {
        await tester.pumpWidget(buildCard(note: noteWithoutLocation));

        expect(find.byIcon(Icons.location_on_outlined), findsNothing);
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

      testWidgets('displays created date label', (tester) async {
        await tester.pumpWidget(buildCard());

        expect(find.text('Created Apr 20, 2025'), findsOneWidget);
      });

      testWidgets('displays edited date label when updated', (tester) async {
        await tester.pumpWidget(buildCard(note: noteWithoutLocation));

        expect(find.text('Edited May 15, 2025'), findsOneWidget);
      });

      testWidgets('hides tags section when no tags', (tester) async {
        await tester.pumpWidget(buildCard(note: noteWithoutLocation));

        expect(find.byType(Chip), findsNothing);
      });
    });

    group('callbacks', () {
      testWidgets('tap calls onTap', (tester) async {
        var tapped = false;
        await tester.pumpWidget(buildCard(onTap: () => tapped = true));

        await tester.tap(find.byType(NoteCard));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('long press calls onLongPress', (tester) async {
        var longPressed = false;
        await tester.pumpWidget(
          buildCard(onLongPress: () => longPressed = true),
        );

        await tester.longPress(find.byType(NoteCard));
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
