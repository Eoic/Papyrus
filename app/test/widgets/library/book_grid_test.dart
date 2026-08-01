import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_card.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:papyrus/widgets/library/book_grid.dart';
import 'package:provider/provider.dart';

void main() {
  group('BookGrid ordinary behavior', () {
    testWidgets('renders books in a GridView', (tester) async {
      final books = [_book(id: 'book-1', title: 'First Book'), _book(id: 'book-2', title: 'Second Book')];

      await tester.pumpWidget(_buildGrid(books: books));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(BookCard), findsNWidgets(2));
    });

    testWidgets('renders an empty grid without items', (tester) async {
      await tester.pumpWidget(_buildGrid(books: const []));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(BookCard), findsNothing);
      expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
    });
  });

  group('BookGrid acquisition reconciliation', () {
    testWidgets('renders a job without a synchronized book once as an orphan', (tester) async {
      final orphan = _job(id: 'orphan-job', bookId: null, title: 'Waiting for Sync');

      await tester.pumpWidget(_buildGrid(books: const [], placeholderJobs: [orphan]));

      expect(find.byType(BookCard), findsNothing);
      expect(find.byType(AcquisitionPlaceholderCard), findsOneWidget);
      expect(find.text('Waiting for Sync'), findsOneWidget);
    });

    testWidgets('attaches a linked job and does not render an orphan', (tester) async {
      final book = _book(id: 'book-1', title: 'Synchronized Book');
      final linked = _job(id: 'linked-job', bookId: book.id, title: book.title);

      await tester.pumpWidget(
        _buildGrid(books: [book], acquisitionJobsByBookId: {book.id: linked}, placeholderJobs: [linked]),
      );

      final card = tester.widget<BookCard>(_bookCard(book.id));

      expect(card.acquisitionJob, same(linked));
      expect(find.byType(BookCard), findsOneWidget);
      expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
    });

    testWidgets('defensively attaches a linked placeholder job by book id', (tester) async {
      final book = _book(id: 'book-1', title: 'Synchronized Book');
      final linked = _job(id: 'linked-job', bookId: book.id, title: book.title);

      await tester.pumpWidget(_buildGrid(books: [book], placeholderJobs: [linked]));

      expect(tester.widget<BookCard>(_bookCard(book.id)).acquisitionJob, same(linked));
      expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
    });

    testWidgets('claims a duplicate linked job id for the first book only', (tester) async {
      final firstBook = _book(id: 'book-1', title: 'First Book');
      final secondBook = _book(id: 'book-2', title: 'Second Book');
      final firstJob = _job(id: 'shared-job', bookId: firstBook.id, title: firstBook.title);
      final secondJob = _job(id: 'shared-job', bookId: secondBook.id, title: secondBook.title);
      final acquisitionSelections = <String>[];
      final ordinaryTaps = <String>[];

      await tester.pumpWidget(
        _buildGrid(
          books: [firstBook, secondBook],
          acquisitionJobsByBookId: {secondBook.id: secondJob, firstBook.id: firstJob},
          selectedAcquisitionJobIds: const {'shared-job'},
          onAcquisitionSelectionToggle: (job) => acquisitionSelections.add(job.id),
          onBookTap: (book) => ordinaryTaps.add(book.id),
        ),
      );

      final firstCard = tester.widget<BookCard>(_bookCard(firstBook.id));
      final secondCard = tester.widget<BookCard>(_bookCard(secondBook.id));

      expect(firstCard.acquisitionJob, same(firstJob));
      expect(firstCard.isSelectionMode, isTrue);
      expect(firstCard.isSelected, isTrue);
      expect(secondCard.acquisitionJob, isNull);
      expect(secondCard.isSelectionMode, isFalse);
      expect(secondCard.isSelected, isFalse);

      await tester.tap(_bookCard(firstBook.id));
      await tester.tap(_bookCard(secondBook.id));

      expect(acquisitionSelections, ['shared-job']);
      expect(ordinaryTaps, [secondBook.id]);
    });

    testWidgets('claims a map and placeholder duplicate id in books order', (tester) async {
      final placeholderBook = _book(id: 'book-placeholder', title: 'Placeholder Winner');
      final mappedBook = _book(id: 'book-mapped', title: 'Mapped Loser');
      final placeholderJob = _job(id: 'shared-job', bookId: placeholderBook.id, title: placeholderBook.title);
      final mappedJob = _job(id: 'shared-job', bookId: mappedBook.id, title: mappedBook.title);

      await tester.pumpWidget(
        _buildGrid(
          books: [placeholderBook, mappedBook],
          acquisitionJobsByBookId: {mappedBook.id: mappedJob},
          placeholderJobs: [placeholderJob],
        ),
      );

      expect(tester.widget<BookCard>(_bookCard(placeholderBook.id)).acquisitionJob, same(placeholderJob));
      expect(tester.widget<BookCard>(_bookCard(mappedBook.id)).acquisitionJob, isNull);
      expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
    });

    testWidgets('deduplicates repeated orphan ids and book ids', (tester) async {
      final first = _job(id: 'job-1', bookId: 'pending-book', title: 'First');
      final duplicateId = _job(id: 'job-1', bookId: null, title: 'Duplicate ID');
      final duplicateBook = _job(id: 'job-2', bookId: 'pending-book', title: 'Duplicate Book');

      await tester.pumpWidget(_buildGrid(books: const [], placeholderJobs: [first, duplicateId, duplicateBook]));

      expect(find.byType(AcquisitionPlaceholderCard), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Duplicate ID'), findsNothing);
      expect(find.text('Duplicate Book'), findsNothing);
    });

    testWidgets('orders synchronized books before orphan placeholders', (tester) async {
      final first = _book(id: 'book-1', title: 'First Book');
      final second = _book(id: 'book-2', title: 'Second Book');
      final orphan = _job(id: 'orphan-job', bookId: null, title: 'Orphan Job');

      await tester.pumpWidget(_buildGrid(books: [first, second], placeholderJobs: [orphan]));

      final firstPosition = tester.getTopLeft(_bookCard(first.id));
      final secondPosition = tester.getTopLeft(_bookCard(second.id));
      final orphanPosition = tester.getTopLeft(find.byType(AcquisitionPlaceholderCard));

      expect(firstPosition.dy, secondPosition.dy);
      expect(orphanPosition.dy, greaterThan(firstPosition.dy));
    });

    testWidgets('routes linked and orphan interactions to acquisition callbacks', (tester) async {
      final linkedBook = _book(id: 'book-linked', title: 'Linked Book');
      final linkedJob = _job(id: 'job-linked', bookId: linkedBook.id, title: linkedBook.title);
      final orphanJob = _job(id: 'job-orphan', bookId: null, title: 'Orphan Book');
      final acquisitionTaps = <String>[];
      final acquisitionToggles = <String>[];
      final bookTaps = <String>[];

      await tester.pumpWidget(
        _buildGrid(
          books: [linkedBook],
          onBookTap: (book) => bookTaps.add(book.id),
          acquisitionJobsByBookId: {linkedBook.id: linkedJob},
          placeholderJobs: [orphanJob],
          onAcquisitionTap: (job) => acquisitionTaps.add(job.id),
          onAcquisitionSelectionToggle: (job) => acquisitionToggles.add(job.id),
        ),
      );

      await tester.tap(_bookCard(linkedBook.id));
      await tester.tap(find.byType(AcquisitionPlaceholderCard));
      await tester.longPress(_bookCard(linkedBook.id));
      await tester.longPress(find.byType(AcquisitionPlaceholderCard));

      expect(acquisitionTaps, ['job-linked', 'job-orphan']);
      expect(acquisitionToggles, ['job-linked', 'job-orphan']);
      expect(bookTaps, isEmpty);
    });

    testWidgets('routes linked and orphan selection-mode taps to acquisition toggles', (tester) async {
      final linkedBook = _book(id: 'book-linked', title: 'Linked Book');
      final linkedJob = _job(id: 'job-linked', bookId: linkedBook.id, title: linkedBook.title);
      final orphanJob = _job(id: 'job-orphan', bookId: null, title: 'Orphan Book');
      final acquisitionTaps = <String>[];
      final acquisitionToggles = <String>[];

      await tester.pumpWidget(
        _buildGrid(
          books: [linkedBook],
          acquisitionJobsByBookId: {linkedBook.id: linkedJob},
          placeholderJobs: [orphanJob],
          selectedAcquisitionJobIds: const {'job-linked'},
          onAcquisitionTap: (job) => acquisitionTaps.add(job.id),
          onAcquisitionSelectionToggle: (job) => acquisitionToggles.add(job.id),
        ),
      );

      final linkedCard = tester.widget<BookCard>(_bookCard(linkedBook.id));
      final orphanCard = tester.widget<AcquisitionPlaceholderCard>(find.byType(AcquisitionPlaceholderCard));

      expect(linkedCard.isSelected, isTrue);
      expect(orphanCard.isSelected, isFalse);

      await tester.tap(_bookCard(linkedBook.id));
      await tester.tap(find.byType(AcquisitionPlaceholderCard));

      expect(acquisitionToggles, ['job-linked', 'job-orphan']);
      expect(acquisitionTaps, isEmpty);
    });

    testWidgets('does not open ordinary book actions for a linked job without callbacks', (tester) async {
      final linkedBook = _book(id: 'book-linked', title: 'Linked Book');
      final linkedJob = _job(id: 'job-linked', bookId: linkedBook.id, title: linkedBook.title);

      await tester.pumpWidget(_buildGrid(books: [linkedBook], acquisitionJobsByBookId: {linkedBook.id: linkedJob}));

      await tester.longPress(_bookCard(linkedBook.id));
      await tester.pumpAndSettle();

      expect(find.text('Select'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not use the ordinary tap callback for a linked job without an acquisition callback', (
      tester,
    ) async {
      final linkedBook = _book(id: 'book-linked', title: 'Linked Book');
      final linkedJob = _job(id: 'job-linked', bookId: linkedBook.id, title: linkedBook.title);
      final ordinaryTaps = <String>[];

      await tester.pumpWidget(
        _buildGrid(
          books: [linkedBook],
          acquisitionJobsByBookId: {linkedBook.id: linkedJob},
          onBookTap: (book) => ordinaryTaps.add(book.id),
        ),
      );

      await tester.tap(_bookCard(linkedBook.id));

      expect(ordinaryTaps, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not expose provider favorite mutation for linked jobs', (tester) async {
      final linkedBook = _book(id: 'book-linked', title: 'Linked Book');
      final ordinaryBook = _book(id: 'book-ordinary', title: 'Ordinary Book');
      final linkedJob = _job(id: 'job-linked', bookId: linkedBook.id, title: linkedBook.title);

      await tester.pumpWidget(
        _buildGrid(books: [linkedBook, ordinaryBook], acquisitionJobsByBookId: {linkedBook.id: linkedJob}),
      );

      final linkedCard = tester.widget<BookCard>(_bookCard(linkedBook.id));
      final ordinaryCard = tester.widget<BookCard>(_bookCard(ordinaryBook.id));

      expect(linkedCard.onToggleFavorite, isNull);
      expect(ordinaryCard.onToggleFavorite, isNotNull);
    });

    testWidgets('ordinary books keep ordinary taps and provider selection', (tester) async {
      final provider = LibraryProvider();
      final ordinary = _book(id: 'book-ordinary', title: 'Ordinary Book');
      final tappedBooks = <String>[];

      await tester.pumpWidget(
        _buildGrid(
          books: [ordinary],
          libraryProvider: provider,
          onBookTap: (book) => tappedBooks.add(book.id),
          onAcquisitionTap: (_) => fail('ordinary book used acquisition tap'),
          onAcquisitionSelectionToggle: (_) => fail('ordinary book used acquisition selection'),
        ),
      );

      await tester.tap(_bookCard(ordinary.id));

      expect(tappedBooks, [ordinary.id]);

      tester.widget<BookCard>(_bookCard(ordinary.id)).onEnterSelectionMode!.call();
      await tester.pump();

      expect(provider.isBookSelected(ordinary.id), isTrue);
    });

    testWidgets('keeps ordinary and acquisition selection state independent', (tester) async {
      final provider = LibraryProvider()..enterSelectionMode('book-ordinary');
      final ordinary = _book(id: 'book-ordinary', title: 'Ordinary Book');
      final linkedBook = _book(id: 'book-linked', title: 'Linked Book');
      final linkedJob = _job(id: 'job-linked', bookId: linkedBook.id, title: linkedBook.title);

      await tester.pumpWidget(
        _buildGrid(
          books: [ordinary, linkedBook],
          libraryProvider: provider,
          acquisitionJobsByBookId: {linkedBook.id: linkedJob},
        ),
      );

      final ordinaryCard = tester.widget<BookCard>(_bookCard(ordinary.id));
      final unselectedLinkedCard = tester.widget<BookCard>(_bookCard(linkedBook.id));

      expect(ordinaryCard.isSelectionMode, isTrue);
      expect(ordinaryCard.isSelected, isTrue);
      expect(unselectedLinkedCard.isSelectionMode, isFalse);
      expect(unselectedLinkedCard.isSelected, isFalse);

      await tester.pumpWidget(
        _buildGrid(
          books: [ordinary, linkedBook],
          libraryProvider: provider,
          acquisitionJobsByBookId: {linkedBook.id: linkedJob},
          selectedAcquisitionJobIds: const {'job-linked'},
        ),
      );

      final selectedLinkedCard = tester.widget<BookCard>(_bookCard(linkedBook.id));

      expect(selectedLinkedCard.isSelectionMode, isTrue);
      expect(selectedLinkedCard.isSelected, isTrue);
      expect(provider.isBookSelected(linkedBook.id), isFalse);
    });
  });

  group('BookGrid responsiveness', () {
    testWidgets('preserves responsive columns and matching item widths', (tester) async {
      final book = _book(id: 'book-1', title: 'Book');
      final orphan = _job(id: 'job-1', bookId: null, title: 'Orphan');

      for (final (width, columns) in const [(400.0, 2), (700.0, 4), (900.0, 5), (1300.0, 6)]) {
        await tester.pumpWidget(_buildGrid(books: [book], placeholderJobs: [orphan], screenSize: Size(width, 800)));

        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.crossAxisCount, columns);
        expect(tester.getSize(_bookCard(book.id)).width, tester.getSize(find.byType(AcquisitionPlaceholderCard)).width);
        expect(
          tester.getSize(_bookCard(book.id)).height,
          tester.getSize(find.byType(AcquisitionPlaceholderCard)).height,
        );
      }
    });
  });
}

Widget _buildGrid({
  required List<Book> books,
  LibraryProvider? libraryProvider,
  ValueChanged<Book>? onBookTap,
  Map<String, AcquisitionJob> acquisitionJobsByBookId = const {},
  List<AcquisitionJob> placeholderJobs = const [],
  Set<String> selectedAcquisitionJobIds = const {},
  ValueChanged<AcquisitionJob>? onAcquisitionTap,
  ValueChanged<AcquisitionJob>? onAcquisitionSelectionToggle,
  Size screenSize = const Size(400, 800),
}) {
  return ChangeNotifierProvider<LibraryProvider>.value(
    value: libraryProvider ?? LibraryProvider(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Scaffold(
              body: BookGrid(
                books: books,
                libraryViewMode: LibraryViewMode.smallGrid,
                onBookTap: onBookTap,
                acquisitionJobsByBookId: acquisitionJobsByBookId,
                placeholderJobs: placeholderJobs,
                selectedAcquisitionJobIds: selectedAcquisitionJobIds,
                onAcquisitionTap: onAcquisitionTap,
                onAcquisitionSelectionToggle: onAcquisitionSelectionToggle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _bookCard(String bookId) {
  return find.byWidgetPredicate((widget) => widget is BookCard && widget.book.id == bookId);
}

Book _book({required String id, required String title}) {
  return Book(
    id: id,
    title: title,
    author: 'Author',
    readingStatus: LibraryReadingStatus.unread,
    currentPosition: 0,
    isFavorite: false,
    fileFormat: BookFormat.epub,
    addedAt: DateTime(2026),
  );
}

AcquisitionJob _job({required String id, required String? bookId, required String title}) {
  return AcquisitionJob(
    id: id,
    endpointId: 'endpoint-1',
    ruleId: null,
    bookId: bookId,
    title: title,
    status: AcquisitionJobStatus.downloading,
    clientReference: null,
    clientHash: 'hash-$id',
    clientState: 'downloading',
    progressBasisPoints: 4200,
    downloadedBytes: 420,
    totalBytes: 1000,
    downloadSpeedBytesPerSecond: null,
    etaSeconds: null,
    selectedFilePath: null,
    retryCount: 0,
    error: null,
    nextPollAt: null,
    createdAt: null,
    updatedAt: null,
    submittedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
  );
}
