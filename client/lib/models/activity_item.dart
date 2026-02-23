/// User summary within an activity feed item.
class ActivityUser {
  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;

  const ActivityUser({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
  });

  factory ActivityUser.fromJson(Map<String, dynamic> json) => ActivityUser(
    userId: json['user_id'] as String,
    displayName: json['display_name'] as String,
    username: json['username'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}

/// Book summary within an activity feed item.
class ActivityBook {
  final String catalogBookId;
  final String title;
  final String author;
  final String? coverImageUrl;

  const ActivityBook({
    required this.catalogBookId,
    required this.title,
    required this.author,
    this.coverImageUrl,
  });

  factory ActivityBook.fromJson(Map<String, dynamic> json) => ActivityBook(
    catalogBookId: json['catalog_book_id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    coverImageUrl: json['cover_url'] as String?,
  );
}

/// Single activity feed item.
class ActivityItem {
  final String activityId;
  final ActivityUser user;
  final String activityType;
  final String description;
  final ActivityBook? book;
  final DateTime createdAt;

  const ActivityItem({
    required this.activityId,
    required this.user,
    required this.activityType,
    required this.description,
    this.book,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    activityId: json['activity_id'] as String,
    user: ActivityUser.fromJson(json['user'] as Map<String, dynamic>),
    activityType: json['activity_type'] as String,
    description: json['description'] as String,
    book: json['book'] != null
        ? ActivityBook.fromJson(json['book'] as Map<String, dynamic>)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
