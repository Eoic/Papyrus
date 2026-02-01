/// Represents genre distribution statistics.
class GenreStats {
  /// The genre name.
  final String genre;

  /// Number of books in this genre.
  final int bookCount;

  /// Percentage of total books (0.0 to 1.0).
  final double percentage;

  /// Color for chart rendering (hex string).
  final String? colorHex;

  const GenreStats({
    required this.genre,
    required this.bookCount,
    required this.percentage,
    this.colorHex,
  });

  /// Percentage as an integer (0-100).
  int get percentageInt => (percentage * 100).round();

  /// Sample genre statistics for development and testing.
  static List<GenreStats> get sample => const [
        GenreStats(
          genre: 'Fiction',
          bookCount: 45,
          percentage: 0.45,
          colorHex: '#5654A8',
        ),
        GenreStats(
          genre: 'Non-fiction',
          bookCount: 30,
          percentage: 0.30,
          colorHex: '#7A5368',
        ),
        GenreStats(
          genre: 'History',
          bookCount: 15,
          percentage: 0.15,
          colorHex: '#006B5B',
        ),
        GenreStats(
          genre: 'Other',
          bookCount: 10,
          percentage: 0.10,
          colorHex: '#8B8B8B',
        ),
      ];

  /// Empty list for no data.
  static List<GenreStats> get empty => const [];
}
