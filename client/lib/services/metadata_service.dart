import 'dart:convert';
import 'package:http/http.dart' as http;

/// Source for fetching book metadata.
enum MetadataSource {
  openLibrary,
  googleBooks,
}

/// Result from a metadata search.
class BookMetadataResult {
  final MetadataSource source;
  final String? title;
  final String? subtitle;
  final List<String>? authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final String? coverUrl;
  final String? language;
  final String? isbn;
  final String? isbn13;
  final int? pageCount;

  const BookMetadataResult({
    required this.source,
    this.title,
    this.subtitle,
    this.authors,
    this.publisher,
    this.publishedDate,
    this.description,
    this.coverUrl,
    this.language,
    this.isbn,
    this.isbn13,
    this.pageCount,
  });

  /// Get the primary author or empty string.
  String get primaryAuthor => authors?.isNotEmpty == true ? authors!.first : '';

  /// Get co-authors (all authors except the first).
  List<String> get coAuthors =>
      authors != null && authors!.length > 1 ? authors!.sublist(1) : [];

  /// Source display name.
  String get sourceLabel {
    switch (source) {
      case MetadataSource.openLibrary:
        return 'Open Library';
      case MetadataSource.googleBooks:
        return 'Google Books';
    }
  }
}

/// Service for fetching book metadata from external APIs.
class MetadataService {
  final http.Client _client;

  MetadataService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for books by query (title, author, or general search).
  Future<List<BookMetadataResult>> search(
    String query,
    MetadataSource source,
  ) async {
    if (query.trim().isEmpty) return [];

    switch (source) {
      case MetadataSource.openLibrary:
        return _searchOpenLibrary(query);
      case MetadataSource.googleBooks:
        return _searchGoogleBooks(query);
    }
  }

  /// Search for a book by ISBN.
  Future<List<BookMetadataResult>> searchByIsbn(
    String isbn,
    MetadataSource source,
  ) async {
    final cleanIsbn = isbn.replaceAll(RegExp(r'[-\s]'), '');
    if (cleanIsbn.isEmpty) return [];

    switch (source) {
      case MetadataSource.openLibrary:
        return _searchOpenLibraryByIsbn(cleanIsbn);
      case MetadataSource.googleBooks:
        return _searchGoogleBooksByIsbn(cleanIsbn);
    }
  }

  // ============================================================================
  // OPEN LIBRARY API
  // ============================================================================

  Future<List<BookMetadataResult>> _searchOpenLibrary(String query) async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=10',
      );
      final response = await _client.get(uri);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];

      return docs.map((doc) => _parseOpenLibraryDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BookMetadataResult>> _searchOpenLibraryByIsbn(String isbn) async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json?isbn=$isbn&limit=5',
      );
      final response = await _client.get(uri);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];

      return docs.map((doc) => _parseOpenLibraryDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  BookMetadataResult _parseOpenLibraryDoc(Map<String, dynamic> doc) {
    // Get cover URL from cover_i (cover ID)
    String? coverUrl;
    final coverId = doc['cover_i'];
    if (coverId != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
    }

    // Get ISBNs
    final isbns = doc['isbn'] as List<dynamic>?;
    String? isbn;
    String? isbn13;
    if (isbns != null && isbns.isNotEmpty) {
      for (final i in isbns) {
        final isbnStr = i.toString();
        if (isbnStr.length == 10 && isbn == null) {
          isbn = isbnStr;
        } else if (isbnStr.length == 13 && isbn13 == null) {
          isbn13 = isbnStr;
        }
      }
    }

    return BookMetadataResult(
      source: MetadataSource.openLibrary,
      title: doc['title'] as String?,
      subtitle: doc['subtitle'] as String?,
      authors: (doc['author_name'] as List<dynamic>?)?.cast<String>(),
      publisher: (doc['publisher'] as List<dynamic>?)?.firstOrNull as String?,
      publishedDate: doc['first_publish_year']?.toString(),
      description: null, // Open Library search doesn't include description
      coverUrl: coverUrl,
      language: (doc['language'] as List<dynamic>?)?.firstOrNull as String?,
      isbn: isbn,
      isbn13: isbn13,
      pageCount: doc['number_of_pages_median'] as int?,
    );
  }

  // ============================================================================
  // GOOGLE BOOKS API
  // ============================================================================

  Future<List<BookMetadataResult>> _searchGoogleBooks(String query) async {
    try {
      final uri = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=10',
      );
      final response = await _client.get(uri);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items.map((item) => _parseGoogleBooksItem(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BookMetadataResult>> _searchGoogleBooksByIsbn(String isbn) async {
    try {
      final uri = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&maxResults=5',
      );
      final response = await _client.get(uri);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items.map((item) => _parseGoogleBooksItem(item)).toList();
    } catch (e) {
      return [];
    }
  }

  BookMetadataResult _parseGoogleBooksItem(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? {};

    // Get cover URL (prefer larger images)
    String? coverUrl;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    if (imageLinks != null) {
      coverUrl = imageLinks['large'] as String? ??
          imageLinks['medium'] as String? ??
          imageLinks['thumbnail'] as String?;
      // Convert HTTP to HTTPS
      coverUrl = coverUrl?.replaceFirst('http://', 'https://');
    }

    // Get ISBNs from industry identifiers
    String? isbn;
    String? isbn13;
    final identifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>? ?? [];
    for (final id in identifiers) {
      final type = id['type'] as String?;
      final identifier = id['identifier'] as String?;
      if (type == 'ISBN_10') {
        isbn = identifier;
      } else if (type == 'ISBN_13') {
        isbn13 = identifier;
      }
    }

    return BookMetadataResult(
      source: MetadataSource.googleBooks,
      title: volumeInfo['title'] as String?,
      subtitle: volumeInfo['subtitle'] as String?,
      authors: (volumeInfo['authors'] as List<dynamic>?)?.cast<String>(),
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      description: volumeInfo['description'] as String?,
      coverUrl: coverUrl,
      language: volumeInfo['language'] as String?,
      isbn: isbn,
      isbn13: isbn13,
      pageCount: volumeInfo['pageCount'] as int?,
    );
  }
}
