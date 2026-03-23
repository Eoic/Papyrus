import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/book_details_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BookDetailsProvider', () {
    late BookDetailsProvider provider;
    late DataStore dataStore;

    setUp(() {
      provider = BookDetailsProvider();
      dataStore = DataStore();
      dataStore.loadData(
        books: [
          buildTestBook(
            id: 'book-1',
            title: 'Test Book',
            author: 'Author',
            currentPosition: 0.5,
            readingStatus: ReadingStatus.inProgress,
            isFavorite: false,
            pageCount: 300,
          ),
          buildTestBook(
            id: 'book-2',
            title: 'Another Book',
            author: 'Author 2',
          ),
        ],
        bookmarks: [
          buildTestBookmark(id: 'bm-1', bookId: 'book-1', position: 0.3),
          buildTestBookmark(id: 'bm-2', bookId: 'book-1', position: 0.6),
          buildTestBookmark(id: 'bm-3', bookId: 'book-2', position: 0.1),
        ],
        annotations: [
          buildTestAnnotation(
            id: 'ann-1',
            bookId: 'book-1',
            selectedText: 'Highlight 1',
          ),
        ],
        notes: [
          buildTestNote(
            id: 'note-1',
            bookId: 'book-1',
            title: 'Note 1',
            content: 'Content 1',
          ),
        ],
      );
      provider.setDataStore(dataStore);
    });

    tearDown(() {
      provider.dispose();
    });

    group('initial state', () {
      test('has no book loaded', () {
        expect(provider.book, isNull);
        expect(provider.hasBook, false);
      });

      test('defaults to details tab', () {
        expect(provider.selectedTab, BookDetailsTab.details);
      });

      test('is not loading', () {
        expect(provider.isLoading, false);
      });

      test('has no error', () {
        expect(provider.error, isNull);
      });

      test('description is not expanded', () {
        expect(provider.isDescriptionExpanded, false);
      });

      test('has empty bookmarks, annotations, and notes', () {
        expect(provider.bookmarks, isEmpty);
        expect(provider.annotations, isEmpty);
        expect(provider.notes, isEmpty);
        expect(provider.bookmarkCount, 0);
        expect(provider.annotationCount, 0);
        expect(provider.noteCount, 0);
      });
    });

    group('loadBook', () {
      test('loads a book from DataStore', () async {
        await provider.loadBook('book-1');

        expect(provider.hasBook, true);
        expect(provider.book!.id, 'book-1');
        expect(provider.book!.title, 'Test Book');
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('sets error when book not found', () async {
        await provider.loadBook('nonexistent');

        expect(provider.hasBook, false);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Book not found'));
      });

      test('loads bookmarks for the book', () async {
        await provider.loadBook('book-1');

        expect(provider.bookmarks.length, 2);
        expect(provider.hasBookmarks, true);
        expect(provider.bookmarkCount, 2);
      });

      test('loads annotations for the book', () async {
        await provider.loadBook('book-1');

        expect(provider.annotations.length, 1);
        expect(provider.hasAnnotations, true);
        expect(provider.annotationCount, 1);
      });

      test('loads notes for the book', () async {
        await provider.loadBook('book-1');

        expect(provider.notes.length, 1);
        expect(provider.hasNotes, true);
        expect(provider.noteCount, 1);
      });

      test('does not reload same book unnecessarily', () async {
        await provider.loadBook('book-1');
        final firstBook = provider.book;

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.loadBook('book-1');

        // Should be the same object since the book didn't change
        expect(provider.book, firstBook);
        // Should not have triggered isLoading cycle
        expect(notifyCount, 0);
      });

      test('notifies listeners during load', () async {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.loadBook('book-1');

        // At least 2 notifications: loading start + loading complete
        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });

    group('setTab', () {
      test('changes selected tab', () {
        provider.setTab(BookDetailsTab.bookmarks);
        expect(provider.selectedTab, BookDetailsTab.bookmarks);

        provider.setTab(BookDetailsTab.annotations);
        expect(provider.selectedTab, BookDetailsTab.annotations);

        provider.setTab(BookDetailsTab.notes);
        expect(provider.selectedTab, BookDetailsTab.notes);
      });

      test('does not notify when setting same tab', () {
        provider.setTab(BookDetailsTab.bookmarks);

        var notified = false;
        provider.addListener(() => notified = true);

        provider.setTab(BookDetailsTab.bookmarks);
        expect(notified, false);
      });

      test('notifies when changing tab', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setTab(BookDetailsTab.notes);
        expect(notified, true);
      });
    });

    group('setTabIndex', () {
      test('sets tab by index', () {
        provider.setTabIndex(0);
        expect(provider.selectedTab, BookDetailsTab.details);

        provider.setTabIndex(1);
        expect(provider.selectedTab, BookDetailsTab.bookmarks);

        provider.setTabIndex(2);
        expect(provider.selectedTab, BookDetailsTab.annotations);

        provider.setTabIndex(3);
        expect(provider.selectedTab, BookDetailsTab.notes);
      });

      test('ignores invalid indices', () {
        provider.setTab(BookDetailsTab.details);
        provider.setTabIndex(-1);
        expect(provider.selectedTab, BookDetailsTab.details);

        provider.setTabIndex(10);
        expect(provider.selectedTab, BookDetailsTab.details);
      });
    });

    group('toggleDescriptionExpanded', () {
      test('toggles expanded state', () {
        expect(provider.isDescriptionExpanded, false);

        provider.toggleDescriptionExpanded();
        expect(provider.isDescriptionExpanded, true);

        provider.toggleDescriptionExpanded();
        expect(provider.isDescriptionExpanded, false);
      });
    });

    group('note CRUD', () {
      setUp(() async {
        await provider.loadBook('book-1');
      });

      test('addNote persists to DataStore and notifies', () {
        final note = buildTestNote(
          id: 'new-note',
          bookId: 'book-1',
          title: 'New Note',
          content: 'New content',
        );

        var notified = false;
        provider.addListener(() => notified = true);

        provider.addNote(note);

        expect(provider.notes.length, 2);
        expect(provider.notes.any((n) => n.id == 'new-note'), true);
        expect(dataStore.getNote('new-note'), isNotNull);
        expect(notified, true);
      });

      test('updateNote persists updated note to DataStore', () {
        final updatedNote = buildTestNote(
          id: 'note-1',
          bookId: 'book-1',
          title: 'Updated Title',
          content: 'Updated content',
        );

        provider.updateNote('note-1', updatedNote);

        expect(dataStore.getNote('note-1')!.title, 'Updated Title');
      });

      test('deleteNote removes from DataStore', () {
        provider.deleteNote('note-1');

        expect(provider.notes, isEmpty);
        expect(dataStore.getNote('note-1'), isNull);
      });
    });

    group('bookmark CRUD', () {
      setUp(() async {
        await provider.loadBook('book-1');
      });

      test('addBookmark persists to DataStore', () {
        final bookmark = buildTestBookmark(
          id: 'new-bm',
          bookId: 'book-1',
          position: 0.8,
        );

        provider.addBookmark(bookmark);

        expect(provider.bookmarks.length, 3);
        expect(dataStore.getBookmark('new-bm'), isNotNull);
      });

      test('updateBookmarkNote updates the bookmark note', () {
        provider.updateBookmarkNote('bm-1', 'Updated note');

        expect(dataStore.getBookmark('bm-1')!.note, 'Updated note');
      });

      test('updateBookmarkNote clears note when null', () {
        // First set a note
        provider.updateBookmarkNote('bm-1', 'A note');
        expect(dataStore.getBookmark('bm-1')!.note, 'A note');

        // Then clear it
        provider.updateBookmarkNote('bm-1', null);
        expect(dataStore.getBookmark('bm-1')!.note, isNull);
      });

      test('updateBookmarkColor updates the bookmark color', () {
        provider.updateBookmarkColor('bm-1', '#FF0000');

        expect(dataStore.getBookmark('bm-1')!.colorHex, '#FF0000');
      });

      test('deleteBookmark removes from DataStore', () {
        provider.deleteBookmark('bm-1');

        expect(provider.bookmarks.length, 1);
        expect(dataStore.getBookmark('bm-1'), isNull);
      });

      test('updateBookmarkNote does nothing for nonexistent bookmark', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateBookmarkNote('nonexistent', 'A note');

        expect(notified, false);
      });
    });

    group('annotation CRUD', () {
      setUp(() async {
        await provider.loadBook('book-1');
      });

      test('addAnnotation persists to DataStore', () {
        final annotation = buildTestAnnotation(
          id: 'new-ann',
          bookId: 'book-1',
          selectedText: 'New highlight',
        );

        provider.addAnnotation(annotation);

        expect(provider.annotations.length, 2);
        expect(dataStore.getAnnotation('new-ann'), isNotNull);
      });

      test('updateAnnotationNote updates the annotation note', () {
        provider.updateAnnotationNote('ann-1', 'Updated note');

        expect(dataStore.getAnnotation('ann-1')!.note, 'Updated note');
      });

      test('updateAnnotation replaces entire annotation', () {
        final updated = buildTestAnnotation(
          id: 'ann-1',
          bookId: 'book-1',
          selectedText: 'Replaced text',
          color: HighlightColor.pink,
        );

        provider.updateAnnotation('ann-1', updated);

        expect(dataStore.getAnnotation('ann-1')!.selectedText, 'Replaced text');
        expect(dataStore.getAnnotation('ann-1')!.color, HighlightColor.pink);
      });

      test('deleteAnnotation removes from DataStore', () {
        provider.deleteAnnotation('ann-1');

        expect(provider.annotations, isEmpty);
        expect(dataStore.getAnnotation('ann-1'), isNull);
      });

      test('updateAnnotationNote does nothing for nonexistent annotation', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateAnnotationNote('nonexistent', 'A note');

        expect(notified, false);
      });
    });

    group('toggleFavorite', () {
      test('toggles favorite status and persists', () async {
        await provider.loadBook('book-1');
        expect(provider.book!.isFavorite, false);

        provider.toggleFavorite();

        expect(provider.book!.isFavorite, true);
        expect(dataStore.getBook('book-1')!.isFavorite, true);

        provider.toggleFavorite();

        expect(provider.book!.isFavorite, false);
        expect(dataStore.getBook('book-1')!.isFavorite, false);
      });

      test('does nothing when no book loaded', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.toggleFavorite();

        expect(notified, false);
      });
    });

    group('updateProgress', () {
      test('updates position and persists', () async {
        await provider.loadBook('book-1');

        provider.updateProgress(0.75);

        expect(provider.book!.currentPosition, 0.75);
        expect(dataStore.getBook('book-1')!.currentPosition, 0.75);
      });

      test('clamps value to 0.0-1.0', () async {
        await provider.loadBook('book-1');

        provider.updateProgress(1.5);
        expect(provider.book!.currentPosition, 1.0);

        provider.updateProgress(-0.5);
        expect(provider.book!.currentPosition, 0.0);
      });

      test('does nothing when no book loaded', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateProgress(0.5);

        expect(notified, false);
      });
    });

    group('updatePageProgress', () {
      test('updates page and position', () async {
        await provider.loadBook('book-1');

        provider.updatePageProgress(150, 0.5);

        expect(provider.book!.currentPage, 150);
        expect(provider.book!.currentPosition, 0.5);
        expect(provider.book!.lastReadAt, isNotNull);
      });

      test('sets status to completed when position >= 1.0', () async {
        await provider.loadBook('book-1');

        provider.updatePageProgress(300, 1.0);

        expect(provider.book!.readingStatus, ReadingStatus.completed);
      });

      test('sets status to inProgress when position > 0', () async {
        // Load a not-started book
        await provider.loadBook('book-2');

        provider.updatePageProgress(10, 0.1);

        expect(provider.book!.readingStatus, ReadingStatus.inProgress);
      });

      test('clamps position to 0.0-1.0', () async {
        await provider.loadBook('book-1');

        provider.updatePageProgress(999, 2.0);

        expect(provider.book!.currentPosition, 1.0);
      });

      test('does nothing when no book loaded', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updatePageProgress(10, 0.1);

        expect(notified, false);
      });

      test('persists to DataStore', () async {
        await provider.loadBook('book-1');

        provider.updatePageProgress(200, 0.67);

        final stored = dataStore.getBook('book-1')!;
        expect(stored.currentPage, 200);
        expect(stored.currentPosition, 0.67);
      });
    });

    group('DataStore listener', () {
      test('refreshes book when DataStore changes externally', () async {
        await provider.loadBook('book-1');
        expect(provider.book!.isFavorite, false);

        // Simulate external change via DataStore directly
        final updated = dataStore.getBook('book-1')!.copyWith(isFavorite: true);
        dataStore.updateBook(updated);

        // Provider should have picked up the change
        expect(provider.book!.isFavorite, true);
      });
    });

    group('clear', () {
      test('resets all state', () async {
        await provider.loadBook('book-1');
        provider.setTab(BookDetailsTab.notes);
        provider.toggleDescriptionExpanded();

        provider.clear();

        expect(provider.book, isNull);
        expect(provider.hasBook, false);
        expect(provider.selectedTab, BookDetailsTab.details);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
        expect(provider.isDescriptionExpanded, false);
      });
    });

    group('setDataStore', () {
      test('switches to new DataStore and removes old listener', () {
        final oldStore = DataStore();
        oldStore.loadData(books: [buildTestBook(id: 'old-book')]);

        final newStore = DataStore();
        newStore.loadData(books: [buildTestBook(id: 'new-book')]);

        final p = BookDetailsProvider();
        p.setDataStore(oldStore);
        p.setDataStore(newStore);

        // Updating old store should not affect provider
        // (no crash = listener was properly removed)
        oldStore.addBook(buildTestBook(id: 'another'));

        p.dispose();
      });

      test('does not re-register when same DataStore passed', () {
        // Just verify it doesn't crash
        provider.setDataStore(dataStore);
        provider.setDataStore(dataStore);
      });
    });
  });
}
