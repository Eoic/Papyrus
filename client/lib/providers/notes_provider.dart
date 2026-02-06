import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/note.dart';

/// Sort options for notes.
enum NoteSortOption { dateNewest, dateOldest, bookTitle, pinnedFirst }

/// Provider for notes page state management.
/// Uses DataStore as the single source of truth.
class NotesProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Sorting
  NoteSortOption _sortOption = NoteSortOption.dateNewest;

  // Filtering
  Set<String> _selectedTags = {};
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

  NoteSortOption get sortOption => _sortOption;
  Set<String> get activeTags => _selectedTags;
  String get searchQuery => _searchQuery;

  /// Whether there are any notes at all (unfiltered).
  bool get hasNotes => _dataStore != null && _dataStore!.notes.isNotEmpty;

  /// Whether current filters yield results.
  bool get hasResults => notes.isNotEmpty;

  /// Whether any filter or search is active.
  bool get isFiltered => _selectedTags.isNotEmpty || _searchQuery.isNotEmpty;

  /// Total count of filtered notes.
  int get totalCount => notes.length;

  /// All unique tags across all notes (for filter chip generation).
  Set<String> get allTags {
    if (_dataStore == null) return {};
    final tags = <String>{};
    for (final note in _dataStore!.notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  /// All notes, filtered and sorted.
  List<Note> get notes {
    if (_dataStore == null) return [];
    var list = List<Note>.from(_dataStore!.notes);
    list = _applyFilters(list);
    _applySorting(list);
    return list;
  }

  /// Notes grouped by book, preserving sort order.
  Map<String, List<Note>> get notesByBook {
    final filtered = notes;
    final map = <String, List<Note>>{};
    for (final note in filtered) {
      map.putIfAbsent(note.bookId, () => []).add(note);
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

  void setSortOption(NoteSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleTagFilter(String tag) {
    _selectedTags = Set.from(_selectedTags);
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void clearTagFilters() {
    _selectedTags = {};
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
    _selectedTags = {};
    _searchQuery = '';
    notifyListeners();
  }

  // ============================================================================
  // CRUD (delegated to DataStore)
  // ============================================================================

  void updateNote(Note note) {
    _dataStore?.updateNote(note);
  }

  void deleteNote(String noteId) {
    _dataStore?.deleteNote(noteId);
  }

  void togglePin(String noteId) {
    final note = _dataStore?.getNote(noteId);
    if (note == null || _dataStore == null) return;
    _dataStore!.updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  List<Note> _applyFilters(List<Note> all) {
    var result = all;

    if (_selectedTags.isNotEmpty) {
      result = result
          .where((n) => n.tags.any((t) => _selectedTags.contains(t)))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((n) {
        final bookTitle = getBookTitle(n.bookId).toLowerCase();
        final title = n.title.toLowerCase();
        final content = n.content.toLowerCase();
        final tags = n.tags.join(' ').toLowerCase();
        return bookTitle.contains(query) ||
            title.contains(query) ||
            content.contains(query) ||
            tags.contains(query);
      }).toList();
    }

    return result;
  }

  void _applySorting(List<Note> list) {
    list.sort((a, b) {
      switch (_sortOption) {
        case NoteSortOption.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case NoteSortOption.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case NoteSortOption.bookTitle:
          return getBookTitle(
            a.bookId,
          ).toLowerCase().compareTo(getBookTitle(b.bookId).toLowerCase());
        case NoteSortOption.pinnedFirst:
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);
      }
    });
  }
}
