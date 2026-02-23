import 'package:flutter/foundation.dart';
import 'package:papyrus/models/activity_item.dart';
import 'package:papyrus/models/catalog_book.dart';
import 'package:papyrus/models/community_review.dart';

/// Provider for community features (feed, catalog, reviews).
/// Manages UI state for the community tab. Online-only.
class CommunityProvider extends ChangeNotifier {
  // Feed state
  List<ActivityItem> _feedItems = [];
  bool _isFeedLoading = false;
  String? _feedError;

  // Search state
  List<CatalogBook> _searchResults = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Selected book detail
  CatalogBook? _selectedBook;
  List<CommunityReview> _bookReviews = [];
  int? _userRating;

  // Feed tab index
  int _feedTabIndex = 0;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<ActivityItem> get feedItems => _feedItems;
  bool get isFeedLoading => _isFeedLoading;
  String? get feedError => _feedError;
  bool get hasFeedItems => _feedItems.isNotEmpty;

  List<CatalogBook> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  bool get hasSearchResults => _searchResults.isNotEmpty;

  CatalogBook? get selectedBook => _selectedBook;
  List<CommunityReview> get bookReviews => _bookReviews;
  int? get userRating => _userRating;

  int get feedTabIndex => _feedTabIndex;

  // ============================================================================
  // FEED
  // ============================================================================

  /// Set the active feed tab index.
  void setFeedTabIndex(int index) {
    _feedTabIndex = index;
    notifyListeners();
  }

  /// Load the following feed (people the user follows).
  Future<void> loadFeed() async {
    _isFeedLoading = true;
    _feedError = null;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/feed') and parse response
    _feedItems = [];
    _isFeedLoading = false;
    notifyListeners();
  }

  /// Load the global/discover feed.
  Future<void> loadGlobalFeed() async {
    _isFeedLoading = true;
    _feedError = null;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/feed/global') and parse response
    _feedItems = [];
    _isFeedLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // SEARCH
  // ============================================================================

  /// Search the community book catalog by query.
  Future<void> searchBooks(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/catalog/search', queryParams: {'q': query})
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Clear the search query and results.
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  // ============================================================================
  // BOOK DETAILS
  // ============================================================================

  /// Select a book to view its details.
  void selectBook(CatalogBook book) {
    _selectedBook = book;
    _bookReviews = [];
    _userRating = null;
    notifyListeners();
  }

  /// Load reviews for a catalog book.
  Future<void> loadBookReviews(String catalogBookId) async {
    // TODO: Call ApiClient.get('/v1/catalog/books/$catalogBookId/reviews')
    _bookReviews = [];
    notifyListeners();
  }

  // ============================================================================
  // RATINGS
  // ============================================================================

  /// Rate a catalog book with a score.
  Future<void> rateBook(String catalogBookId, int score) async {
    _userRating = score;
    notifyListeners();
    // TODO: Call ApiClient.post('/v1/ratings', body: {...})
  }

  // ============================================================================
  // REVIEWS
  // ============================================================================

  /// Submit a review for a catalog book.
  Future<void> submitReview({
    required String catalogBookId,
    required String body,
    String? title,
    bool containsSpoilers = false,
  }) async {
    // TODO: Call ApiClient.post('/v1/reviews', body: {...})
    notifyListeners();
  }
}
