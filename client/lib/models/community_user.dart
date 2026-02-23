/// Community user profile model.
class CommunityUser {
  final String userId;
  final String? username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String profileVisibility;
  final int followerCount;
  final int followingCount;
  final int bookCount;
  final int reviewCount;
  final bool isFollowing;
  final bool isFriend;
  final bool isBlocked;

  const CommunityUser({
    required this.userId,
    this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.profileVisibility = 'public',
    required this.followerCount,
    required this.followingCount,
    required this.bookCount,
    this.reviewCount = 0,
    this.isFollowing = false,
    this.isFriend = false,
    this.isBlocked = false,
  });

  CommunityUser copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? profileVisibility,
    int? followerCount,
    int? followingCount,
    int? bookCount,
    int? reviewCount,
    bool? isFollowing,
    bool? isFriend,
    bool? isBlocked,
  }) => CommunityUser(
    userId: userId ?? this.userId,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    profileVisibility: profileVisibility ?? this.profileVisibility,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount ?? this.followingCount,
    bookCount: bookCount ?? this.bookCount,
    reviewCount: reviewCount ?? this.reviewCount,
    isFollowing: isFollowing ?? this.isFollowing,
    isFriend: isFriend ?? this.isFriend,
    isBlocked: isBlocked ?? this.isBlocked,
  );

  factory CommunityUser.fromJson(Map<String, dynamic> json) => CommunityUser(
    userId: json['user_id'] as String,
    username: json['username'] as String?,
    displayName: json['display_name'] as String,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    profileVisibility: json['profile_visibility'] as String? ?? 'public',
    followerCount: json['follower_count'] as int? ?? 0,
    followingCount: json['following_count'] as int? ?? 0,
    bookCount: json['book_count'] as int? ?? 0,
    reviewCount: json['review_count'] as int? ?? 0,
    isFollowing: json['is_following'] as bool? ?? false,
    isFriend: json['is_friend'] as bool? ?? false,
    isBlocked: json['is_blocked'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'profile_visibility': profileVisibility,
    'follower_count': followerCount,
    'following_count': followingCount,
    'book_count': bookCount,
    'review_count': reviewCount,
    'is_following': isFollowing,
    'is_friend': isFriend,
    'is_blocked': isBlocked,
  };
}
