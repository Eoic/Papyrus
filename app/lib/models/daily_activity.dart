/// Represents reading activity for a single day.
class DailyActivity {
  final DateTime date;
  final int readingMinutes;
  final int pagesRead;
  final List<String> booksRead;

  const DailyActivity({
    required this.date,
    required this.readingMinutes,
    this.pagesRead = 0,
    this.booksRead = const [],
  });

  /// Whether there was any reading activity on this day.
  bool get hasActivity => readingMinutes > 0;

  /// Short day label (e.g., "Mon", "Tue").
  String get dayLabel => _weekdayShort[date.weekday - 1];

  /// Single letter day label (e.g., "M", "T").
  String get dayInitial => _weekdayInitial[date.weekday - 1];

  /// Full day name (e.g., "Monday", "Tuesday").
  String get dayName => _weekdayFull[date.weekday - 1];

  static const _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _weekdayInitial = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Formatted reading time (e.g., "45m", "1h 30m").
  String get readingTimeLabel {
    if (readingMinutes == 0) return '0m';
    if (readingMinutes < 60) return '${readingMinutes}m';

    final hours = readingMinutes ~/ 60;
    final minutes = readingMinutes % 60;

    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Whether this is today.
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Create a copy with updated fields.
  DailyActivity copyWith({
    DateTime? date,
    int? readingMinutes,
    int? pagesRead,
    List<String>? booksRead,
  }) {
    return DailyActivity(
      date: date ?? this.date,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      pagesRead: pagesRead ?? this.pagesRead,
      booksRead: booksRead ?? this.booksRead,
    );
  }

  /// Sample week of activity for development and testing.
  static List<DailyActivity> get sampleWeek {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return [
      DailyActivity(
        date: monday,
        readingMinutes: 45,
        pagesRead: 32,
        booksRead: ['1'],
      ),
      DailyActivity(
        date: monday.add(const Duration(days: 1)),
        readingMinutes: 52,
        pagesRead: 38,
        booksRead: ['1', '3'],
      ),
      DailyActivity(
        date: monday.add(const Duration(days: 2)),
        readingMinutes: 30,
        pagesRead: 22,
        booksRead: ['3'],
      ),
      DailyActivity(
        date: monday.add(const Duration(days: 3)),
        readingMinutes: 48,
        pagesRead: 35,
        booksRead: ['3'],
      ),
      DailyActivity(
        date: monday.add(const Duration(days: 4)),
        readingMinutes: 15,
        pagesRead: 10,
        booksRead: ['3'],
      ),
      DailyActivity(
        date: monday.add(const Duration(days: 5)),
        readingMinutes: 0,
        pagesRead: 0,
        booksRead: [],
      ),
      DailyActivity(
        date: monday.add(const Duration(days: 6)),
        readingMinutes: 55,
        pagesRead: 40,
        booksRead: ['1', '8'],
      ),
    ];
  }

  /// Empty week (no activity).
  static List<DailyActivity> get emptyWeek {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(
      7,
      (index) => DailyActivity(
        date: monday.add(Duration(days: index)),
        readingMinutes: 0,
      ),
    );
  }
}

/// Extension for calculating weekly statistics.
extension WeeklyActivityStats on List<DailyActivity> {
  /// Total reading minutes for the week.
  int get totalMinutes =>
      fold(0, (sum, activity) => sum + activity.readingMinutes);

  /// Average reading minutes per day.
  int get averageMinutes => isEmpty ? 0 : totalMinutes ~/ length;

  /// Formatted total reading time.
  String get totalTimeLabel {
    final minutes = totalMinutes;
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  /// Formatted average reading time.
  String get averageTimeLabel {
    final avg = averageMinutes;
    if (avg == 0) return '0m';
    return '${avg}m';
  }

  /// Maximum reading minutes in a single day.
  int get maxMinutes => isEmpty
      ? 0
      : map((a) => a.readingMinutes).reduce((a, b) => a > b ? a : b);
}
