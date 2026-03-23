import 'package:flutter/foundation.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/models/genre_stats.dart';
import 'package:papyrus/models/reading_streak.dart';

/// Time period for statistics filtering.
enum StatsPeriod { week, month, year, allTime, custom }

/// Monthly reading statistics.
class MonthlyStats {
  final int month;
  final int year;
  final int booksRead;
  final int pagesRead;
  final int readingMinutes;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.booksRead,
    required this.pagesRead,
    required this.readingMinutes,
  });

  String get monthLabel {
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
    return months[month - 1];
  }

  String get fullMonthLabel {
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
    return months[month - 1];
  }
}

/// Reading session statistics.
class SessionStats {
  final int totalSessions;
  final int totalMinutes;
  final int totalPages;

  const SessionStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalPages,
  });

  /// Average session duration in minutes.
  double get averageSessionDuration =>
      totalSessions > 0 ? totalMinutes / totalSessions : 0;

  /// Reading velocity (pages per hour).
  double get pagesPerHour =>
      totalMinutes > 0 ? (totalPages / totalMinutes) * 60 : 0;

  /// Formatted average session duration.
  String get averageSessionLabel {
    final avg = averageSessionDuration.round();
    if (avg < 60) return '${avg}m';
    final hours = avg ~/ 60;
    final minutes = avg % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Formatted reading velocity.
  String get velocityLabel => '${pagesPerHour.toStringAsFixed(1)} pages/hr';
}

/// Provider for statistics page state management.
/// Uses DataStore as the single source of truth.
class StatisticsProvider extends ChangeNotifier {
  DataStore? _dataStore;

  // Loading state
  bool _isLoading = false;
  String? _error;

  // Selected period
  StatsPeriod _selectedPeriod = StatsPeriod.week;

  // Custom date range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Chart data
  List<DailyActivity> _readingTimeData = [];
  List<DailyActivity> _pagesReadData = [];
  List<MonthlyStats> _monthlyStats = [];
  List<GenreStats> _genreDistribution = [];
  ReadingStreak _streak = ReadingStreak.empty;

  /// Attach to a DataStore instance.
  void attach(DataStore dataStore) {
    if (_dataStore != dataStore) {
      _dataStore?.removeListener(_onDataStoreChanged);
      _dataStore = dataStore;
      _dataStore!.addListener(_onDataStoreChanged);
      _updateDataForPeriod();
      notifyListeners();
    }
  }

  void _onDataStoreChanged() {
    _updateDataForPeriod();
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

  StatsPeriod get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  /// Total books completed in the selected period.
  int get totalBooks {
    if (_dataStore == null) return 0;
    final range = _getDateRangeForPeriod();
    return _dataStore!.books
        .where(
          (b) =>
              b.completedAt != null &&
              b.completedAt!.isAfter(range.start) &&
              b.completedAt!.isBefore(range.end),
        )
        .length;
  }

  /// Goals completed in the selected period.
  int get goalsCompleted {
    if (_dataStore == null) return 0;
    final range = _getDateRangeForPeriod();
    return _dataStore!.readingGoals
        .where(
          (g) =>
              g.completedAt != null &&
              g.completedAt!.isAfter(range.start) &&
              g.completedAt!.isBefore(range.end),
        )
        .length;
  }

  /// Total reading minutes in the selected period.
  int get totalReadingMinutes {
    if (_dataStore == null) return 0;
    final range = _getDateRangeForPeriod();
    return _dataStore!.readingSessions
        .where(
          (s) =>
              s.startTime.isAfter(range.start) &&
              s.startTime.isBefore(range.end),
        )
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Pages read in the selected period.
  int get pagesRead {
    if (_dataStore == null) return 0;
    final range = _getDateRangeForPeriod();
    return _dataStore!.readingSessions
        .where(
          (s) =>
              s.startTime.isAfter(range.start) &&
              s.startTime.isBefore(range.end),
        )
        .fold(0, (sum, s) => sum + (s.pagesRead ?? 0));
  }

  /// Session statistics for the selected period.
  SessionStats get sessionStats {
    if (_dataStore == null) {
      return const SessionStats(
        totalSessions: 0,
        totalMinutes: 0,
        totalPages: 0,
      );
    }
    final range = _getDateRangeForPeriod();
    final sessions = _dataStore!.readingSessions
        .where(
          (s) =>
              s.startTime.isAfter(range.start) &&
              s.startTime.isBefore(range.end),
        )
        .toList();

    return SessionStats(
      totalSessions: sessions.length,
      totalMinutes: sessions.fold(0, (sum, s) => sum + s.durationMinutes),
      totalPages: sessions.fold(0, (sum, s) => sum + (s.pagesRead ?? 0)),
    );
  }

  List<DailyActivity> get readingTimeData => _readingTimeData;
  List<DailyActivity> get pagesReadData => _pagesReadData;
  List<MonthlyStats> get monthlyStats => _monthlyStats;
  List<GenreStats> get genreDistribution => _genreDistribution;
  ReadingStreak get streak => _streak;

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Total reading time formatted (e.g., "3.5h").
  String get totalReadingLabel {
    final hours = totalReadingMinutes / 60;
    if (hours < 1) return '${totalReadingMinutes}m';
    if (hours == hours.truncate()) return '${hours.truncate()}h';
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Average reading time per day for the period.
  String get averageReadingLabel {
    if (_readingTimeData.isEmpty) return '0m';
    final avgMinutes = _readingTimeData.averageMinutes;
    if (avgMinutes < 60) return '${avgMinutes}m';
    final hours = avgMinutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Average daily reading time in minutes.
  int get averageDailyMinutes {
    if (_readingTimeData.isEmpty) return 0;
    return _readingTimeData.averageMinutes;
  }

  /// Period label for display.
  String get periodLabel {
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        return 'This week';
      case StatsPeriod.month:
        return 'This month';
      case StatsPeriod.year:
        return 'This year';
      case StatsPeriod.allTime:
        return 'All time';
      case StatsPeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatShortDate(_customStartDate!)} - ${_formatShortDate(_customEndDate!)}';
        }
        return 'Custom range';
    }
  }

  /// Short period label for dropdown.
  String get periodShortLabel {
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        return 'Week';
      case StatsPeriod.month:
        return 'Month';
      case StatsPeriod.year:
        return 'Year';
      case StatsPeriod.allTime:
        return 'All';
      case StatsPeriod.custom:
        return 'Custom';
    }
  }

  /// Whether custom date range is active.
  bool get hasCustomRange =>
      _selectedPeriod == StatsPeriod.custom &&
      _customStartDate != null &&
      _customEndDate != null;

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Loads statistics data. With DataStore, this is mainly for loading state UX.
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay for realistic UX
      await Future.delayed(const Duration(milliseconds: 100));

      _updateDataForPeriod();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load statistics: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the selected time period and reloads data.
  void setPeriod(StatsPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      if (period != StatsPeriod.custom) {
        _customStartDate = null;
        _customEndDate = null;
      }
      _updateDataForPeriod();
      notifyListeners();
    }
  }

  /// Sets a custom date range.
  void setCustomDateRange(DateTime startDate, DateTime endDate) {
    _selectedPeriod = StatsPeriod.custom;
    _customStartDate = startDate;
    _customEndDate = endDate;
    _updateDataForPeriod();
    notifyListeners();
  }

  /// Refreshes statistics data.
  Future<void> refresh() async {
    await loadStatistics();
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  ({DateTime start, DateTime end}) _getDateRangeForPeriod() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: now.add(const Duration(days: 1)),
        );
      case StatsPeriod.month:
        return (
          start: DateTime(now.year, now.month, 1),
          end: now.add(const Duration(days: 1)),
        );
      case StatsPeriod.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: now.add(const Duration(days: 1)),
        );
      case StatsPeriod.allTime:
        return (start: DateTime(2000), end: now.add(const Duration(days: 1)));
      case StatsPeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return (
            start: _customStartDate!,
            end: _customEndDate!.add(const Duration(days: 1)),
          );
        }
        return (
          start: now.subtract(const Duration(days: 7)),
          end: now.add(const Duration(days: 1)),
        );
    }
  }

  void _updateDataForPeriod() {
    // Genre distribution (constant for now)
    _genreDistribution = GenreStats.sample;

    // Streak
    _streak = ReadingStreak.sample;

    // Monthly stats
    _monthlyStats = _generateMonthlyStats();

    // Daily activity data
    _readingTimeData = _generateActivityData();
    _pagesReadData = _readingTimeData;
  }

  List<DailyActivity> _generateActivityData() {
    if (_dataStore == null) return DailyActivity.sampleWeek;

    final range = _getDateRangeForPeriod();
    final days = range.end.difference(range.start).inDays;

    // Limit to 60 days for performance
    final dataPoints = days.clamp(1, 60);

    return List.generate(dataPoints, (i) {
      final date = range.start.add(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySessions = _dataStore!.readingSessions.where(
        (s) =>
            s.startTime.isAfter(
              dayStart.subtract(const Duration(seconds: 1)),
            ) &&
            s.startTime.isBefore(dayEnd),
      );

      return DailyActivity(
        date: date,
        readingMinutes: daySessions.fold(
          0,
          (sum, s) => sum + s.durationMinutes,
        ),
        pagesRead: daySessions.fold(0, (sum, s) => sum + (s.pagesRead ?? 0)),
        booksRead: [],
      );
    });
  }

  List<MonthlyStats> _generateMonthlyStats() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final month = ((now.month - 1 - i) % 12) + 1;
      final year = now.year - ((now.month - 1 - i) < 0 ? 1 : 0);

      if (_dataStore == null) {
        final seed = (i * 7 + 3) % 5;
        return MonthlyStats(
          month: month,
          year: year,
          booksRead: seed + 2,
          pagesRead: (seed + 2) * 150,
          readingMinutes: (seed + 2) * 120,
        );
      }

      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 1);

      final monthSessions = _dataStore!.readingSessions.where(
        (s) =>
            s.startTime.isAfter(
              monthStart.subtract(const Duration(seconds: 1)),
            ) &&
            s.startTime.isBefore(monthEnd),
      );

      final booksCompleted = _dataStore!.books
          .where(
            (b) =>
                b.completedAt != null &&
                b.completedAt!.isAfter(monthStart) &&
                b.completedAt!.isBefore(monthEnd),
          )
          .length;

      return MonthlyStats(
        month: month,
        year: year,
        booksRead: booksCompleted,
        pagesRead: monthSessions.fold(0, (sum, s) => sum + (s.pagesRead ?? 0)),
        readingMinutes: monthSessions.fold(
          0,
          (sum, s) => sum + s.durationMinutes,
        ),
      );
    }).reversed.toList();
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
