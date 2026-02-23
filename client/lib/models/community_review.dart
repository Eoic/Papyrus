/// Community book review model.
class CommunityReview {
  final String reviewId;
  final String userId;
  final String catalogBookId;
  final String? authorDisplayName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? title;
  final String body;
  final bool containsSpoilers;
  final String visibility;
  final int likeCount;
  final int helpfulCount;
  final DateTime? createdAt;

  const CommunityReview({
    required this.reviewId,
    required this.userId,
    required this.catalogBookId,
    this.authorDisplayName,
    this.authorUsername,
    this.authorAvatarUrl,
    this.title,
    required this.body,
    this.containsSpoilers = false,
    this.visibility = 'public',
    this.likeCount = 0,
    this.helpfulCount = 0,
    this.createdAt,
  });

  factory CommunityReview.fromJson(Map<String, dynamic> json) =>
      CommunityReview(
        reviewId: json['review_id'] as String,
        userId: json['user_id'] as String,
        catalogBookId: json['catalog_book_id'] as String,
        authorDisplayName: json['author_display_name'] as String?,
        authorUsername: json['author_username'] as String?,
        authorAvatarUrl: json['author_avatar_url'] as String?,
        title: json['title'] as String?,
        body: json['body'] as String,
        containsSpoilers: json['contains_spoilers'] as bool? ?? false,
        visibility: json['visibility'] as String? ?? 'public',
        likeCount: json['like_count'] as int? ?? 0,
        helpfulCount: json['helpful_count'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'review_id': reviewId,
    'user_id': userId,
    'catalog_book_id': catalogBookId,
    'title': title,
    'body': body,
    'contains_spoilers': containsSpoilers,
    'visibility': visibility,
  };
}
