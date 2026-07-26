import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/book/private_book_cover.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_list_item.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';

void main() {
  group('AcquisitionPlaceholderListItem', () {
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
        await tester.pumpWidget(_buildListItem(job: _job(status: entry.key)));

        expect(find.text('A Downloading Book'), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('shows real progress, speed, and ETA', (tester) async {
      await tester.pumpWidget(
        _buildListItem(
          job: _job(status: AcquisitionJobStatus.downloading, speed: 1536 * 1024, etaSeconds: 180),
        ),
      );

      expect(find.text('Downloading 42%'), findsOneWidget);
      expect(find.text('1.5 MB/s · 3 min remaining'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.42);
    });

    testWidgets('does not show indeterminate or fake progress', (tester) async {
      await tester.pumpWidget(
        _buildListItem(job: _job(status: AcquisitionJobStatus.downloading, progressBasisPoints: null)),
      );

      expect(find.text('Downloading'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('0%'), findsNothing);
    });

    testWidgets('shows stable failed status without leaking the raw error', (tester) async {
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(_buildListItem(job: _job(status: AcquisitionJobStatus.failed)));

        final status = tester.widget<Text>(find.text('Download failed'));
        final node = tester.getSemantics(find.byKey(const ValueKey('acquisition-placeholder-list-item-job-1')));

        expect(find.text('Disk full'), findsNothing);
        expect(node.label, isNot(contains('Disk full')));
        expect(status.style?.color, AppTheme.light.colorScheme.error);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('uses a neutral cover rather than release artwork', (tester) async {
      await tester.pumpWidget(_buildListItem(job: _job()));

      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byType(CoverImage), findsNothing);
    });

    testWidgets('exposes tap, long press, and selected semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      var longPresses = 0;

      try {
        await tester.pumpWidget(
          _buildListItem(
            job: _job(),
            isSelected: true,
            onTap: () => taps += 1,
            onEnterSelectionMode: () => longPresses += 1,
          ),
        );

        final finder = find.byKey(const ValueKey('acquisition-placeholder-list-item-job-1'));
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
        _buildListItem(job: _job(), isSelectionMode: true, onTap: () => taps += 1, onSelectToggle: () => toggles += 1),
      );

      await tester.tap(find.byKey(const ValueKey('acquisition-placeholder-list-item-job-1')));

      expect(taps, 0);
      expect(toggles, 1);
    });

    testWidgets('without callbacks has no button role or actions', (tester) async {
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(_buildListItem(job: _job()));

        final node = tester.getSemantics(find.byKey(const ValueKey('acquisition-placeholder-list-item-job-1')));

        expect(node.flagsCollection.isButton, isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isFalse);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('selected treatment matches an ordinary list item', (tester) async {
      final book = Book(
        id: 'book-1',
        title: 'A Book',
        author: 'An Author',
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0,
        isFavorite: false,
        fileFormat: BookFormat.epub,
        addedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                BookListItem(book: book, isFavorite: false, isSelectionMode: true, isSelected: true),
                AcquisitionPlaceholderListItem(job: _job(), isSelectionMode: true, isSelected: true),
              ],
            ),
          ),
        ),
      );

      final bookRoot = find.byType(BookListItem);
      final placeholderRoot = find.byType(AcquisitionPlaceholderListItem);
      final bookMaterial = tester.widget<Material>(
        find.descendant(of: bookRoot, matching: find.byType(Material)).first,
      );
      final placeholderMaterial = tester.widget<Material>(
        find.descendant(of: placeholderRoot, matching: find.byType(Material)).first,
      );
      final bookContainer = tester.widget<Container>(
        find.descendant(of: bookRoot, matching: find.byType(Container)).first,
      );
      final placeholderContainer = tester.widget<Container>(
        find.descendant(of: placeholderRoot, matching: find.byType(Container)).first,
      );

      expect(placeholderMaterial.color, bookMaterial.color);
      expect(placeholderContainer.decoration, bookContainer.decoration);
    });

    testWidgets('fits a narrow row with large text', (tester) async {
      await tester.pumpWidget(
        _buildListItem(
          job: _job(
            title: 'A very long downloading book title that must remain compact',
            speed: 1536 * 1024,
            etaSeconds: 180,
          ),
          width: 240,
          textScaler: const TextScaler.linear(2),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Widget _buildListItem({
  required AcquisitionJob job,
  VoidCallback? onTap,
  VoidCallback? onSelectToggle,
  VoidCallback? onEnterSelectionMode,
  bool isSelectionMode = false,
  bool isSelected = false,
  double width = 400,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800), textScaler: textScaler),
      child: Scaffold(
        body: SizedBox(
          width: width,
          child: AcquisitionPlaceholderListItem(
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
