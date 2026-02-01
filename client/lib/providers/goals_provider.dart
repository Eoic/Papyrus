import 'package:flutter/foundation.dart';
import 'package:papyrus/models/reading_goal.dart';

/// Provider for goals page state management.
class GoalsProvider extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  String? _error;

  // Goals data
  List<ReadingGoal> _activeGoals = [];
  List<ReadingGoal> _completedGoals = [];

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ReadingGoal> get activeGoals => _activeGoals;
  List<ReadingGoal> get completedGoals => _completedGoals;

  bool get hasActiveGoals => _activeGoals.isNotEmpty;
  bool get hasCompletedGoals => _completedGoals.isNotEmpty;

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads all goals data.
  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Load sample data and separate by completion status
      final allGoals = ReadingGoal.sampleGoals;
      final archivedGoals = ReadingGoal.sampleCompletedGoals;

      // Active goals: not archived AND not completed (current < target)
      _activeGoals = allGoals.where((g) => !g.isArchived && !g.isCompleted).toList();

      // Completed goals: archived OR completed (current >= target)
      final completedFromActive = allGoals.where((g) => g.isCompleted && !g.isArchived).toList();
      _completedGoals = [...completedFromActive, ...archivedGoals];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load goals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new goal.
  Future<void> createGoal({
    required GoalType type,
    required int target,
    required GoalPeriod period,
    bool isRecurring = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();

    // Calculate dates based on period or use provided custom dates
    final DateTime goalStartDate;
    final DateTime goalEndDate;

    if (period == GoalPeriod.custom && startDate != null && endDate != null) {
      goalStartDate = startDate;
      goalEndDate = endDate;
    } else {
      goalStartDate = _getStartDateForPeriod(period, now);
      goalEndDate = _getEndDateForPeriod(period, now);
    }

    final newGoal = ReadingGoal(
      id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      target: target,
      current: 0,
      period: period,
      startDate: goalStartDate,
      endDate: goalEndDate,
      isRecurring: isRecurring,
    );

    _activeGoals = [..._activeGoals, newGoal];
    notifyListeners();
  }

  /// Deletes a goal by ID.
  Future<void> deleteGoal(String goalId) async {
    _activeGoals = _activeGoals.where((g) => g.id != goalId).toList();
    _completedGoals = _completedGoals.where((g) => g.id != goalId).toList();
    notifyListeners();
  }

  /// Updates the progress of a goal.
  Future<void> updateGoalProgress(String goalId, int newProgress) async {
    final goalIndex = _activeGoals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _activeGoals[goalIndex];
      final updatedGoal = goal.copyWith(current: newProgress);

      // Check if goal is now completed
      if (updatedGoal.isCompleted) {
        _activeGoals.removeAt(goalIndex);
        _completedGoals = [
          updatedGoal.copyWith(completedAt: DateTime.now()),
          ..._completedGoals,
        ];
      } else {
        _activeGoals[goalIndex] = updatedGoal;
      }
      notifyListeners();
    }
  }

  /// Updates a goal's properties.
  Future<void> updateGoal({
    required String goalId,
    int? target,
    GoalType? type,
  }) async {
    final goalIndex = _activeGoals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _activeGoals[goalIndex];
      _activeGoals[goalIndex] = goal.copyWith(
        target: target ?? goal.target,
        type: type ?? goal.type,
      );
      notifyListeners();
    }
  }

  /// Archives (completes) a goal.
  Future<void> archiveGoal(String goalId) async {
    final goalIndex = _activeGoals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _activeGoals[goalIndex];
      final archivedGoal = goal.copyWith(
        isArchived: true,
        completedAt: DateTime.now(),
      );
      _activeGoals.removeAt(goalIndex);
      _completedGoals = [archivedGoal, ..._completedGoals];
      notifyListeners();
    }
  }

  /// Refreshes goals data.
  Future<void> refresh() async {
    await loadGoals();
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  DateTime _getStartDateForPeriod(GoalPeriod period, DateTime now) {
    switch (period) {
      case GoalPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case GoalPeriod.weekly:
        return now.subtract(Duration(days: now.weekday - 1));
      case GoalPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case GoalPeriod.yearly:
        return DateTime(now.year, 1, 1);
      case GoalPeriod.custom:
        return now; // Should be provided by caller
    }
  }

  DateTime _getEndDateForPeriod(GoalPeriod period, DateTime now) {
    switch (period) {
      case GoalPeriod.daily:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case GoalPeriod.weekly:
        return now.add(Duration(days: 7 - now.weekday));
      case GoalPeriod.monthly:
        return DateTime(now.year, now.month + 1, 0);
      case GoalPeriod.yearly:
        return DateTime(now.year, 12, 31);
      case GoalPeriod.custom:
        return now.add(const Duration(days: 30)); // Should be provided by caller
    }
  }
}
