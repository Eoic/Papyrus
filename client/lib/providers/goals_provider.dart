import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/reading_goal.dart';

/// Provider for goals page state management.
/// Uses DataStore as the single source of truth.
class GoalsProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Loading state
  bool _isLoading = false;
  String? _error;

  /// Attach to a DataStore instance.
  void attach(DataStore dataStore) {
    if (_dataStore != dataStore) {
      _dataStore?.removeListener(_onDataStoreChanged);
      _dataStore = dataStore;
      _dataStore!.addListener(_onDataStoreChanged);
      notifyListeners();
    }
  }

  void _onDataStoreChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dataStore?.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get active goals from DataStore.
  List<ReadingGoal> get activeGoals {
    if (_dataStore == null) return [];
    return _dataStore!.activeGoals;
  }

  /// Get completed/archived goals from DataStore.
  List<ReadingGoal> get completedGoals {
    if (_dataStore == null) return [];
    return _dataStore!.completedGoals;
  }

  bool get hasActiveGoals => activeGoals.isNotEmpty;
  bool get hasCompletedGoals => completedGoals.isNotEmpty;

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads all goals data. With DataStore, this is mainly for loading state UX.
  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay for realistic UX
      await Future.delayed(const Duration(milliseconds: 100));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load goals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new goal. Persists to DataStore.
  Future<void> createGoal({
    required GoalType type,
    required int target,
    required GoalPeriod period,
    bool isRecurring = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

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
      targetValue: target,
      currentValue: 0,
      period: period,
      startDate: goalStartDate,
      endDate: goalEndDate,
      isRecurring: isRecurring,
    );

    _dataStore!.addReadingGoal(newGoal);
  }

  /// Deletes a goal by ID. Persists to DataStore.
  Future<void> deleteGoal(String goalId) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }
    _dataStore!.deleteReadingGoal(goalId);
  }

  /// Updates the progress of a goal. Persists to DataStore.
  Future<void> updateGoalProgress(String goalId, int newProgress) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    final goal = _dataStore!.getReadingGoal(goalId);
    if (goal != null) {
      var updatedGoal = goal.copyWith(currentValue: newProgress);

      // Check if goal is now completed
      if (updatedGoal.isCompleted && !goal.isArchived) {
        updatedGoal = updatedGoal.copyWith(
          completedAt: DateTime.now(),
          isArchived: true,
        );
      }

      _dataStore!.updateReadingGoal(updatedGoal);
    }
  }

  /// Updates a goal's properties. Persists to DataStore.
  Future<void> updateGoal({
    required String goalId,
    int? target,
    GoalType? type,
  }) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    final goal = _dataStore!.getReadingGoal(goalId);
    if (goal != null) {
      _dataStore!.updateReadingGoal(goal.copyWith(
        targetValue: target ?? goal.targetValue,
        type: type ?? goal.type,
      ));
    }
  }

  /// Archives (completes) a goal. Persists to DataStore.
  Future<void> archiveGoal(String goalId) async {
    if (_dataStore == null) {
      throw Exception('DataStore not attached');
    }

    final goal = _dataStore!.getReadingGoal(goalId);
    if (goal != null) {
      _dataStore!.updateReadingGoal(goal.copyWith(
        isArchived: true,
        completedAt: DateTime.now(),
      ));
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
