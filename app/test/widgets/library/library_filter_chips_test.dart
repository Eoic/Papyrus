import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/shared/quick_filter_chips.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('LibraryFilterChips', () {
    late LibraryProvider libraryProvider;

    setUp(() {
      libraryProvider = LibraryProvider();
    });

    Widget buildChips({
      LibraryProvider? provider,
      bool showDownloading = false,
      bool isDownloadingSelected = false,
      VoidCallback? onDownloadingTapped,
      VoidCallback? onLibraryFilterTapped,
    }) {
      return createTestApp(
        libraryProvider: provider ?? libraryProvider,
        screenSize: const Size(1000, 800),
        child: LibraryFilterChips(
          showDownloading: showDownloading,
          isDownloadingSelected: isDownloadingSelected,
          onDownloadingTapped: onDownloadingTapped,
          onLibraryFilterTapped: onLibraryFilterTapped,
        ),
      );
    }

    testWidgets('displays all five filter chips', (tester) async {
      await tester.pumpWidget(buildChips());

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
    });

    testWidgets('"All" chip is selected by default', (tester) async {
      await tester.pumpWidget(buildChips());

      final allChip = tester.widget<FilterChip>(find.ancestor(of: find.text('All'), matching: find.byType(FilterChip)));
      expect(allChip.selected, true);
    });

    testWidgets('tapping "Reading" chip toggles reading filter', (tester) async {
      await tester.pumpWidget(buildChips());

      await tester.tap(find.text('Reading'));
      await tester.pumpAndSettle();

      expect(libraryProvider.isFilterActive(LibraryFilterType.reading), true);
      expect(libraryProvider.isFilterActive(LibraryFilterType.all), false);
    });

    testWidgets('tapping "Favorites" chip toggles favorites filter', (tester) async {
      await tester.pumpWidget(buildChips());

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(libraryProvider.isFilterActive(LibraryFilterType.favorites), true);
    });

    testWidgets('tapping "Finished" chip toggles finished filter', (tester) async {
      await tester.pumpWidget(buildChips());

      await tester.tap(find.text('Finished'));
      await tester.pumpAndSettle();

      expect(libraryProvider.isFilterActive(LibraryFilterType.finished), true);
    });

    testWidgets('tapping "Unread" chip toggles unread filter', (tester) async {
      await tester.pumpWidget(buildChips());

      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      expect(libraryProvider.isFilterActive(LibraryFilterType.unread), true);
    });

    testWidgets('tapping "All" chip resets all filters', (tester) async {
      // First set some filters
      libraryProvider.addFilter(LibraryFilterType.reading);
      libraryProvider.addFilter(LibraryFilterType.favorites);

      await tester.pumpWidget(buildChips());

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(libraryProvider.isFilterActive(LibraryFilterType.all), true);
      expect(libraryProvider.isFilterActive(LibraryFilterType.reading), false);
      expect(libraryProvider.isFilterActive(LibraryFilterType.favorites), false);
    });

    testWidgets('tapping a filter chip twice deactivates it', (tester) async {
      await tester.pumpWidget(buildChips());

      // Tap to activate
      await tester.tap(find.text('Reading'));
      await tester.pumpAndSettle();
      expect(libraryProvider.isFilterActive(LibraryFilterType.reading), true);

      // Tap to deactivate
      await tester.tap(find.text('Reading'));
      await tester.pumpAndSettle();
      expect(libraryProvider.isFilterActive(LibraryFilterType.reading), false);
      // Should fall back to "all"
      expect(libraryProvider.isFilterActive(LibraryFilterType.all), true);
    });

    testWidgets('filter chip icons are present', (tester) async {
      await tester.pumpWidget(buildChips());

      expect(find.byIcon(Icons.apps), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('chips are horizontally scrollable', (tester) async {
      await tester.pumpWidget(buildChips());

      // ListView should be present with horizontal scrolling
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('does not show Downloading by default', (tester) async {
      await tester.pumpWidget(buildChips());

      expect(find.text('Downloading'), findsNothing);
    });

    testWidgets('shows Downloading after the library filters when requested', (tester) async {
      await tester.pumpWidget(buildChips(showDownloading: true));

      final chips = tester.widget<QuickFilterChips>(find.byType(QuickFilterChips));
      final labels = chips.filters.map((filter) => filter.label).toList();

      expect(labels, ['All', 'Reading', 'Favorites', 'Finished', 'Unread', 'Downloading']);
    });

    testWidgets('shows Downloading as the only selected chip', (tester) async {
      await tester.pumpWidget(buildChips(showDownloading: true, isDownloadingSelected: true));

      final chips = tester.widget<QuickFilterChips>(find.byType(QuickFilterChips));
      final allChip = chips.filters.first;
      final downloadingChip = chips.filters.last;

      expect(downloadingChip.isSelected, isTrue);
      expect(allChip.isSelected, isFalse);
      expect(chips.filters.where((filter) => filter.isSelected), [downloadingChip]);
    });

    testWidgets('selecting Downloading resets library filters before dispatching its callback', (tester) async {
      var downloadingTaps = 0;
      var libraryFilterTaps = 0;
      libraryProvider.addFilter(LibraryFilterType.reading);

      await tester.pumpWidget(
        buildChips(
          showDownloading: true,
          onDownloadingTapped: () => downloadingTaps++,
          onLibraryFilterTapped: () => libraryFilterTaps++,
        ),
      );

      final chips = tester.widget<QuickFilterChips>(find.byType(QuickFilterChips));
      chips.onFilterTapped(chips.filters.length - 1);
      await tester.pump();

      expect(downloadingTaps, 1);
      expect(libraryFilterTaps, 0);
      expect(libraryProvider.activeFilters, {LibraryFilterType.all});
    });

    testWidgets('dispatches ordinary chips through the provider and callback', (tester) async {
      var downloadingTaps = 0;
      var libraryFilterTaps = 0;

      await tester.pumpWidget(
        buildChips(
          showDownloading: true,
          onDownloadingTapped: () => downloadingTaps++,
          onLibraryFilterTapped: () => libraryFilterTaps++,
        ),
      );

      await tester.tap(find.text('Reading'));
      await tester.pump();

      expect(downloadingTaps, 0);
      expect(libraryFilterTaps, 1);
      expect(libraryProvider.activeFilters, {LibraryFilterType.reading});
    });
  });
}
