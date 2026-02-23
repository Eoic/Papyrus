import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/catalog_book.dart';
import 'package:papyrus/providers/community_provider.dart';

void main() {
  group('CommunityProvider', () {
    late CommunityProvider provider;

    setUp(() {
      provider = CommunityProvider();
    });

    group('initial state', () {
      test('should have empty feed', () {
        expect(provider.feedItems, isEmpty);
        expect(provider.isFeedLoading, false);
        expect(provider.feedError, isNull);
        expect(provider.hasFeedItems, false);
      });

      test('should have empty search', () {
        expect(provider.searchResults, isEmpty);
        expect(provider.searchQuery, '');
        expect(provider.isSearching, false);
        expect(provider.hasSearchResults, false);
      });

      test('should have no selected book', () {
        expect(provider.selectedBook, isNull);
        expect(provider.bookReviews, isEmpty);
        expect(provider.userRating, isNull);
      });

      test('should have feed tab index 0', () {
        expect(provider.feedTabIndex, 0);
      });
    });

    group('feed tab', () {
      test('should update feed tab index', () {
        provider.setFeedTabIndex(1);
        expect(provider.feedTabIndex, 1);
      });

      test('should notify listeners on tab change', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setFeedTabIndex(2);
        expect(notified, true);
      });
    });

    group('feed loading', () {
      test('should set loading state during loadFeed', () async {
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isFeedLoading);
        });

        await provider.loadFeed();

        expect(loadingStates, [true, false]);
        expect(provider.feedError, isNull);
      });

      test('should set loading state during loadGlobalFeed', () async {
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isFeedLoading);
        });

        await provider.loadGlobalFeed();

        expect(loadingStates, [true, false]);
        expect(provider.feedError, isNull);
      });
    });

    group('search', () {
      test('should clear results for empty query', () async {
        await provider.searchBooks('');
        expect(provider.searchQuery, '');
        expect(provider.searchResults, isEmpty);
        expect(provider.isSearching, false);
      });

      test('should set searching state for non-empty query', () async {
        var searchingStates = <bool>[];
        provider.addListener(() {
          searchingStates.add(provider.isSearching);
        });

        await provider.searchBooks('flutter');

        expect(provider.searchQuery, 'flutter');
        expect(searchingStates, [true, false]);
      });

      test('should clear search state', () {
        provider.clearSearch();
        expect(provider.searchQuery, '');
        expect(provider.searchResults, isEmpty);
        expect(provider.isSearching, false);
      });

      test('should notify listeners on clearSearch', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearSearch();
        expect(notified, true);
      });
    });

    group('book details', () {
      test('should set selected book and clear reviews', () {
        const book = CatalogBook(
          catalogBookId: '123',
          title: 'Test Book',
          author: 'Test Author',
        );
        provider.selectBook(book);

        expect(provider.selectedBook, book);
        expect(provider.bookReviews, isEmpty);
        expect(provider.userRating, isNull);
      });

      test('should notify listeners on selectBook', () {
        var notified = false;
        provider.addListener(() => notified = true);

        const book = CatalogBook(
          catalogBookId: '456',
          title: 'Another Book',
          author: 'Another Author',
        );
        provider.selectBook(book);
        expect(notified, true);
      });
    });

    group('ratings', () {
      test('should update user rating', () async {
        await provider.rateBook('book-1', 8);
        expect(provider.userRating, 8);
      });

      test('should notify listeners on rateBook', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.rateBook('book-1', 5);
        expect(notified, true);
      });
    });

    group('reviews', () {
      test('should notify listeners on submitReview', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.submitReview(
          catalogBookId: 'book-1',
          body: 'Great book!',
        );
        expect(notified, true);
      });
    });
  });
}
