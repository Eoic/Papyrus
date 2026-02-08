import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/widgets/book/book_notes.dart';
import 'package:papyrus/widgets/book_details/note_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late List<Note> testNotes;

  setUp(() {
    testNotes = [
      Note(
        id: 'note-1',
        bookId: 'book-1',
        title: 'Chapter Summary',
        content: 'This chapter covers the basics of software design.',
        location: const BookLocation(chapter: 1, pageNumber: 20),
        tags: ['summary'],
        createdAt: DateTime(2025, 6, 1),
      ),
      Note(
        id: 'note-2',
        bookId: 'book-1',
        title: 'Architecture Patterns',
        content: 'Key patterns discussed: MVC, MVVM, and Clean Architecture.',
        tags: ['patterns', 'architecture'],
        createdAt: DateTime(2025, 5, 10),
      ),
      Note(
        id: 'note-3',
        bookId: 'book-1',
        title: 'Zen of Python',
        content:
            'Beautiful is better than ugly. Explicit is better than implicit.',
        tags: ['philosophy'],
        createdAt: DateTime(2025, 7, 20),
      ),
    ];
  });

  Widget buildNotes({
    List<Note>? notes,
    VoidCallback? onAddNote,
    Function(Note)? onNoteTap,
    Function(Note)? onNoteActions,
    Size screenSize = const Size(400, 800),
  }) {
    return createTestApp(
      screenSize: screenSize,
      child: BookNotes(
        notes: notes ?? testNotes,
        onAddNote: onAddNote,
        onNoteTap: onNoteTap,
        onNoteActions: onNoteActions,
      ),
    );
  }

  group('BookNotes', () {
    group('rendering', () {
      testWidgets('displays search field with hint text', (tester) async {
        await tester.pumpWidget(buildNotes());

        expect(find.text('Search notes...'), findsOneWidget);
      });

      testWidgets('displays sort button', (tester) async {
        await tester.pumpWidget(buildNotes());

        expect(find.byIcon(Icons.sort), findsOneWidget);
      });

      testWidgets('renders NoteCard for each note', (tester) async {
        await tester.pumpWidget(buildNotes());

        expect(find.byType(NoteCard), findsNWidgets(3));
      });

      testWidgets('shows empty state when notes list is empty', (tester) async {
        await tester.pumpWidget(buildNotes(notes: []));

        expect(find.text('No notes yet'), findsOneWidget);
        expect(find.byIcon(Icons.note_outlined), findsOneWidget);
      });
    });

    group('search', () {
      testWidgets('filters by title', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.enterText(find.byType(TextField), 'Architecture');
        await tester.pump();

        expect(find.byType(NoteCard), findsOneWidget);
      });

      testWidgets('filters by content', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.enterText(find.byType(TextField), 'Beautiful');
        await tester.pump();

        expect(find.byType(NoteCard), findsOneWidget);
      });

      testWidgets('filters by tag', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.enterText(find.byType(TextField), 'philosophy');
        await tester.pump();

        expect(find.byType(NoteCard), findsOneWidget);
      });

      testWidgets('shows no results when no matches', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.enterText(find.byType(TextField), 'zzzznonexistent');
        await tester.pump();

        expect(find.text('No notes found'), findsOneWidget);
      });

      testWidgets('clearing search restores all notes', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.enterText(find.byType(TextField), 'Architecture');
        await tester.pump();
        expect(find.byType(NoteCard), findsOneWidget);

        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        expect(find.byType(NoteCard), findsNWidgets(3));
      });
    });

    group('sorting', () {
      testWidgets('sort menu shows 3 options', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();

        expect(find.text('Newest first'), findsOneWidget);
        expect(find.text('Oldest first'), findsOneWidget);
        expect(find.text('By title'), findsOneWidget);
      });

      testWidgets('default is newest first', (tester) async {
        await tester.pumpWidget(buildNotes());

        // Newest first: note-3 (Jul), note-1 (Jun), note-2 (May)
        final items = tester.widgetList<NoteCard>(find.byType(NoteCard));
        expect(items.first.note.id, 'note-3');
        expect(items.last.note.id, 'note-2');
      });

      testWidgets('selecting by title reorders alphabetically', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();
        await tester.tap(find.text('By title'));
        await tester.pumpAndSettle();

        // Alphabetical: Architecture Patterns, Chapter Summary, Zen of Python
        final items = tester.widgetList<NoteCard>(find.byType(NoteCard));
        expect(items.first.note.id, 'note-2'); // Architecture Patterns
        expect(items.last.note.id, 'note-3'); // Zen of Python
      });

      testWidgets('selecting oldest first reorders by date', (tester) async {
        await tester.pumpWidget(buildNotes());

        await tester.tap(find.byIcon(Icons.sort));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Oldest first'));
        await tester.pumpAndSettle();

        // Oldest first: note-2 (May), note-1 (Jun), note-3 (Jul)
        final items = tester.widgetList<NoteCard>(find.byType(NoteCard));
        expect(items.first.note.id, 'note-2');
        expect(items.last.note.id, 'note-3');
      });
    });

    group('callbacks', () {
      testWidgets('tap calls onNoteTap', (tester) async {
        Note? tappedNote;
        await tester.pumpWidget(buildNotes(onNoteTap: (n) => tappedNote = n));

        await tester.tap(find.byType(NoteCard).first);
        await tester.pump();

        expect(tappedNote, isNotNull);
      });

      testWidgets('long press calls onNoteActions', (tester) async {
        Note? actionNote;
        await tester.pumpWidget(
          buildNotes(onNoteActions: (n) => actionNote = n),
        );

        await tester.longPress(find.byType(NoteCard).first);
        await tester.pump();

        expect(actionNote, isNotNull);
      });
    });

    group('responsive', () {
      testWidgets('desktop shows add note button in header', (tester) async {
        await tester.pumpWidget(buildNotes(screenSize: const Size(1200, 800)));

        expect(find.text('Add note'), findsOneWidget);
      });

      testWidgets('mobile does not show add note button in header', (
        tester,
      ) async {
        await tester.pumpWidget(buildNotes(screenSize: const Size(400, 800)));

        expect(find.text('Add note'), findsNothing);
      });

      testWidgets('desktop layout shows action menu on items', (tester) async {
        await tester.pumpWidget(buildNotes(screenSize: const Size(1200, 800)));

        expect(find.byIcon(Icons.more_vert), findsNWidgets(3));
      });

      testWidgets('mobile layout hides action menu on items', (tester) async {
        await tester.pumpWidget(buildNotes(screenSize: const Size(400, 800)));

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });
    });
  });
}
