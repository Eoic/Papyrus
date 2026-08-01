import 'package:papyrus/providers/enums/library_reading_status.dart';

/// Format of the book file.
enum BookFormat { epub, pdf, mobi, azw3, txt, cbr, cbz }

/// Extension to get display labels for book format.
extension BookFormatExtension on BookFormat {
  String get label {
    switch (this) {
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.mobi:
        return 'MOBI';
      case BookFormat.azw3:
        return 'AZW3';
      case BookFormat.txt:
        return 'TXT';
      case BookFormat.cbr:
        return 'CBR';
      case BookFormat.cbz:
        return 'CBZ';
    }
  }
}

/// Book data model matching the database schema.
class Book {
  final String id;
  final String title;
  final String? subtitle;
  final String author;
  final List<String> coAuthors;
  final String? isbn;
  final String? isbn13;
  final DateTime? publicationDate;
  final String? publisher;
  final String? language;
  final int? pageCount;
  final String? description;
  final String? coverUrl;
  final String? fileMediaId;
  final String? coverMediaId;

  // Digital book fields
  final String? filePath;
  final BookFormat? fileFormat;
  final int? fileSize;
  final String? fileHash;

  // Physical book fields
  final bool isPhysical;
  final String? physicalLocation;
  final String? lentTo;
  final DateTime? lentAt;

  // Reading state
  final LibraryReadingStatus readingStatus;
  final int? currentPage;
  final double currentPosition; // 0.0 to 1.0
  final String? currentCfi; // EPUB CFI position

  // User metadata
  final bool isFavorite;
  final int? rating; // 1-5
  final Map<String, dynamic>? customMetadata;

  // Series
  final String? seriesId;
  final String? seriesName;
  final double? seriesNumber;

  // Timestamps
  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastReadAt;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    required this.author,
    this.coAuthors = const [],
    this.isbn,
    this.isbn13,
    this.publicationDate,
    this.publisher,
    this.language,
    this.pageCount,
    this.description,
    this.coverUrl,
    this.fileMediaId,
    this.coverMediaId,
    this.filePath,
    this.fileFormat,
    this.fileSize,
    this.fileHash,
    this.isPhysical = false,
    this.physicalLocation,
    this.lentTo,
    this.lentAt,
    this.readingStatus = LibraryReadingStatus.unread,
    this.currentPage,
    this.currentPosition = 0.0,
    this.currentCfi,
    this.isFavorite = false,
    this.rating,
    this.customMetadata,
    this.seriesId,
    this.seriesName,
    this.seriesNumber,
    required this.addedAt,
    this.startedAt,
    this.completedAt,
    this.lastReadAt,
  });

  // Backwards compatibility aliases
  double get progress => currentPosition;
  String? get coverURL => coverUrl;
  int? get totalPages => pageCount;

  // Shelves and topics are now managed via junction tables in DataStore.
  // These empty lists provide backwards compatibility for code that reads them.
  // To get actual shelves/topics for a book, use DataStore.getShelvesForBook(bookId)
  // and DataStore.getTagsForBook(bookId).
  List<String> get shelves => const [];
  List<String> get topics => const [];

  /// Progress as a percentage (0-100).
  int get progressPercent => (currentPosition * 100).round();

  /// Progress as a percentage string.
  String get progressLabel => '$progressPercent%';

  /// Whether the book has any progress.
  bool get hasProgress => currentPosition > 0;

  /// Get display string for format.
  String get formatLabel {
    if (isPhysical) return 'Physical';
    return fileFormat?.label ?? 'Unknown';
  }

  /// Get all authors as a single string.
  String get allAuthors {
    if (coAuthors.isEmpty) return author;
    return '$author, ${coAuthors.join(', ')}';
  }

  /// Create a copy with updated fields.
  ///
  /// Nullable fields use explicit `clear...` flags because an omitted nullable
  /// argument and an argument set to null are otherwise indistinguishable.
  Book copyWith({
    String? id,
    String? title,
    String? subtitle,
    bool clearSubtitle = false,
    String? author,
    List<String>? coAuthors,
    String? isbn,
    bool clearIsbn = false,
    String? isbn13,
    bool clearIsbn13 = false,
    DateTime? publicationDate,
    bool clearPublicationDate = false,
    String? publisher,
    bool clearPublisher = false,
    String? language,
    bool clearLanguage = false,
    int? pageCount,
    bool clearPageCount = false,
    String? description,
    bool clearDescription = false,
    String? coverUrl,
    bool clearCoverUrl = false,
    String? fileMediaId,
    String? coverMediaId,
    String? filePath,
    BookFormat? fileFormat,
    int? fileSize,
    String? fileHash,
    bool? isPhysical,
    String? physicalLocation,
    bool clearPhysicalLocation = false,
    String? lentTo,
    bool clearLentTo = false,
    DateTime? lentAt,
    bool clearLentAt = false,
    LibraryReadingStatus? readingStatus,
    int? currentPage,
    double? currentPosition,
    String? currentCfi,
    bool? isFavorite,
    int? rating,
    bool clearRating = false,
    Map<String, dynamic>? customMetadata,
    String? seriesId,
    String? seriesName,
    bool clearSeriesName = false,
    double? seriesNumber,
    bool clearSeriesNumber = false,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastReadAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      author: author ?? this.author,
      coAuthors: coAuthors ?? this.coAuthors,
      isbn: clearIsbn ? null : (isbn ?? this.isbn),
      isbn13: clearIsbn13 ? null : (isbn13 ?? this.isbn13),
      publicationDate: clearPublicationDate ? null : (publicationDate ?? this.publicationDate),
      publisher: clearPublisher ? null : (publisher ?? this.publisher),
      language: clearLanguage ? null : (language ?? this.language),
      pageCount: clearPageCount ? null : (pageCount ?? this.pageCount),
      description: clearDescription ? null : (description ?? this.description),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      fileMediaId: fileMediaId ?? this.fileMediaId,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      filePath: filePath ?? this.filePath,
      fileFormat: fileFormat ?? this.fileFormat,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      isPhysical: isPhysical ?? this.isPhysical,
      physicalLocation: clearPhysicalLocation ? null : (physicalLocation ?? this.physicalLocation),
      lentTo: clearLentTo ? null : (lentTo ?? this.lentTo),
      lentAt: clearLentAt ? null : (lentAt ?? this.lentAt),
      readingStatus: readingStatus ?? this.readingStatus,
      currentPage: currentPage ?? this.currentPage,
      currentPosition: currentPosition ?? this.currentPosition,
      currentCfi: currentCfi ?? this.currentCfi,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: clearRating ? null : (rating ?? this.rating),
      customMetadata: customMetadata ?? this.customMetadata,
      seriesId: seriesId ?? this.seriesId,
      seriesName: clearSeriesName ? null : (seriesName ?? this.seriesName),
      seriesNumber: clearSeriesNumber ? null : (seriesNumber ?? this.seriesNumber),
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'author': author,
      'co_authors': coAuthors,
      'isbn': isbn,
      'isbn13': isbn13,
      'publication_date': publicationDate?.toIso8601String(),
      'publisher': publisher,
      'language': language,
      'page_count': pageCount,
      'description': description,
      'cover_image_url': coverUrl,
      'file_media_id': fileMediaId,
      'cover_media_id': coverMediaId,
      'file_path': filePath,
      'file_format': fileFormat?.name,
      'file_size': fileSize,
      'file_hash': fileHash,
      'is_physical': isPhysical,
      'physical_location': physicalLocation,
      'lent_to': lentTo,
      'lent_at': lentAt?.toIso8601String(),
      'reading_status': readingStatus.name,
      'current_page': currentPage,
      'current_position': currentPosition,
      'current_cfi': currentCfi,
      'is_favorite': isFavorite,
      'rating': rating,
      'custom_metadata': customMetadata,
      'series_id': seriesId,
      'series_name': seriesName,
      'series_number': seriesNumber,
      'added_at': addedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      author: json['author'] as String,
      coAuthors: (json['co_authors'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isbn: json['isbn'] as String?,
      isbn13: json['isbn13'] as String?,
      publicationDate: json['publication_date'] != null ? DateTime.parse(json['publication_date'] as String) : null,
      publisher: json['publisher'] as String?,
      language: json['language'] as String?,
      pageCount: json['page_count'] as int?,
      description: json['description'] as String?,
      coverUrl: json['cover_image_url'] as String?,
      fileMediaId: json['file_media_id'] as String?,
      coverMediaId: json['cover_media_id'] as String?,
      filePath: json['file_path'] as String?,
      fileFormat: json['file_format'] != null ? BookFormat.values.byName(json['file_format'] as String) : null,
      fileSize: json['file_size'] as int?,
      fileHash: json['file_hash'] as String?,
      isPhysical: json['is_physical'] as bool? ?? false,
      physicalLocation: json['physical_location'] as String?,
      lentTo: json['lent_to'] as String?,
      lentAt: json['lent_at'] != null ? DateTime.parse(json['lent_at'] as String) : null,
      readingStatus: LibraryReadingStatus.values.byName(json['reading_status'] as String? ?? 'unread'),
      currentPage: json['current_page'] as int?,
      currentPosition: (json['current_position'] as num?)?.toDouble() ?? 0.0,
      currentCfi: json['current_cfi'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      rating: json['rating'] as int?,
      customMetadata: json['custom_metadata'] as Map<String, dynamic>?,
      seriesId: json['series_id'] as String?,
      seriesName: json['series_name'] as String?,
      seriesNumber: (json['series_number'] as num?)?.toDouble(),
      addedAt: DateTime.parse(json['added_at'] as String),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      lastReadAt: json['last_read_at'] != null ? DateTime.parse(json['last_read_at'] as String) : null,
    );
  }
}
