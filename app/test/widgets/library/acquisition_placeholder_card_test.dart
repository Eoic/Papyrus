import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/book/private_book_cover.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_card.dart';
import 'package:papyrus/widgets/library/acquisition_status_text.dart';
import 'package:papyrus/widgets/library/book_card.dart';

void main() {
  group('acquisition status formatting', () {
    const expectedLabels = {
      AcquisitionJobStatus.queued: 'Queued',
      AcquisitionJobStatus.submitted: 'Queued',
      AcquisitionJobStatus.downloading: 'Downloading 42%',
      AcquisitionJobStatus.needsFileSelection: 'Needs attention',
      AcquisitionJobStatus.importing: 'Adding to library',
      AcquisitionJobStatus.completed: 'Finishing import',
      AcquisitionJobStatus.failed: 'Download failed',
      AcquisitionJobStatus.cancelled: 'Cancelled',
      AcquisitionJobStatus.unknown: 'Needs attention',
    };

    for (final entry in expectedLabels.entries) {
      test('formats ${entry.key.name}', () {
        expect(acquisitionStatusLabel(_job(status: entry.key)), entry.value);
      });
    }

    test('does not invent downloading progress', () {
      expect(
        acquisitionStatusLabel(_job(status: AcquisitionJobStatus.downloading, progressBasisPoints: null)),
        'Downloading',
      );
    });

    test('formats binary byte units with stable precision', () {
      expect(formatBytes(null), '—');
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(10 * 1024), '10 KB');
      expect(formatBytes(1024 * 1024), '1.0 MB');
    });

    test('formats speed and ETA', () {
      expect(formatSpeed(1536), '1.5 KB/s');
      expect(formatSpeed(2 * 1024 * 1024), '2.0 MB/s');
      expect(formatEta(45), '45 sec remaining');
      expect(formatEta(180), '3 min remaining');
      expect(formatEta(7200), '2 hr remaining');
    });
  });

  group('AcquisitionPlaceholderCard', () {
    const expectedLabels = {
      AcquisitionJobStatus.queued: 'Queued',
      AcquisitionJobStatus.submitted: 'Queued',
      AcquisitionJobStatus.downloading: 'Downloading 42%',
      AcquisitionJobStatus.needsFileSelection: 'Needs attention',
      AcquisitionJobStatus.importing: 'Adding to library',
      AcquisitionJobStatus.completed: 'Finishing import',
      AcquisitionJobStatus.failed: 'Download failed',
      AcquisitionJobStatus.cancelled: 'Cancelled',
      AcquisitionJobStatus.unknown: 'Needs attention',
    };

    for (final entry in expectedLabels.entries) {
      testWidgets('renders ${entry.key.name}', (tester) async {
        await tester.pumpWidget(_buildCard(job: _job(status: entry.key)));

        expect(find.text('A Downloading Book'), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('shows real progress, speed, and ETA', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          job: _job(status: AcquisitionJobStatus.downloading, speed: 1536 * 1024, etaSeconds: 180),
        ),
      );

      expect(find.text('Downloading 42%'), findsOneWidget);
      expect(find.text('1.5 MB/s · 3 min remaining'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.42);
    });

    testWidgets('does not show indeterminate or fake progress', (tester) async {
      await tester.pumpWidget(
        _buildCard(job: _job(status: AcquisitionJobStatus.downloading, progressBasisPoints: null)),
      );

      expect(find.text('Downloading'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('0%'), findsNothing);
    });

    testWidgets('shows stable failed status without leaking the raw error', (tester) async {
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(_buildCard(job: _job(status: AcquisitionJobStatus.failed)));

        final status = tester.widget<Text>(find.text('Download failed'));
        final node = tester.getSemantics(find.byKey(const ValueKey('acquisition-placeholder-card-job-1')));

        expect(find.text('Disk full'), findsNothing);
        expect(node.label, isNot(contains('Disk full')));
        expect(status.style?.color, AppTheme.light.colorScheme.error);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('uses a neutral cover rather than release artwork', (tester) async {
      await tester.pumpWidget(_buildCard(job: _job()));

      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byType(CoverImage), findsNothing);
    });

    testWidgets('exposes tap, long press, and selected semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      var longPresses = 0;

      try {
        await tester.pumpWidget(
          _buildCard(
            job: _job(),
            isSelected: true,
            onTap: () => taps += 1,
            onEnterSelectionMode: () => longPresses += 1,
          ),
        );

        final finder = find.byKey(const ValueKey('acquisition-placeholder-card-job-1'));
        final node = tester.getSemantics(finder);

        expect(node.label, contains('A Downloading Book'));
        expect(node.label, contains('Downloading 42%'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);

        await tester.tap(finder);
        await tester.longPress(finder);

        expect(taps, 1);
        expect(longPresses, 1);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('selection mode routes tap to selection toggle', (tester) async {
      var taps = 0;
      var toggles = 0;

      await tester.pumpWidget(
        _buildCard(job: _job(), isSelectionMode: true, onTap: () => taps += 1, onSelectToggle: () => toggles += 1),
      );

      await tester.tap(find.byKey(const ValueKey('acquisition-placeholder-card-job-1')));

      expect(taps, 0);
      expect(toggles, 1);
    });

    testWidgets('desktop selector has its own action and does not open details', (tester) async {
      final semantics = tester.ensureSemantics();
      var details = 0;
      var selections = 0;

      try {
        await tester.pumpWidget(
          _buildCard(
            job: _job(status: AcquisitionJobStatus.cancelled),
            onTap: () => details += 1,
            onEnterSelectionMode: () => selections += 1,
            size: const Size(240, 360),
            screenSize: const Size(1200, 800),
          ),
        );

        tester.semantics.tap(find.semantics.byLabel('Select A Downloading Book'));
        await tester.tap(find.byKey(const ValueKey('acquisition-selector-job-1')));

        expect(selections, 2);
        expect(details, 0);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('without callbacks has no button role or actions', (tester) async {
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(_buildCard(job: _job()));

        final node = tester.getSemantics(find.byKey(const ValueKey('acquisition-placeholder-card-job-1')));

        expect(node.flagsCollection.isButton, isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isFalse);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('matches selected BookCard Card treatment in the light theme', (tester) async {
      await tester.pumpWidget(_buildCardPair(theme: AppTheme.light));

      _expectCardParity(tester, AppTheme.light);
    });

    testWidgets('matches selected BookCard Card treatment in the e-ink theme', (tester) async {
      await tester.pumpWidget(_buildCardPair(theme: AppTheme.eink));

      _expectCardParity(tester, AppTheme.eink);
    });

    testWidgets('fits a narrow card with large text', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          job: _job(
            title: 'A very long downloading book title that must remain compact',
            speed: 1536 * 1024,
            etaSeconds: 180,
          ),
          size: const Size(150, 300),
          textScaler: const TextScaler.linear(2),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Widget _buildCardPair({required ThemeData theme}) {
  final book = Book(
    id: 'book-1',
    title: 'A Synchronized Book',
    author: 'An Author',
    readingStatus: ReadingStatus.notStarted,
    currentPosition: 0,
    isFavorite: false,
    fileFormat: BookFormat.epub,
    addedAt: DateTime(2026),
  );

  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: Scaffold(
        body: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          children: [
            BookCard(book: book, isFavorite: false, isSelectionMode: true, isSelected: true),
            AcquisitionPlaceholderCard(job: _job(), isSelectionMode: true, isSelected: true),
          ],
        ),
      ),
    ),
  );
}

void _expectCardParity(WidgetTester tester, ThemeData theme) {
  final bookRoot = find.byType(BookCard);
  final placeholderRoot = find.byType(AcquisitionPlaceholderCard);
  final bookCard = tester.widget<Card>(find.descendant(of: bookRoot, matching: find.byType(Card)));
  final placeholderCard = tester.widget<Card>(find.descendant(of: placeholderRoot, matching: find.byType(Card)));
  final bookMaterial = tester.widget<Material>(_cardMaterial(bookRoot));
  final placeholderMaterial = tester.widget<Material>(_cardMaterial(placeholderRoot));
  final bookMargin = tester.widget<Padding>(find.descendant(of: bookRoot, matching: find.byType(Padding)).first);
  final placeholderMargin = tester.widget<Padding>(
    find.descendant(of: placeholderRoot, matching: find.byType(Padding)).first,
  );
  final selectionColor = theme.colorScheme.primary.withValues(alpha: 0.15);

  expect(tester.getSize(bookRoot), tester.getSize(placeholderRoot));
  expect(placeholderCard.margin, bookCard.margin);
  expect(placeholderCard.elevation, bookCard.elevation);
  expect(placeholderCard.clipBehavior, bookCard.clipBehavior);
  expect(placeholderCard.shape, bookCard.shape);
  expect(placeholderMaterial.shape, bookMaterial.shape);
  expect(placeholderMaterial.elevation, bookMaterial.elevation);
  expect(bookMaterial.elevation, theme.cardTheme.elevation);
  expect(placeholderMaterial.elevation, theme.cardTheme.elevation);
  expect(placeholderMaterial.clipBehavior, bookMaterial.clipBehavior);
  expect(bookMargin.padding, theme.cardTheme.margin);
  expect(placeholderMargin.padding, theme.cardTheme.margin);
  expect(_selectionTint(bookRoot, selectionColor), findsOneWidget);
  expect(_selectionTint(placeholderRoot, selectionColor), findsOneWidget);
}

Finder _cardMaterial(Finder root) {
  return find
      .descendant(
        of: root,
        matching: find.byWidgetPredicate((widget) => widget is Material && widget.type == MaterialType.card),
      )
      .first;
}

Finder _selectionTint(Finder root, Color color) {
  return find.descendant(
    of: root,
    matching: find.byWidgetPredicate((widget) => widget is Container && widget.color == color),
  );
}

Widget _buildCard({
  required AcquisitionJob job,
  VoidCallback? onTap,
  VoidCallback? onSelectToggle,
  VoidCallback? onEnterSelectionMode,
  bool isSelectionMode = false,
  bool isSelected = false,
  Size size = const Size(200, 300),
  Size screenSize = const Size(400, 800),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(size: screenSize, textScaler: textScaler),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: AcquisitionPlaceholderCard(
              job: job,
              onTap: onTap,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onSelectToggle: onSelectToggle,
              onEnterSelectionMode: onEnterSelectionMode,
            ),
          ),
        ),
      ),
    ),
  );
}

AcquisitionJob _job({
  AcquisitionJobStatus status = AcquisitionJobStatus.downloading,
  String title = 'A Downloading Book',
  int? progressBasisPoints = 4200,
  int? speed,
  int? etaSeconds,
}) {
  return AcquisitionJob(
    id: 'job-1',
    endpointId: 'endpoint-1',
    ruleId: null,
    bookId: null,
    title: title,
    status: status,
    clientReference: null,
    clientHash: 'hash-1',
    clientState: status.apiValue,
    progressBasisPoints: progressBasisPoints,
    downloadedBytes: 420,
    totalBytes: 1000,
    downloadSpeedBytesPerSecond: speed,
    etaSeconds: etaSeconds,
    selectedFilePath: null,
    retryCount: 0,
    error: status == AcquisitionJobStatus.failed ? 'Disk full' : null,
    nextPollAt: null,
    createdAt: null,
    updatedAt: null,
    submittedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
  );
}
