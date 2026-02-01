/// Format of the book.
enum BookFormat {
  epub,
  pdf,
  mobi,
  azw3,
  physical,
  txt,
  cbr,
  cbz,
}

/// Book data model with all fields needed for the library.
class BookData {
  final String id;
  final String title;
  final String author;
  final String? coverURL;
  final bool isFinished;
  final double progress; // 0.0 to 1.0
  final List<String> shelves;
  final List<String> topics;
  final BookFormat format;
  final bool isFavorite;
  final DateTime? lastReadAt;
  final int? totalPages;
  final int? currentPage;

  const BookData({
    required this.id,
    required this.title,
    required this.author,
    this.coverURL,
    this.isFinished = false,
    this.progress = 0.0,
    this.shelves = const [],
    this.topics = const [],
    this.format = BookFormat.epub,
    this.isFavorite = false,
    this.lastReadAt,
    this.totalPages,
    this.currentPage,
  });

  /// Check if the book is currently being read (has some progress but not finished).
  bool get isReading => progress > 0 && progress < 1.0 && !isFinished;

  /// Get display string for format.
  String get formatLabel {
    switch (format) {
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.mobi:
        return 'MOBI';
      case BookFormat.azw3:
        return 'AZW3';
      case BookFormat.physical:
        return 'Physical';
      case BookFormat.txt:
        return 'TXT';
      case BookFormat.cbr:
        return 'CBR';
      case BookFormat.cbz:
        return 'CBZ';
    }
  }

  /// Get progress as percentage string.
  String get progressLabel => '${(progress * 100).round()}%';

  /// Create a copy with updated fields.
  BookData copyWith({
    String? id,
    String? title,
    String? author,
    String? coverURL,
    bool? isFinished,
    double? progress,
    List<String>? shelves,
    List<String>? topics,
    BookFormat? format,
    bool? isFavorite,
    DateTime? lastReadAt,
    int? totalPages,
    int? currentPage,
  }) {
    return BookData(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverURL: coverURL ?? this.coverURL,
      isFinished: isFinished ?? this.isFinished,
      progress: progress ?? this.progress,
      shelves: shelves ?? this.shelves,
      topics: topics ?? this.topics,
      format: format ?? this.format,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  /// Sample books for development and testing.
  static List<BookData> get sampleBooks => [
        BookData(
          id: '1',
          title: 'The Pragmatic Programmer',
          author: 'David Thomas, Andrew Hunt',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1401432508i/4099.jpg',
          progress: 0.75,
          shelves: ['Technical', 'Favorites'],
          topics: ['Programming', 'Software Engineering'],
          format: BookFormat.epub,
          isFavorite: true,
          lastReadAt: DateTime.now().subtract(const Duration(hours: 2)),
          totalPages: 352,
          currentPage: 264,
        ),
        BookData(
          id: '2',
          title: 'Clean Code',
          author: 'Robert C. Martin',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436202607i/3735293.jpg',
          progress: 1.0,
          isFinished: true,
          shelves: ['Technical', 'Completed'],
          topics: ['Programming', 'Best Practices'],
          format: BookFormat.pdf,
          isFavorite: true,
        ),
        BookData(
          id: '3',
          title: 'Dune',
          author: 'Frank Herbert',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          progress: 0.45,
          shelves: ['Fiction', 'Sci-Fi'],
          topics: ['Science Fiction', 'Classic'],
          format: BookFormat.epub,
          lastReadAt: DateTime.now().subtract(const Duration(days: 1)),
          totalPages: 688,
          currentPage: 310,
        ),
        BookData(
          id: '4',
          title: '1984',
          author: 'George Orwell',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg',
          progress: 1.0,
          isFinished: true,
          shelves: ['Fiction', 'Completed'],
          topics: ['Dystopian', 'Classic'],
          format: BookFormat.physical,
        ),
        BookData(
          id: '5',
          title: 'Design Patterns',
          author: 'Gang of Four',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348027904i/85009.jpg',
          progress: 0.2,
          shelves: ['Technical', 'Reference'],
          topics: ['Programming', 'Architecture'],
          format: BookFormat.pdf,
          lastReadAt: DateTime.now().subtract(const Duration(days: 7)),
          totalPages: 416,
          currentPage: 83,
        ),
        BookData(
          id: '6',
          title: 'The Hobbit',
          author: 'J.R.R. Tolkien',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg',
          progress: 0.0,
          shelves: ['Fiction', 'To Read'],
          topics: ['Fantasy', 'Classic'],
          format: BookFormat.epub,
          isFavorite: true,
        ),
        BookData(
          id: '7',
          title: 'Refactoring',
          author: 'Martin Fowler',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386925632i/44936.jpg',
          progress: 0.6,
          shelves: ['Technical'],
          topics: ['Programming', 'Best Practices'],
          format: BookFormat.mobi,
          lastReadAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        BookData(
          id: '8',
          title: 'Sapiens',
          author: 'Yuval Noah Harari',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg',
          progress: 0.85,
          shelves: ['Non-Fiction', 'History'],
          topics: ['History', 'Anthropology'],
          format: BookFormat.epub,
          isFavorite: true,
          lastReadAt: DateTime.now().subtract(const Duration(hours: 5)),
          totalPages: 464,
          currentPage: 394,
        ),
        BookData(
          id: '9',
          title: 'Neuromancer',
          author: 'William Gibson',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554437249i/6088007.jpg',
          progress: 0.0,
          shelves: ['Fiction', 'Sci-Fi', 'To Read'],
          topics: ['Science Fiction', 'Cyberpunk'],
          format: BookFormat.epub,
        ),
        BookData(
          id: '10',
          title: 'Atomic Habits',
          author: 'James Clear',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg',
          progress: 1.0,
          isFinished: true,
          shelves: ['Non-Fiction', 'Self-Help', 'Completed'],
          topics: ['Productivity', 'Psychology'],
          format: BookFormat.physical,
          isFavorite: true,
        ),
        BookData(
          id: '11',
          title: 'The Linux Command Line',
          author: 'William Shotts',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1344692678i/11724436.jpg',
          progress: 0.3,
          shelves: ['Technical', 'Reference'],
          topics: ['Linux', 'Command Line'],
          format: BookFormat.pdf,
          lastReadAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        BookData(
          id: '12',
          title: 'Foundation',
          author: 'Isaac Asimov',
          coverURL: 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417900846i/29579.jpg',
          progress: 0.0,
          shelves: ['Fiction', 'Sci-Fi', 'To Read'],
          topics: ['Science Fiction', 'Classic'],
          format: BookFormat.epub,
        ),
      ];
}
