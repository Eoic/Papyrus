import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/widgets/book_details/bookmark_dialog.dart';
import 'package:papyrus/widgets/bookmarks/bookmark_action_sheet.dart';

void main() {
  final bookmark = Bookmark(
    id: 'bookmark',
    bookId: 'physical-book',
    position: 0.25,
    pageNumber: 30,
    note: 'Existing note',
    createdAt: DateTime.utc(2026),
  );

  Finder colorChoices() => find.byWidgetPredicate(
    (widget) =>
        widget is GestureDetector &&
        widget.child is Container &&
        (widget.child as Container).constraints?.minWidth == 48,
  );

  Future<void> open(WidgetTester tester, void Function(BuildContext) show) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(onPressed: () => show(context), child: const Text('Open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final kind in ['create', 'note', 'color', 'delete']) {
    for (final fails in [false, true]) {
      testWidgets('bookmark $kind waits for write and ${fails ? 'keeps failures open' : 'closes after success'}', (
        tester,
      ) async {
        final write = Completer<void>();
        var calls = 0;
        Future<void> save() {
          calls++;
          return write.future;
        }

        await open(tester, (context) {
          switch (kind) {
            case 'create':
              BookmarkDialog.show(context, bookId: 'physical-book', pageCount: 120, onSave: (_) => save());
            case 'note':
              BookmarkNoteSheet.show(context, bookmark: bookmark, onSave: (_) => save());
            case 'color':
              BookmarkColorSheet.show(context, bookmark: bookmark, onSave: (_) => save());
            case 'delete':
              DeleteBookmarkDialog.show(context, bookmark: bookmark, bookTitle: 'Physical Book', onDelete: save);
          }
        });
        if (kind == 'create') await tester.enterText(find.byType(TextFormField).first, '30');
        final action = kind == 'color'
            ? colorChoices().first
            : find.widgetWithText(FilledButton, kind == 'delete' ? 'Delete' : 'Save');
        await tester.tap(action);
        await tester.pump();
        expect(calls, 1);
        expect(action, findsOneWidget);
        if (kind == 'color') {
          expect(tester.widget<GestureDetector>(action).onTap, isNull);
        } else {
          expect(tester.widget<FilledButton>(action).onPressed, isNull);
        }

        if (fails) {
          write.completeError(StateError('Disk full'));
        } else {
          write.complete();
        }
        await tester.pumpAndSettle();
        if (kind == 'color' && !fails) {
          expect(colorChoices(), findsNothing);
        } else {
          expect(action, fails ? findsOneWidget : findsNothing);
        }
        if (fails) {
          expect(find.text('Could not save changes. Please try again.'), findsOneWidget);
          if (kind == 'color') {
            expect(tester.widget<GestureDetector>(action).onTap, isNotNull);
          } else {
            expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
          }
        }
      });
    }
  }

  testWidgets('manual physical bookmark saves page, position, chapter, note and selected color with a UUID', (
    tester,
  ) async {
    Bookmark? saved;
    await open(
      tester,
      (context) => BookmarkDialog.show(
        context,
        bookId: 'physical-book',
        pageCount: 120,
        onSave: (bookmark) {
          saved = bookmark;
        },
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30');
    await tester.enterText(fields.at(1), '  First chapter  ');
    await tester.enterText(fields.at(2), '  Remember this  ');
    final blue = find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector &&
          widget.child is Container &&
          (widget.child as Container).decoration is BoxDecoration &&
          ((widget.child as Container).decoration as BoxDecoration).color == const Color(0xFF2196F3),
    );
    await tester.tap(blue);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(saved!.bookId, 'physical-book');
    expect(saved!.pageNumber, 30);
    expect(saved!.position, 0.25);
    expect(saved!.chapterTitle, 'First chapter');
    expect(saved!.note, 'Remember this');
    expect(saved!.colorHex, '#2196F3');
    expect(saved!.createdAt.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
  });

  testWidgets('physical bookmark without a total page count retains its entered page', (tester) async {
    Bookmark? saved;
    await open(
      tester,
      (context) => BookmarkDialog.show(
        context,
        bookId: 'physical-book',
        onSave: (bookmark) {
          saved = bookmark;
        },
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, '47');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(saved!.pageNumber, 47);
    expect(saved!.position, 0);
    expect(saved!.chapterTitle, isNull);
    expect(saved!.note, isNull);
  });
}
