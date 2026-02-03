/// Represents reading streak statistics.
class ReadingStreak {
  /// Current consecutive reading days.
  final int currentStreak;

  /// Best streak ever achieved.
  final int bestStreak;

  /// Number of days with reading activity this month.
  final int daysThisMonth;

  /// Total days in the current month.
  final int totalDaysInMonth;

  const ReadingStreak({
    required this.currentStreak,
    required this.bestStreak,
    required this.daysThisMonth,
    required this.totalDaysInMonth,
  });

  /// Percentage of days this month with reading activity.
  double get monthlyPercentage =>
      totalDaysInMonth > 0 ? daysThisMonth / totalDaysInMonth : 0.0;

  /// Whether currently on a streak.
  bool get hasActiveStreak => currentStreak > 0;

  /// Whether current streak is the best streak.
  bool get isCurrentBest => currentStreak >= bestStreak && currentStreak > 0;

  /// Sample streak data for development and testing.
  static ReadingStreak get sample => const ReadingStreak(
    currentStreak: 5,
    bestStreak: 21,
    daysThisMonth: 18,
    totalDaysInMonth: 26,
  );

  /// Empty streak (no reading activity).
  static ReadingStreak get empty => const ReadingStreak(
    currentStreak: 0,
    bestStreak: 0,
    daysThisMonth: 0,
    totalDaysInMonth: 30,
  );
}
