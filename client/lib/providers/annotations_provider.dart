import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';

/// Sort options for annotations.
enum AnnotationSortOption { dateNewest, dateOldest, bookTitle, position }

/// Provider for annotations page state management.
/// Uses DataStore as the single source of truth.
class AnnotationsProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Sorting
  AnnotationSortOption _sortOption = AnnotationSortOption.dateNewest;

  // Filtering
  Set<HighlightColor> _selectedColors = {};
  String _searchQuery = '';

  /// Attach to a DataStore instance.
  void attach(DataStore dataStore) {
    if (_dataStore != dataStore) {
      _dataStore?.removeListener(_onDataStoreChanged);
      _dataStore = dataStore;
      _dataStore!.addListener(_onDataStoreChanged);
      notifyListeners();
    }
  }

  void _onDataStoreChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dataStore?.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  AnnotationSortOption get sortOption => _sortOption;
  Set<HighlightColor> get activeColors => _selectedColors;
  String get searchQuery => _searchQuery;

  /// Whether there are any annotations at all (unfiltered).
  bool get hasAnnotations =>
      _dataStore != null && _dataStore!.annotations.isNotEmpty;

  /// Whether current filters yield results.
  bool get hasResults => annotations.isNotEmpty;

  /// Whether any filter or search is active.
  bool get isFiltered => _selectedColors.isNotEmpty || _searchQuery.isNotEmpty;

  /// Total count of filtered annotations.
  int get totalCount => annotations.length;

  /// All annotations, filtered and sorted.
  List<Annotation> get annotations {
    if (_dataStore == null) return [];
    var list = List<Annotation>.from(_dataStore!.annotations);
    list = _applyFilters(list);
    _applySorting(list);
    return list;
  }

  /// Annotations grouped by book, preserving sort order.
  Map<String, List<Annotation>> get annotationsByBook {
    final filtered = annotations;
    final map = <String, List<Annotation>>{};
    for (final annotation in filtered) {
      map.putIfAbsent(annotation.bookId, () => []).add(annotation);
    }
    return map;
  }

  /// Resolve book title from DataStore.
  String getBookTitle(String bookId) {
    return _dataStore?.getBook(bookId)?.title ?? 'Unknown book';
  }

  /// Resolve book cover URL from DataStore.
  String? getBookCoverUrl(String bookId) {
    return _dataStore?.getBook(bookId)?.coverUrl;
  }

  // ============================================================================
  // SORTING & FILTERING
  // ============================================================================

  void setSortOption(AnnotationSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleColorFilter(HighlightColor color) {
    _selectedColors = Set.from(_selectedColors);
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    } else {
      _selectedColors.add(color);
    }
    notifyListeners();
  }

  void clearColorFilters() {
    _selectedColors = {};
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedColors = {};
    _searchQuery = '';
    notifyListeners();
  }

  // ============================================================================
  // CRUD (delegated to DataStore)
  // ============================================================================

  void updateAnnotationNote(String annotationId, String? note) {
    final annotation = _dataStore?.getAnnotation(annotationId);
    if (annotation == null || _dataStore == null) return;
    _dataStore!.updateAnnotation(annotation.copyWith(note: note));
  }

  void deleteAnnotation(String annotationId) {
    _dataStore?.deleteAnnotation(annotationId);
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  List<Annotation> _applyFilters(List<Annotation> all) {
    var result = all;

    if (_selectedColors.isNotEmpty) {
      result = result.where((a) => _selectedColors.contains(a.color)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((a) {
        final bookTitle = getBookTitle(a.bookId).toLowerCase();
        final highlightText = a.highlightText.toLowerCase();
        final note = a.note?.toLowerCase() ?? '';
        final location = a.location.displayLocation.toLowerCase();
        return bookTitle.contains(query) ||
            highlightText.contains(query) ||
            note.contains(query) ||
            location.contains(query);
      }).toList();
    }

    return result;
  }

  void _applySorting(List<Annotation> list) {
    list.sort((a, b) {
      switch (_sortOption) {
        case AnnotationSortOption.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case AnnotationSortOption.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case AnnotationSortOption.bookTitle:
          return getBookTitle(
            a.bookId,
          ).toLowerCase().compareTo(getBookTitle(b.bookId).toLowerCase());
        case AnnotationSortOption.position:
          return a.location.pageNumber.compareTo(b.location.pageNumber);
      }
    });
  }
}
