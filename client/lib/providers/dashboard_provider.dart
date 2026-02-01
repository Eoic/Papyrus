import 'package:flutter/foundation.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/models/reading_goal.dart';

/// Provider for dashboard state management.
class DashboardProvider extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  String? _error;

  // Core dashboard data
  BookData? _currentBook;
  List<ReadingGoal> _activeGoals = [];
  List<DailyActivity> _weeklyActivity = [];
  List<BookData> _recentlyAdded = [];
  int _todayReadingMinutes = 0;

  // Quick stats
  int _totalBooks = 0;
  int _totalShelves = 0;
  int _totalTopics = 0;
  int _totalReadingMinutes = 0;

  // Activity period (for desktop toggle)
  ActivityPeriod _activityPeriod = ActivityPeriod.week;

  // Week/month offset for navigation (0 = current, -1 = previous, etc.)
  int _weekOffset = 0;
  int _monthOffset = 0;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get error => _error;

  BookData? get currentBook => _currentBook;
  List<ReadingGoal> get activeGoals => _activeGoals;
  List<DailyActivity> get weeklyActivity => _weeklyActivity;
  List<BookData> get recentlyAdded => _recentlyAdded;
  int get todayReadingMinutes => _todayReadingMinutes;

  int get weekOffset => _weekOffset;
  int get monthOffset => _monthOffset;

  int get totalBooks => _totalBooks;
  int get totalShelves => _totalShelves;
  int get totalTopics => _totalTopics;
  int get totalReadingMinutes => _totalReadingMinutes;

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
  bool get hasCurrentBook => _currentBook != null;

  /// Whether there are active reading goals.
  bool get hasActiveGoals => _activeGoals.isNotEmpty;

  /// Today's reading time formatted.
  String get todayReadingLabel {
    if (_todayReadingMinutes == 0) return '0 minutes';
    if (_todayReadingMinutes == 1) return '1 minute';
    if (_todayReadingMinutes < 60) return '$_todayReadingMinutes minutes';

    final hours = _todayReadingMinutes ~/ 60;
    final minutes = _todayReadingMinutes % 60;

    if (minutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '${hours}h ${minutes}m';
  }

  /// Total reading time formatted for quick stats.
  String get totalReadingLabel {
    final hours = _totalReadingMinutes ~/ 60;
    if (hours == 0) return '${_totalReadingMinutes}m';
    return '${hours}h';
  }

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads all dashboard data.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Load sample data
      _loadSampleData();

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
    _updateActivityForOffset();
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
    _updateActivityForOffset();
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

  void _loadSampleData() {
    final allBooks = BookData.sampleBooks;

    // Find current book (most recently read with progress < 100%)
    final readingBooks = allBooks.where((b) => b.isReading).toList()
      ..sort((a, b) => (b.lastReadAt ?? DateTime(2000))
          .compareTo(a.lastReadAt ?? DateTime(2000)));
    _currentBook = readingBooks.isNotEmpty ? readingBooks.first : null;

    // Set active goals
    _activeGoals = ReadingGoal.sampleGoals;

    // Set weekly activity
    _weeklyActivity = DailyActivity.sampleWeek;

    // Get recently added books (last 5)
    _recentlyAdded = allBooks.take(5).toList();

    // Today's reading (from sample data)
    final today = _weeklyActivity.where((a) => a.isToday).firstOrNull;
    _todayReadingMinutes = today?.readingMinutes ?? 32;

    // Quick stats
    _totalBooks = allBooks.length;
    _totalShelves = allBooks.expand((b) => b.shelves).toSet().length;
    _totalTopics = allBooks.expand((b) => b.topics).toSet().length;
    _totalReadingMinutes = 24 * 60; // 24 hours sample
  }

  void _updateActivityForOffset() {
    // In a real app, this would fetch data for the offset week/month
    // For now, we generate sample data with reduced activity for past periods
    if (_activityPeriod == ActivityPeriod.week) {
      _weeklyActivity = _generateActivityForWeekOffset(_weekOffset);
    } else {
      // For month view, we'd generate monthly data
      _weeklyActivity = _generateActivityForWeekOffset(_monthOffset);
    }
  }

  List<DailyActivity> _generateActivityForWeekOffset(int offset) {
    if (offset == 0) {
      return DailyActivity.sampleWeek;
    }
    // Generate sample data for past weeks (with somewhat different values)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + (-offset * 7)));
    return List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      // Pseudo-random values based on offset and day
      final seed = (offset.abs() * 7 + i + 1);
      final minutes = ((seed * 17) % 60) + 10;
      return DailyActivity(
        date: date,
        readingMinutes: minutes,
        pagesRead: minutes ~/ 2,
        booksRead: [],
      );
    });
  }

  String _getWeekRangeLabel(int offset) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + (-offset * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6));

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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

    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];

    return '${months[month - 1]} $year';
  }
}

/// Activity period for chart display.
enum ActivityPeriod {
  week,
  month,
}
