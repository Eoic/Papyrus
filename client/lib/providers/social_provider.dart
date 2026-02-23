import 'package:flutter/foundation.dart';
import 'package:papyrus/models/community_user.dart';

/// Provider for social features (follow, block, user profiles).
/// Online-only — no offline caching.
class SocialProvider extends ChangeNotifier {
  // Profile state
  CommunityUser? _currentProfile;
  CommunityUser? _viewedProfile;
  bool _isProfileLoading = false;

  // Follow lists
  List<CommunityUser> _followers = [];
  List<CommunityUser> _following = [];
  List<CommunityUser> _friends = [];
  bool _isFollowListLoading = false;

  // Discover (user search)
  List<CommunityUser> _userSearchResults = [];
  bool _isUserSearching = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  CommunityUser? get currentProfile => _currentProfile;
  CommunityUser? get viewedProfile => _viewedProfile;
  bool get isProfileLoading => _isProfileLoading;

  List<CommunityUser> get followers => _followers;
  List<CommunityUser> get following => _following;
  List<CommunityUser> get friends => _friends;
  bool get isFollowListLoading => _isFollowListLoading;

  List<CommunityUser> get userSearchResults => _userSearchResults;
  bool get isUserSearching => _isUserSearching;

  // ============================================================================
  // PROFILE
  // ============================================================================

  /// Load the current user's community profile.
  Future<void> loadOwnProfile() async {
    _isProfileLoading = true;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/profiles/me')
    _isProfileLoading = false;
    notifyListeners();
  }

  /// Load another user's community profile.
  Future<void> loadUserProfile(String userId) async {
    _isProfileLoading = true;
    _viewedProfile = null;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/profiles/$userId')
    _isProfileLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // FOLLOW / UNFOLLOW
  // ============================================================================

  /// Follow a user. Optimistically updates the viewed profile if it matches.
  Future<void> followUser(String targetUserId) async {
    // TODO: Call ApiClient.post('/v1/social/follow/$targetUserId')
    // Optimistically update viewedProfile if it matches
    if (_viewedProfile != null && _viewedProfile!.userId == targetUserId) {
      _viewedProfile = _viewedProfile!.copyWith(
        isFollowing: true,
        followerCount: _viewedProfile!.followerCount + 1,
      );
      notifyListeners();
    }
  }

  /// Unfollow a user. Optimistically updates the viewed profile if it matches.
  Future<void> unfollowUser(String targetUserId) async {
    // TODO: Call ApiClient.delete('/v1/social/follow/$targetUserId')
    if (_viewedProfile != null && _viewedProfile!.userId == targetUserId) {
      _viewedProfile = _viewedProfile!.copyWith(
        isFollowing: false,
        followerCount: _viewedProfile!.followerCount - 1,
      );
      notifyListeners();
    }
  }

  // ============================================================================
  // BLOCK
  // ============================================================================

  /// Block a user.
  Future<void> blockUser(String targetUserId) async {
    // TODO: Call ApiClient.post('/v1/social/block/$targetUserId')
    notifyListeners();
  }

  /// Unblock a user.
  Future<void> unblockUser(String targetUserId) async {
    // TODO: Call ApiClient.delete('/v1/social/block/$targetUserId')
    notifyListeners();
  }

  // ============================================================================
  // FOLLOW LISTS
  // ============================================================================

  /// Load the current user's followers.
  Future<void> loadFollowers() async {
    _isFollowListLoading = true;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/social/followers')
    _followers = [];
    _isFollowListLoading = false;
    notifyListeners();
  }

  /// Load the users the current user is following.
  Future<void> loadFollowing() async {
    _isFollowListLoading = true;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/social/following')
    _following = [];
    _isFollowListLoading = false;
    notifyListeners();
  }

  /// Load the current user's mutual-follow friends.
  Future<void> loadFriends() async {
    _isFollowListLoading = true;
    notifyListeners();

    // TODO: Call ApiClient.get('/v1/social/friends')
    _friends = [];
    _isFollowListLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // USER SEARCH
  // ============================================================================

  /// Search for users by query string.
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _userSearchResults = [];
      _isUserSearching = false;
      notifyListeners();
      return;
    }

    _isUserSearching = true;
    notifyListeners();

    // TODO: Call search endpoint
    _userSearchResults = [];
    _isUserSearching = false;
    notifyListeners();
  }
}
