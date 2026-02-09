import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/add_book_provider.dart';
import 'package:papyrus/widgets/add_book/file_import_item_card.dart';
import 'package:papyrus/widgets/add_book/file_import_sheet.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a [FileImportItem] with minimal test data.
FileImportItem _testItem({
  String fileName = 'test.epub',
  FileImportStatus status = FileImportStatus.success,
  String title = 'Test Book',
  String author = 'Test Author',
  String? errorMessage,
}) {
  return FileImportItem(
    fileName: fileName,
    fileSize: 1024,
    bytes: Uint8List(0),
    format: BookFormat.epub,
    status: status,
    title: title,
    author: author,
    errorMessage: errorMessage,
  );
}

/// Builds the [ImportContent] widget inside a mobile-like bottom sheet context.
///
/// Uses [DraggableScrollableSheet] to reproduce the real constraints the widget
/// receives on mobile (scroll controller from the sheet, bounded height from the
/// sheet's fraction of screen).
Widget _buildMobileSheet({
  required AddBookProvider provider,
  DataStore? dataStore,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AddBookProvider>.value(value: provider),
      ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => SizedBox(
            width: 420,
            height: 800,
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => ImportContent(
                isDesktop: false,
                scrollController: scrollController,
                autoPick: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Builds the [ImportContent] widget inside a desktop-like dialog context.
///
/// Uses [ConstrainedBox] to reproduce the real constraints from the
/// Dialog + ConstrainedBox wrapper used in [FileImportSheet.show].
Widget _buildDesktopDialog({
  required AddBookProvider provider,
  DataStore? dataStore,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AddBookProvider>.value(value: provider),
      ChangeNotifierProvider<DataStore>.value(value: dataStore ?? DataStore()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
            child: const Material(
              child: ImportContent(isDesktop: true, autoPick: false),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FileImportSheet - mobile (DraggableScrollableSheet)', () {
    testWidgets('picking state renders without exceptions', (tester) async {
      final provider = AddBookProvider();
      provider.setTestState(isPicking: true);

      await tester.pumpWidget(_buildMobileSheet(provider: provider));
      await tester.pump();

      // Should show the picking spinner and header
      expect(find.text('Import digital books'), findsOneWidget);
      expect(find.text('Opening file picker...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Should show bottom sheet handle
      expect(find.byType(BottomSheetHandle), findsOneWidget);
      // No exceptions in the render tree
      expect(tester.takeException(), isNull);
    });

    testWidgets('processing state renders items and cancel button', (
      tester,
    ) async {
      final provider = AddBookProvider();
      provider.setTestState(
        isProcessing: true,
        processedCount: 1,
        items: [
          _testItem(status: FileImportStatus.success, fileName: 'book1.epub'),
          _testItem(
            status: FileImportStatus.extracting,
            fileName: 'book2.epub',
          ),
          _testItem(status: FileImportStatus.pending, fileName: 'book3.epub'),
        ],
      );

      await tester.pumpWidget(_buildMobileSheet(provider: provider));
      await tester.pump();

      // Should show the progress header
      expect(find.text('Importing 3 books'), findsOneWidget);
      expect(find.text('1 of 3 processed'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Scroll to cancel button to ensure it's reachable
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Cancel'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      // All 3 item cards should now be visible/built
      expect(
        find.byType(FileImportItemCard, skipOffstage: false),
        findsNWidgets(3),
      );

      // Cancel button is now visible
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('review state: footer buttons are reachable by scrolling', (
      tester,
    ) async {
      final provider = AddBookProvider();
      provider.setTestState(
        items: [
          _testItem(
            status: FileImportStatus.success,
            title: 'Good Book',
            author: 'Author A',
          ),
          _testItem(status: FileImportStatus.duplicate, fileName: 'dup.epub'),
          _testItem(
            status: FileImportStatus.error,
            fileName: 'bad.epub',
            errorMessage: 'Parse failed',
          ),
        ],
      );

      await tester.pumpWidget(_buildMobileSheet(provider: provider));
      await tester.pump();

      // Should show review header
      expect(find.text('Review imported book'), findsOneWidget);
      expect(find.text('1 of 3 books ready to add'), findsOneWidget);

      // Scroll to the "Add to library" button to verify it's reachable
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Add to library'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      // Both footer buttons must be visible after scrolling
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Add to library'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('FileImportSheet - desktop (Dialog)', () {
    testWidgets('picking state renders without exceptions', (tester) async {
      final provider = AddBookProvider();
      provider.setTestState(isPicking: true);

      await tester.pumpWidget(_buildDesktopDialog(provider: provider));
      await tester.pump();

      expect(find.text('Import digital books'), findsOneWidget);
      expect(find.text('Opening file picker...'), findsOneWidget);
      // No bottom sheet handle on desktop
      expect(find.byType(BottomSheetHandle), findsNothing);

      expect(tester.takeException(), isNull);
    });

    testWidgets('processing state renders items and cancel button', (
      tester,
    ) async {
      final provider = AddBookProvider();
      provider.setTestState(
        isProcessing: true,
        processedCount: 0,
        items: [
          _testItem(status: FileImportStatus.extracting, fileName: 'book1.pdf'),
          _testItem(status: FileImportStatus.pending, fileName: 'book2.pdf'),
        ],
      );

      await tester.pumpWidget(_buildDesktopDialog(provider: provider));
      await tester.pump();

      expect(find.text('Importing 2 books'), findsOneWidget);

      // Scroll to cancel button to ensure it's reachable
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Cancel'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(
        find.byType(FileImportItemCard, skipOffstage: false),
        findsNWidgets(2),
      );
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('review state: footer buttons are reachable by scrolling', (
      tester,
    ) async {
      final provider = AddBookProvider();
      provider.setTestState(
        items: [
          _testItem(
            status: FileImportStatus.success,
            title: 'Desktop Book',
            author: 'Author B',
          ),
        ],
      );

      await tester.pumpWidget(_buildDesktopDialog(provider: provider));
      await tester.pump();

      expect(find.text('Review imported book'), findsOneWidget);
      expect(find.byType(FileImportItemCard), findsOneWidget);

      // Scroll to the "Add to library" button
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Add to library'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Add to library'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('review with multiple successes shows correct button text', (
      tester,
    ) async {
      final provider = AddBookProvider();
      provider.setTestState(
        items: [
          _testItem(status: FileImportStatus.success, title: 'Book 1'),
          _testItem(status: FileImportStatus.success, title: 'Book 2'),
          _testItem(status: FileImportStatus.success, title: 'Book 3'),
        ],
      );

      await tester.pumpWidget(_buildDesktopDialog(provider: provider));
      await tester.pump();

      expect(find.text('Review imported books'), findsOneWidget);
      expect(find.text('3 of 3 books ready to add'), findsOneWidget);

      // Scroll to the multi-book button
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Add 3 books to library'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(
        find.widgetWithText(FilledButton, 'Add 3 books to library'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
