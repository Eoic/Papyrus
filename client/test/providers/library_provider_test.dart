import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/providers/library_provider.dart';

void main() {
  group('LibraryProvider', () {
    late LibraryProvider provider;

    setUp(() {
      provider = LibraryProvider();
    });

    group('initial state', () {
      test('should have grid view mode by default', () {
        expect(provider.viewMode, LibraryViewMode.grid);
        expect(provider.isGridView, true);
        expect(provider.isListView, false);
      });

      test('should have "all" filter active by default', () {
        expect(provider.activeFilters, {LibraryFilterType.all});
        expect(provider.isFilterActive(LibraryFilterType.all), true);
      });

      test('should have empty search query by default', () {
        expect(provider.searchQuery, '');
        expect(provider.hasActiveAdvancedFilters, false);
      });

      test('should have no shelf or topic selected by default', () {
        expect(provider.selectedShelf, null);
        expect(provider.selectedTopic, null);
      });
    });

    group('view mode', () {
      test('should toggle between grid and list view', () {
        expect(provider.isGridView, true);

        provider.toggleViewMode();
        expect(provider.isListView, true);
        expect(provider.isGridView, false);

        provider.toggleViewMode();
        expect(provider.isGridView, true);
        expect(provider.isListView, false);
      });

      test('should set view mode directly', () {
        provider.setViewMode(LibraryViewMode.list);
        expect(provider.viewMode, LibraryViewMode.list);

        provider.setViewMode(LibraryViewMode.grid);
        expect(provider.viewMode, LibraryViewMode.grid);
      });
    });

    group('quick filters', () {
      test('should add filter and remove "all"', () {
        provider.addFilter(LibraryFilterType.reading);

        expect(provider.isFilterActive(LibraryFilterType.reading), true);
        expect(provider.isFilterActive(LibraryFilterType.all), false);
      });

      test('should allow multiple filters', () {
        provider.addFilter(LibraryFilterType.reading);
        provider.addFilter(LibraryFilterType.favorites);

        expect(provider.isFilterActive(LibraryFilterType.reading), true);
        expect(provider.isFilterActive(LibraryFilterType.favorites), true);
        expect(provider.activeFilters.length, 2);
      });

      test('should remove filter and default to "all" when empty', () {
        provider.addFilter(LibraryFilterType.reading);
        provider.removeFilter(LibraryFilterType.reading);

        expect(provider.isFilterActive(LibraryFilterType.reading), false);
        expect(provider.isFilterActive(LibraryFilterType.all), true);
      });

      test('should toggle filter on and off', () {
        expect(provider.isFilterActive(LibraryFilterType.reading), false);

        provider.toggleFilter(LibraryFilterType.reading);
        expect(provider.isFilterActive(LibraryFilterType.reading), true);

        provider.toggleFilter(LibraryFilterType.reading);
        expect(provider.isFilterActive(LibraryFilterType.reading), false);
      });

      test('should not duplicate filters when added multiple times', () {
        provider.addFilter(LibraryFilterType.reading);
        provider.addFilter(LibraryFilterType.reading);
        provider.addFilter(LibraryFilterType.reading);

        // Set uses unique values
        expect(
          provider.activeFilters.where((f) => f == LibraryFilterType.reading).length,
          1,
        );
      });
    });

    group('search query', () {
      test('should set search query', () {
        provider.setSearchQuery('test query');
        expect(provider.searchQuery, 'test query');
      });

      test('should clear search query', () {
        provider.setSearchQuery('test query');
        provider.clearSearch();
        expect(provider.searchQuery, '');
      });

      test('should detect advanced filters in query', () {
        provider.setSearchQuery('simple search');
        expect(provider.hasActiveAdvancedFilters, false);

        provider.setSearchQuery('author:tolkien');
        expect(provider.hasActiveAdvancedFilters, true);
      });
    });

    group('shelf and topic selection', () {
      test('should select shelf and set shelves filter', () {
        provider.selectShelf('Fiction');

        expect(provider.selectedShelf, 'Fiction');
        expect(provider.isFilterActive(LibraryFilterType.shelves), true);
      });

      test('should clear shelf when set to null', () {
        provider.selectShelf('Fiction');
        provider.selectShelf(null);

        expect(provider.selectedShelf, null);
      });

      test('should select topic and set topics filter', () {
        provider.selectTopic('Science');

        expect(provider.selectedTopic, 'Science');
        expect(provider.isFilterActive(LibraryFilterType.topics), true);
      });

      test('should clear topic when set to null', () {
        provider.selectTopic('Science');
        provider.selectTopic(null);

        expect(provider.selectedTopic, null);
      });
    });

    group('reset filters', () {
      test('should reset all filters to default state', () {
        // Set up various filters
        provider.addFilter(LibraryFilterType.reading);
        provider.addFilter(LibraryFilterType.favorites);
        provider.setSearchQuery('author:tolkien');
        provider.selectShelf('Fiction');
        provider.selectTopic('Science');

        // Reset
        provider.resetFilters();

        // Verify all reset
        expect(provider.activeFilters, {LibraryFilterType.all});
        expect(provider.searchQuery, '');
        expect(provider.selectedShelf, null);
        expect(provider.selectedTopic, null);
      });
    });

    group('notifyListeners', () {
      test('should notify on view mode change', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.toggleViewMode();
        expect(notified, true);
      });

      test('should notify on filter change', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.addFilter(LibraryFilterType.reading);
        provider.removeFilter(LibraryFilterType.reading);
        provider.toggleFilter(LibraryFilterType.favorites);

        expect(notifyCount, 3);
      });

      test('should not notify when setting same search query', () {
        provider.setSearchQuery('test');

        var notified = false;
        provider.addListener(() => notified = true);

        provider.setSearchQuery('test'); // Same value
        expect(notified, false);
      });
    });
  });
}
