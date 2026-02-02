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
  final String? title;
  final String? goalDescription;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final GoalPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  /// Whether this goal is currently active.
  final bool isActive;

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
    this.title,
    this.goalDescription,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.isRecurring = true,
    this.streak = 0,
    this.isArchived = false,
    this.completedAt,
  });

  // Backwards compatibility aliases
  int get target => targetValue;
  int get current => currentValue;

  /// Progress as a value between 0.0 and 1.0.
  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  /// Number of items remaining to reach the goal.
  int get remaining => (targetValue - currentValue).clamp(0, targetValue);

  /// Whether the goal has been completed.
  bool get isCompleted => currentValue >= targetValue;

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
    if (goalDescription != null) return goalDescription!;
    if (isCustomPeriod) {
      return 'Read $targetValue $typeLabel';
    }
    return 'Read $targetValue $typeLabel $periodLabel';
  }

  /// Display title for the goal.
  String get displayTitle {
    if (title != null) return title!;
    return description;
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
    String? title,
    String? goalDescription,
    GoalType? type,
    int? targetValue,
    int? currentValue,
    GoalPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isRecurring,
    int? streak,
    bool? isArchived,
    DateTime? completedAt,
  }) {
    return ReadingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      goalDescription: goalDescription ?? this.goalDescription,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isRecurring: isRecurring ?? this.isRecurring,
      streak: streak ?? this.streak,
      isArchived: isArchived ?? this.isArchived,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': goalDescription,
      'goal_type': type.name,
      'target_value': targetValue,
      'current_value': currentValue,
      'time_period': period.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'is_recurring': isRecurring,
      'streak': streak,
      'is_archived': isArchived,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      id: json['id'] as String,
      title: json['title'] as String?,
      goalDescription: json['description'] as String?,
      type: GoalType.values.byName(json['goal_type'] as String),
      targetValue: json['target_value'] as int,
      currentValue: json['current_value'] as int,
      period: GoalPeriod.values.byName(json['time_period'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      isRecurring: json['is_recurring'] as bool? ?? true,
      streak: json['streak'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Sample reading goals for backwards compatibility.
  static List<ReadingGoal> get sampleGoals {
    final now = DateTime.now();
    return [
      ReadingGoal(
        id: 'goal-1',
        title: 'Yearly reading goal',
        type: GoalType.books,
        targetValue: 12,
        currentValue: 3,
        period: GoalPeriod.yearly,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        isActive: true,
        isRecurring: true,
      ),
      ReadingGoal(
        id: 'goal-2',
        title: 'Daily reading habit',
        type: GoalType.minutes,
        targetValue: 30,
        currentValue: 45,
        period: GoalPeriod.daily,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
        isActive: true,
        isRecurring: true,
        streak: 5,
      ),
      ReadingGoal(
        id: 'goal-3',
        title: 'Weekly pages',
        type: GoalType.pages,
        targetValue: 100,
        currentValue: 65,
        period: GoalPeriod.weekly,
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now.add(Duration(days: 7 - now.weekday)),
        isActive: true,
        isRecurring: false,
      ),
      ReadingGoal(
        id: 'goal-4',
        title: 'Summer reading challenge',
        goalDescription: 'Read 5 books during summer vacation',
        type: GoalType.books,
        targetValue: 5,
        currentValue: 2,
        period: GoalPeriod.custom,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 2, 0),
        isActive: true,
        isRecurring: false,
      ),
    ];
  }

  /// Sample completed goals for backwards compatibility.
  static List<ReadingGoal> get sampleCompletedGoals {
    final now = DateTime.now();
    return [
      ReadingGoal(
        id: 'goal-5',
        title: 'Q1 reading goal',
        type: GoalType.books,
        targetValue: 6,
        currentValue: 6,
        period: GoalPeriod.custom,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 3, 31),
        isActive: false,
        isRecurring: false,
        isArchived: true,
        completedAt: DateTime(now.year, 3, 15),
      ),
      ReadingGoal(
        id: 'goal-6',
        title: 'Last year reading time',
        type: GoalType.minutes,
        targetValue: 6000,
        currentValue: 6000,
        period: GoalPeriod.yearly,
        startDate: DateTime(now.year - 1, 1, 1),
        endDate: DateTime(now.year - 1, 12, 31),
        isActive: false,
        isRecurring: true,
        isArchived: true,
        completedAt: DateTime(now.year - 1, 12, 20),
      ),
    ];
  }
}
