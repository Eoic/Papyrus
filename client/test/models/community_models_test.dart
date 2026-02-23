import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/activity_item.dart';
import 'package:papyrus/models/catalog_book.dart';
import 'package:papyrus/models/community_review.dart';
import 'package:papyrus/models/community_user.dart';

void main() {
  group('CommunityUser', () {
    test('creates from JSON', () {
      final json = {
        'user_id': '123',
        'display_name': 'Test User',
        'username': 'testuser',
        'follower_count': 5,
        'following_count': 3,
        'book_count': 10,
      };
      final user = CommunityUser.fromJson(json);
      expect(user.userId, '123');
      expect(user.displayName, 'Test User');
      expect(user.username, 'testuser');
      expect(user.followerCount, 5);
    });

    test('converts to JSON', () {
      const user = CommunityUser(
        userId: '123',
        displayName: 'Test',
        followerCount: 0,
        followingCount: 0,
        bookCount: 0,
      );
      final json = user.toJson();
      expect(json['user_id'], '123');
      expect(json['display_name'], 'Test');
    });

    test('copyWith creates modified copy', () {
      const user = CommunityUser(
        userId: '123',
        displayName: 'Test',
        isFollowing: false,
        followerCount: 5,
        followingCount: 0,
        bookCount: 0,
      );
      final updated = user.copyWith(isFollowing: true, followerCount: 6);
      expect(updated.isFollowing, true);
      expect(updated.followerCount, 6);
      expect(updated.displayName, 'Test');
    });
  });

  group('CatalogBook', () {
    test('creates from JSON', () {
      final json = {
        'catalog_book_id': '456',
        'title': 'Dune',
        'author': 'Frank Herbert',
        'average_rating': 8.5,
        'rating_count': 100,
        'review_count': 25,
      };
      final book = CatalogBook.fromJson(json);
      expect(book.catalogBookId, '456');
      expect(book.title, 'Dune');
      expect(book.averageRating, 8.5);
    });
  });

  group('CommunityReview', () {
    test('creates from JSON', () {
      final json = {
        'review_id': '789',
        'user_id': '123',
        'catalog_book_id': '456',
        'body': 'Great book!',
        'contains_spoilers': false,
        'like_count': 3,
        'helpful_count': 1,
      };
      final review = CommunityReview.fromJson(json);
      expect(review.reviewId, '789');
      expect(review.body, 'Great book!');
      expect(review.containsSpoilers, false);
    });
  });

  group('ActivityItem', () {
    test('creates from JSON', () {
      final json = {
        'activity_id': 'act1',
        'user': {'user_id': '123', 'display_name': 'User'},
        'activity_type': 'rated_book',
        'description': 'User rated Dune',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final item = ActivityItem.fromJson(json);
      expect(item.activityId, 'act1');
      expect(item.activityType, 'rated_book');
      expect(item.user.displayName, 'User');
    });
  });
}
