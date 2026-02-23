/// Community book catalog model.
class CatalogBook {
  final String catalogBookId;
  final String? openLibraryId;
  final String? isbn;
  final String title;
  final String author;
  final List<String>? authors;
  final String? coverImageUrl;
  final String? description;
  final int? pageCount;
  final double? averageRating;
  final int ratingCount;
  final int reviewCount;

  const CatalogBook({
    required this.catalogBookId,
    this.openLibraryId,
    this.isbn,
    required this.title,
    required this.author,
    this.authors,
    this.coverImageUrl,
    this.description,
    this.pageCount,
    this.averageRating,
    this.ratingCount = 0,
    this.reviewCount = 0,
  });

  factory CatalogBook.fromJson(Map<String, dynamic> json) {
    final authors = json['authors'] as List?;
    final authorStr = authors != null && authors.isNotEmpty
        ? authors.first as String
        : json['author'] as String? ?? 'Unknown';

    return CatalogBook(
      catalogBookId: json['catalog_book_id'] as String,
      openLibraryId: json['open_library_id'] as String?,
      isbn: json['isbn'] as String?,
      title: json['title'] as String,
      author: authorStr,
      authors: authors?.cast<String>(),
      coverImageUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      pageCount: json['page_count'] as int?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'catalog_book_id': catalogBookId,
    'open_library_id': openLibraryId,
    'isbn': isbn,
    'title': title,
    'authors': authors ?? [author],
    'cover_url': coverImageUrl,
    'description': description,
    'page_count': pageCount,
    'average_rating': averageRating,
    'rating_count': ratingCount,
    'review_count': reviewCount,
  };
}
