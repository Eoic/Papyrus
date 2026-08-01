import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/themes/app_theme.dart';
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
        readingStatus: LibraryReadingStatus.inProgress,
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
      VoidCallback? onSelectToggle,
      VoidCallback? onEnterSelectionMode,
      bool showProgress = true,
      bool isSelectionMode = false,
      bool isSelected = false,
      AcquisitionJob? acquisitionJob,
      Size cardSize = const Size(200, 300),
      Size screenSize = const Size(400, 800),
      ThemeData? theme,
    }) {
      final card = SizedBox(
        width: cardSize.width,
        height: cardSize.height,
        child: BookCard(
          book: book ?? testBook,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          onTap: onTap,
          onSelectToggle: onSelectToggle,
          onEnterSelectionMode: onEnterSelectionMode,
          showProgress: showProgress,
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          acquisitionJob: acquisitionJob,
        ),
      );

      if (theme == null) {
        return createTestApp(child: card, screenSize: screenSize);
      }

      return MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: card),
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

    testWidgets('hides ordinary desktop menu for linked jobs only', (tester) async {
      await tester.pumpWidget(buildCard(acquisitionJob: _acquisitionJob(), screenSize: const Size(900, 800)));

      expect(find.byIcon(Icons.more_vert), findsNothing);

      await tester.pumpWidget(buildCard(screenSize: const Size(900, 800)));

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('fits a narrow linked card without the format badge', (tester) async {
      await tester.pumpWidget(
        buildCard(acquisitionJob: _acquisitionJob(progressBasisPoints: 4200), cardSize: const Size(150, 300)),
      );

      final status = tester.widget<Text>(find.text('Downloading 42%'));

      expect(find.text('EPUB'), findsNothing);
      expect(status.maxLines, 1);
      expect(status.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a narrow e-ink linked card with a long status', (tester) async {
      await tester.pumpWidget(
        buildCard(
          acquisitionJob: _acquisitionJob(status: AcquisitionJobStatus.importing, progressBasisPoints: null),
          cardSize: const Size(150, 300),
          theme: AppTheme.eink,
        ),
      );

      final status = tester.widget<Text>(find.text('Adding to library'));

      expect(find.text('EPUB'), findsNothing);
      expect(status.maxLines, 1);
      expect(status.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes one selected linked acquisition action', (tester) async {
      final semantics = tester.ensureSemantics();
      var selections = 0;

      try {
        await tester.pumpWidget(
          buildCard(
            acquisitionJob: _acquisitionJob(),
            isSelectionMode: true,
            isSelected: true,
            onSelectToggle: () => selections += 1,
          ),
        );

        final finder = find.byKey(const ValueKey('linked-acquisition-book-card-job-1'));
        final node = tester.getSemantics(finder);
        final interactiveNodes = find.semantics
            .byPredicate((candidate) => candidate.getSemanticsData().hasAction(SemanticsAction.tap))
            .evaluate();

        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(interactiveNodes, hasLength(1));

        tester.semantics.tap(find.semantics.byLabel(node.label));

        expect(selections, 1);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('linked acquisition without callbacks has state but no button action', (tester) async {
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(buildCard(acquisitionJob: _acquisitionJob(), isSelected: true));

        final node = tester.getSemantics(find.byKey(const ValueKey('linked-acquisition-book-card-job-1')));

        expect(node.flagsCollection.isButton, isFalse);
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isFalse);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('linked acquisition selector has its own action and does not open details', (tester) async {
      final semantics = tester.ensureSemantics();
      var details = 0;
      var selections = 0;

      try {
        await tester.pumpWidget(
          buildCard(
            acquisitionJob: _acquisitionJob(status: AcquisitionJobStatus.cancelled),
            onTap: () => details += 1,
            onEnterSelectionMode: () => selections += 1,
            screenSize: const Size(1200, 800),
          ),
        );

        tester.semantics.tap(find.semantics.byLabel('Select The Hobbit'));
        await tester.tap(find.byIcon(Icons.radio_button_unchecked));

        expect(selections, 2);
        expect(details, 0);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('linked acquisition stays hovered over its selection control', (tester) async {
      await tester.pumpWidget(
        buildCard(
          acquisitionJob: _acquisitionJob(status: AcquisitionJobStatus.cancelled),
          onEnterSelectionMode: () {},
          screenSize: const Size(1200, 800),
        ),
      );

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: tester.getCenter(find.byType(BookCard)));
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);

      await pointer.moveTo(tester.getCenter(find.byKey(const ValueKey('acquisition-selector-job-1'))));
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
    });

    testWidgets('linked acquisition hides favorite and exposes only its acquisition action', (tester) async {
      final semantics = tester.ensureSemantics();
      var acquisitionTaps = 0;
      var favoriteTaps = 0;

      try {
        await tester.pumpWidget(
          buildCard(
            acquisitionJob: _acquisitionJob(),
            onTap: () => acquisitionTaps += 1,
            onToggleFavorite: (_) => favoriteTaps += 1,
          ),
        );

        final finder = find.byKey(const ValueKey('linked-acquisition-book-card-job-1'));
        final node = tester.getSemantics(finder);
        final interactiveNodes = find.semantics
            .byPredicate((candidate) => candidate.getSemanticsData().hasAction(SemanticsAction.tap))
            .evaluate();

        expect(find.byIcon(Icons.favorite_border), findsNothing);
        expect(find.byIcon(Icons.favorite), findsNothing);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(interactiveNodes, hasLength(1));

        tester.semantics.tap(find.semantics.byLabel(node.label));

        expect(acquisitionTaps, 1);
        expect(favoriteTaps, 0);
      } finally {
        semantics.dispose();
      }
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
