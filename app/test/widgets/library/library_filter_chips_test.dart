import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/library_filters.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/enums/library_sort_option.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('LibraryFilterChips', () {
    late LibraryProvider libraryProvider;

    setUp(() {
      libraryProvider = LibraryProvider();
    });

    tearDown(() {
      libraryProvider.dispose();
    });

    Widget buildChips() {
      return createTestApp(
        libraryProvider: libraryProvider,
        screenSize: const Size(1800, 800),
        child: const LibraryFilterChips(),
      );
    }

    Future<void> pumpChips(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildChips());
    }

    testWidgets('renders the current filter, sort, and view categories', (tester) async {
      await pumpChips(tester);

      expect(find.text('Status'), findsOneWidget);
      expect(find.text(LibrarySortOption.dateAddedNewest.label), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Topic'), findsOneWidget);
      expect(find.text('Shelf'), findsOneWidget);
      expect(find.text(LibraryViewMode.smallGrid.label), findsOneWidget);
    });

    testWidgets('uses a horizontal list with fixed height', (tester) async {
      await pumpChips(tester);

      final listView = tester.widget<ListView>(find.byType(ListView));
      final container = tester.widget<SizedBox>(
        find.ancestor(of: find.byType(AnimatedSwitcher), matching: find.byType(SizedBox)).first,
      );

      expect(listView.scrollDirection, Axis.horizontal);
      expect(container.height, 48);
    });

    testWidgets('shows active multi-select categories first with a count label', (tester) async {
      libraryProvider.setStatusFilters({LibraryReadingStatus.inProgress, LibraryReadingStatus.completed});

      await pumpChips(tester);

      expect(find.text('Status · 2'), findsOneWidget);
      expect(libraryProvider.activeFilterCount, 1);
    });

    testWidgets('favorite selection sheet updates the shared filter model', (tester) async {
      await pumpChips(tester);

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Favorite state'), findsOneWidget);

      await tester.tap(find.text('Favorites').last);
      await tester.pumpAndSettle();

      expect(libraryProvider.favoriteFilter, FavoriteFilter.favorites);
    });

    testWidgets('view selection sheet updates the shared view mode', (tester) async {
      await pumpChips(tester);

      await tester.tap(find.text(LibraryViewMode.smallGrid.label));
      await tester.pumpAndSettle();
      expect(find.text('View mode'), findsOneWidget);

      await tester.tap(find.text(LibraryViewMode.list.label).last);
      await tester.pumpAndSettle();

      expect(libraryProvider.viewMode, LibraryViewMode.list);
    });

    testWidgets('Clear all resets filters, sort, and view', (tester) async {
      libraryProvider.setStatusFilters({LibraryReadingStatus.inProgress});
      libraryProvider.setSortOption(LibrarySortOption.titleAZ);
      libraryProvider.setViewMode(LibraryViewMode.list);

      await pumpChips(tester);
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(libraryProvider.filters.isEmpty, isTrue);
      expect(libraryProvider.sortOption, LibrarySortOption.dateAddedNewest);
      expect(libraryProvider.viewMode, LibraryViewMode.smallGrid);
    });
  });
}
