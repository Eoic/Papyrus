import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/providers/social_provider.dart';

void main() {
  group('SocialProvider', () {
    late SocialProvider provider;

    setUp(() {
      provider = SocialProvider();
    });

    group('initial state', () {
      test('should have null profiles', () {
        expect(provider.currentProfile, isNull);
        expect(provider.viewedProfile, isNull);
        expect(provider.isProfileLoading, false);
      });

      test('should have empty follow lists', () {
        expect(provider.followers, isEmpty);
        expect(provider.following, isEmpty);
        expect(provider.friends, isEmpty);
        expect(provider.isFollowListLoading, false);
      });

      test('should have empty user search', () {
        expect(provider.userSearchResults, isEmpty);
        expect(provider.isUserSearching, false);
      });
    });

    group('profile loading', () {
      test('should set loading state during loadOwnProfile', () async {
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isProfileLoading);
        });

        await provider.loadOwnProfile();

        expect(loadingStates, [true, false]);
      });

      test(
        'should clear viewed profile and set loading during loadUserProfile',
        () async {
          var loadingStates = <bool>[];
          provider.addListener(() {
            loadingStates.add(provider.isProfileLoading);
          });

          await provider.loadUserProfile('user-123');

          expect(provider.viewedProfile, isNull);
          expect(loadingStates, [true, false]);
        },
      );
    });

    group('follow / unfollow', () {
      test('should not crash when following with no viewed profile', () async {
        await provider.followUser('user-123');
        // No assertion error = pass
      });

      test(
        'should not crash when unfollowing with no viewed profile',
        () async {
          await provider.unfollowUser('user-123');
          // No assertion error = pass
        },
      );
    });

    group('block / unblock', () {
      test('should notify listeners on blockUser', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.blockUser('user-456');
        expect(notified, true);
      });

      test('should notify listeners on unblockUser', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.unblockUser('user-456');
        expect(notified, true);
      });
    });

    group('follow lists', () {
      test('should set loading state during loadFollowers', () async {
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isFollowListLoading);
        });

        await provider.loadFollowers();

        expect(loadingStates, [true, false]);
        expect(provider.followers, isEmpty);
      });

      test('should set loading state during loadFollowing', () async {
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isFollowListLoading);
        });

        await provider.loadFollowing();

        expect(loadingStates, [true, false]);
        expect(provider.following, isEmpty);
      });

      test('should set loading state during loadFriends', () async {
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isFollowListLoading);
        });

        await provider.loadFriends();

        expect(loadingStates, [true, false]);
        expect(provider.friends, isEmpty);
      });
    });

    group('user search', () {
      test('should clear results for empty query', () async {
        await provider.searchUsers('');
        expect(provider.userSearchResults, isEmpty);
        expect(provider.isUserSearching, false);
      });

      test('should set searching state for non-empty query', () async {
        var searchingStates = <bool>[];
        provider.addListener(() {
          searchingStates.add(provider.isUserSearching);
        });

        await provider.searchUsers('alice');

        expect(searchingStates, [true, false]);
      });
    });
  });
}
