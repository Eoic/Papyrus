import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/widgets/book/private_book_cover.dart';
import 'package:papyrus/widgets/library/book_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BookCard', () {
    late Book testBook;

    setUp(() {
      testBook = Book(
        id: 'book-1',
        title: 'The Hobbit',
        author: 'J.R.R. Tolkien',
        readingStatus: ReadingStatus.inProgress,
        currentPosition: 0.5,
        isFavorite: false,
        fileFormat: BookFormat.epub,
        addedAt: DateTime.now(),
      );
    });

    Widget buildCard({
      Book? book,
      bool isFavorite = false,
      void Function(bool)? onToggleFavorite,
      VoidCallback? onTap,
      bool showProgress = true,
      AcquisitionJob? acquisitionJob,
    }) {
      return createTestApp(
        child: SizedBox(
          width: 200,
          height: 300,
          child: BookCard(
            book: book ?? testBook,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            onTap: onTap,
            showProgress: showProgress,
            acquisitionJob: acquisitionJob,
          ),
        ),
      );
    }

    testWidgets('displays book title', (tester) async {
      await tester.pumpWidget(buildCard());
      // Title appears in both the bottom text and the placeholder cover
      expect(find.text('The Hobbit'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays book author', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('J.R.R. Tolkien'), findsOneWidget);
    });

    testWidgets('displays format badge', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('displays physical format label', (tester) async {
      final physicalBook = testBook.copyWith(isPhysical: true);
      await tester.pumpWidget(buildCard(book: physicalBook));
      expect(find.text('Physical'), findsOneWidget);
    });

    testWidgets('shows progress bar when progress > 0', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress bar when showProgress is false', (tester) async {
      await tester.pumpWidget(buildCard(showProgress: false));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('hides progress bar when progress is 0', (tester) async {
      final noProgressBook = testBook.copyWith(currentPosition: 0.0);
      await tester.pumpWidget(buildCard(book: noProgressBook));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows compact acquisition progress for a downloading placeholder', (tester) async {
      await tester.pumpWidget(
        buildCard(
          book: testBook.copyWith(currentPosition: 0),
          acquisitionJob: _acquisitionJob(downloadSpeedBytesPerSecond: 1536 * 1024, etaSeconds: 180),
        ),
      );

      expect(find.text('Downloading 50%'), findsOneWidget);
      expect(find.text('1.5 MB/s · 3 min remaining'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.5);
    });

    testWidgets('uses shared acquisition status labels', (tester) async {
      await tester.pumpWidget(
        buildCard(
          book: testBook.copyWith(currentPosition: 0),
          acquisitionJob: _acquisitionJob(status: AcquisitionJobStatus.completed),
        ),
      );

      expect(find.text('Finishing import'), findsOneWidget);
      expect(find.text('Downloaded'), findsNothing);
    });

    testWidgets('does not invent acquisition progress', (tester) async {
      await tester.pumpWidget(buildCard(book: testBook, acquisitionJob: _acquisitionJob(progressBasisPoints: null)));

      expect(find.text('Downloading'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows unfilled heart when not favorite', (tester) async {
      await tester.pumpWidget(buildCard(isFavorite: false));
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('shows filled heart when favorite', (tester) async {
      await tester.pumpWidget(buildCard(isFavorite: true));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('calls onToggleFavorite when favorite button tapped', (tester) async {
      bool? tappedValue;
      await tester.pumpWidget(buildCard(isFavorite: false, onToggleFavorite: (current) => tappedValue = current));

      // Find and tap the favorite button (InkWell wrapping the heart icon)
      final favoriteIcon = find.byIcon(Icons.favorite_border);
      expect(favoriteIcon, findsOneWidget);
      await tester.tap(favoriteIcon);
      await tester.pump();

      expect(tappedValue, false);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('forwards the book id to the cover renderer', (tester) async {
      await tester.pumpWidget(buildCard());

      expect(tester.widget<CoverImage>(find.byType(CoverImage)).bookId, testBook.id);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(Card), findsOneWidget);
    });
  });
}

AcquisitionJob _acquisitionJob({
  AcquisitionJobStatus status = AcquisitionJobStatus.downloading,
  int? progressBasisPoints = 5000,
  int? downloadSpeedBytesPerSecond = 128,
  int? etaSeconds = 4,
}) {
  return AcquisitionJob(
    id: 'job-1',
    endpointId: 'endpoint-1',
    ruleId: null,
    bookId: 'book-1',
    title: 'The Hobbit',
    status: status,
    clientReference: null,
    clientHash: 'hash-1',
    clientState: 'downloading',
    progressBasisPoints: progressBasisPoints,
    downloadedBytes: 512,
    totalBytes: 1024,
    downloadSpeedBytesPerSecond: downloadSpeedBytesPerSecond,
    etaSeconds: etaSeconds,
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
