/// Type of reading goal.
enum GoalType {
  books,
  pages,
  minutes,
}

/// Period for the reading goal.
enum GoalPeriod {
  daily,
  weekly,
  monthly,
  yearly,
  custom, // User-defined date range
}

/// Represents a user's reading goal.
class ReadingGoal {
  final String id;
  final GoalType type;
  final int target;
  final int current;
  final GoalPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  /// Whether this goal repeats after completion.
  /// - true: Goal resets and repeats (e.g., "30 min daily" repeats each day)
  /// - false: One-off goal that doesn't repeat after completion
  final bool isRecurring;

  /// Current streak for recurring daily goals.
  final int streak;

  /// Whether this goal is completed (archived).
  final bool isArchived;

  /// Completion date for archived goals.
  final DateTime? completedAt;

  const ReadingGoal({
    required this.id,
    required this.type,
    required this.target,
    required this.current,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isRecurring = true,
    this.streak = 0,
    this.isArchived = false,
    this.completedAt,
  });

  /// Progress as a value between 0.0 and 1.0.
  double get progress => (current / target).clamp(0.0, 1.0);

  /// Number of items remaining to reach the goal.
  int get remaining => (target - current).clamp(0, target);

  /// Whether the goal has been completed.
  bool get isCompleted => current >= target;

  /// Progress as a percentage string.
  String get progressLabel => '${(progress * 100).round()}%';

  /// Display label for the goal type.
  String get typeLabel {
    switch (type) {
      case GoalType.books:
        return 'books';
      case GoalType.pages:
        return 'pages';
      case GoalType.minutes:
        return 'minutes';
    }
  }

  /// Display label for the period.
  String get periodLabel {
    switch (period) {
      case GoalPeriod.daily:
        return 'daily';
      case GoalPeriod.weekly:
        return 'this week';
      case GoalPeriod.monthly:
        return 'this month';
      case GoalPeriod.yearly:
        return 'this year';
      case GoalPeriod.custom:
        return _formatDateRange();
    }
  }

  String _formatDateRange() {
    final start = '${startDate.day}/${startDate.month}';
    final end = '${endDate.day}/${endDate.month}';
    if (startDate.year != endDate.year) {
      return '$start/${startDate.year} - $end/${endDate.year}';
    }
    return '$start - $end';
  }

  /// Whether this is a daily goal.
  bool get isDaily => period == GoalPeriod.daily;

  /// Whether this is a yearly goal.
  bool get isYearly => period == GoalPeriod.yearly;

  /// Whether this is a custom date range goal.
  bool get isCustomPeriod => period == GoalPeriod.custom;

  /// Full goal description.
  String get description {
    if (isCustomPeriod) {
      return 'Read $target $typeLabel';
    }
    return 'Read $target $typeLabel $periodLabel';
  }

  /// Status text (e.g., "4 books to go").
  String get statusText {
    if (isCompleted) {
      return 'Goal completed!';
    }
    return '$remaining $typeLabel to go';
  }

  /// Recurrence label for display.
  String get recurrenceLabel {
    if (isCustomPeriod) {
      return 'Custom range';
    }
    return isRecurring ? 'Recurring' : 'One-off';
  }

  /// Create a copy with updated fields.
  ReadingGoal copyWith({
    String? id,
    GoalType? type,
    int? target,
    int? current,
    GoalPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurring,
    int? streak,
    bool? isArchived,
    DateTime? completedAt,
  }) {
    return ReadingGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurring: isRecurring ?? this.isRecurring,
      streak: streak ?? this.streak,
      isArchived: isArchived ?? this.isArchived,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Sample reading goal for development and testing.
  static ReadingGoal get sample {
    final now = DateTime.now();
    return ReadingGoal(
      id: 'goal-1',
      type: GoalType.books,
      target: 12,
      current: 8,
      period: GoalPeriod.yearly,
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31),
      isRecurring: true,
    );
  }

  /// Empty goal (no goal set).
  static ReadingGoal? get empty => null;

  /// Sample reading goals for development and testing.
  static List<ReadingGoal> get sampleGoals {
    final now = DateTime.now();
    return [
      // Recurring yearly goal
      ReadingGoal(
        id: 'goal-1',
        type: GoalType.books,
        target: 12,
        current: 8,
        period: GoalPeriod.yearly,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        isRecurring: true,
      ),
      // Recurring daily goal with streak
      ReadingGoal(
        id: 'goal-2',
        type: GoalType.minutes,
        target: 30,
        current: 45,
        period: GoalPeriod.daily,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
        isRecurring: true,
        streak: 5,
      ),
      // One-off weekly goal
      ReadingGoal(
        id: 'goal-3',
        type: GoalType.pages,
        target: 50,
        current: 35,
        period: GoalPeriod.weekly,
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now.add(Duration(days: 7 - now.weekday)),
        isRecurring: false,
      ),
      // Custom date range goal
      ReadingGoal(
        id: 'goal-4',
        type: GoalType.books,
        target: 5,
        current: 2,
        period: GoalPeriod.custom,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 2, 0), // 2 months
        isRecurring: false,
      ),
    ];
  }

  /// Sample completed goals for development and testing.
  static List<ReadingGoal> get sampleCompletedGoals {
    final now = DateTime.now();
    return [
      ReadingGoal(
        id: 'goal-completed-1',
        type: GoalType.books,
        target: 6,
        current: 6,
        period: GoalPeriod.monthly,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 3, 31),
        isRecurring: false,
        isArchived: true,
        completedAt: DateTime(now.year, 3, 15),
      ),
      ReadingGoal(
        id: 'goal-completed-2',
        type: GoalType.minutes,
        target: 6000,
        current: 6000,
        period: GoalPeriod.yearly,
        startDate: DateTime(now.year - 1, 1, 1),
        endDate: DateTime(now.year - 1, 12, 31),
        isRecurring: true,
        isArchived: true,
        completedAt: DateTime(now.year - 1, 12, 20),
      ),
    ];
  }
}
