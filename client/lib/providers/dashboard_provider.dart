import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/models/reading_goal.dart';

/// Provider for dashboard state management.
/// Uses DataStore as the single source of truth.
class DashboardProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Loading state
  bool _isLoading = false;
  String? _error;

  // Activity period (for desktop toggle)
  ActivityPeriod _activityPeriod = ActivityPeriod.week;

  // Week/month offset for navigation (0 = current, -1 = previous, etc.)
  int _weekOffset = 0;
  int _monthOffset = 0;

  // Cached activity data (recalculated on demand)
  List<DailyActivity> _weeklyActivity = [];

  /// Attach to a DataStore instance.
  void attach(DataStore dataStore) {
    if (_dataStore != dataStore) {
      _dataStore?.removeListener(_onDataStoreChanged);
      _dataStore = dataStore;
      _dataStore!.addListener(_onDataStoreChanged);
      _loadActivityData();
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

  /// Get current book (most recently read with progress < 100%).
  Book? get currentBook {
    if (_dataStore == null) return null;
    final readingBooks = _dataStore!.books.where((b) => b.isReading).toList()
      ..sort(
        (a, b) => (b.lastReadAt ?? DateTime(2000)).compareTo(
          a.lastReadAt ?? DateTime(2000),
        ),
      );
    return readingBooks.isNotEmpty ? readingBooks.first : null;
  }

  /// Get active reading goals from DataStore.
  List<ReadingGoal> get activeGoals {
    if (_dataStore == null) return [];
    return _dataStore!.activeGoals;
  }

  List<DailyActivity> get weeklyActivity => _weeklyActivity;

  /// Get recently added books (last 5).
  List<Book> get recentlyAdded {
    if (_dataStore == null) return [];
    final books = List<Book>.from(_dataStore!.books)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return books.take(5).toList();
  }

  /// Today's reading minutes from reading sessions.
  int get todayReadingMinutes {
    if (_dataStore == null) return 0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todaySessions = _dataStore!.readingSessions.where(
      (s) => s.startTime.isAfter(todayStart),
    );
    return todaySessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get weekOffset => _weekOffset;
  int get monthOffset => _monthOffset;

  /// Total book count from DataStore.
  int get totalBooks => _dataStore?.books.length ?? 0;

  /// Total shelf count from DataStore.
  int get totalShelves => _dataStore?.shelves.length ?? 0;

  /// Total tag count from DataStore.
  int get totalTopics => _dataStore?.tags.length ?? 0;

  /// Total reading minutes from all sessions.
  int get totalReadingMinutes {
    if (_dataStore == null) return 0;
    return _dataStore!.readingSessions.fold(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
  }

  ActivityPeriod get activityPeriod => _activityPeriod;

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Time-based greeting message.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Whether there's a book currently being read.
  bool get hasCurrentBook => currentBook != null;

  /// Whether there are active reading goals.
  bool get hasActiveGoals => activeGoals.isNotEmpty;

  /// Today's reading time formatted.
  String get todayReadingLabel {
    final minutes = todayReadingMinutes;
    if (minutes == 0) return '0 minutes';
    if (minutes == 1) return '1 minute';
    if (minutes < 60) return '$minutes minutes';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '${hours}h ${mins}m';
  }

  /// Total reading time formatted for quick stats.
  String get totalReadingLabel {
    final hours = totalReadingMinutes ~/ 60;
    if (hours == 0) return '${totalReadingMinutes}m';
    return '${hours}h';
  }

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads all dashboard data. With DataStore, this is mainly for loading state UX.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay for realistic UX
      await Future.delayed(const Duration(milliseconds: 100));

      _loadActivityData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the activity period (week/month).
  void setActivityPeriod(ActivityPeriod period) {
    if (_activityPeriod != period) {
      _activityPeriod = period;
      // Reset offset when switching periods
      _weekOffset = 0;
      _monthOffset = 0;
      _loadActivityData();
      notifyListeners();
    }
  }

  /// Navigate to previous week/month.
  void goToPreviousPeriod() {
    if (_activityPeriod == ActivityPeriod.week) {
      _weekOffset--;
    } else {
      _monthOffset--;
    }
    _loadActivityData();
    notifyListeners();
  }

  /// Navigate to next week/month.
  void goToNextPeriod() {
    if (_activityPeriod == ActivityPeriod.week) {
      if (_weekOffset < 0) {
        _weekOffset++;
      }
    } else {
      if (_monthOffset < 0) {
        _monthOffset++;
      }
    }
    _loadActivityData();
    notifyListeners();
  }

  /// Whether we can navigate to the next period (can't go past current).
  bool get canGoToNextPeriod {
    if (_activityPeriod == ActivityPeriod.week) {
      return _weekOffset < 0;
    }
    return _monthOffset < 0;
  }

  /// Get the period label (e.g., "This week", "Jan 15-21", "December 2024").
  String get periodLabel {
    if (_activityPeriod == ActivityPeriod.week) {
      if (_weekOffset == 0) return 'This week';
      if (_weekOffset == -1) return 'Last week';
      return _getWeekRangeLabel(_weekOffset);
    } else {
      if (_monthOffset == 0) return 'This month';
      if (_monthOffset == -1) return 'Last month';
      return _getMonthLabel(_monthOffset);
    }
  }

  /// Refreshes dashboard data.
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  void _loadActivityData() {
    if (_dataStore == null) {
      _weeklyActivity = DailyActivity.sampleWeek;
      return;
    }

    final offset = _activityPeriod == ActivityPeriod.week
        ? _weekOffset
        : _monthOffset;
    _weeklyActivity = _generateActivityFromSessions(offset);
  }

  List<DailyActivity> _generateActivityFromSessions(int offset) {
    if (_dataStore == null) return [];

    final now = DateTime.now();
    final weekStart = now.subtract(
      Duration(days: now.weekday - 1 + (-offset * 7)),
    );

    return List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Get sessions for this day
      final daySessions = _dataStore!.readingSessions.where(
        (s) =>
            s.startTime.isAfter(
              dayStart.subtract(const Duration(seconds: 1)),
            ) &&
            s.startTime.isBefore(dayEnd),
      );

      final minutes = daySessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final pages = daySessions.fold(0, (sum, s) => sum + (s.pagesRead ?? 0));

      return DailyActivity(
        date: date,
        readingMinutes: minutes,
        pagesRead: pages,
        booksRead: [],
      );
    });
  }

  String _getWeekRangeLabel(int offset) {
    final now = DateTime.now();
    final weekStart = now.subtract(
      Duration(days: now.weekday - 1 + (-offset * 7)),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (weekStart.month == weekEnd.month) {
      return '${months[weekStart.month - 1]} ${weekStart.day}-${weekEnd.day}';
    }
    return '${months[weekStart.month - 1]} ${weekStart.day} - ${months[weekEnd.month - 1]} ${weekEnd.day}';
  }

  String _getMonthLabel(int offset) {
    final now = DateTime.now();
    var month = now.month + offset;
    var year = now.year;
    while (month <= 0) {
      month += 12;
      year--;
    }
    while (month > 12) {
      month -= 12;
      year++;
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[month - 1]} $year';
  }
}

/// Activity period for chart display.
enum ActivityPeriod { week, month }
