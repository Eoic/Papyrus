import 'package:flutter/foundation.dart';
import 'package:papyrus/models/daily_activity.dart';
import 'package:papyrus/models/genre_stats.dart';
import 'package:papyrus/models/reading_streak.dart';

/// Time period for statistics filtering.
enum StatsPeriod {
  week,
  month,
  year,
  allTime,
  custom,
}

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String get fullMonthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
class StatisticsProvider extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  String? _error;

  // Selected period
  StatsPeriod _selectedPeriod = StatsPeriod.week;

  // Custom date range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Summary statistics
  int _totalBooks = 0;
  int _goalsCompleted = 0;
  int _totalReadingMinutes = 0;
  int _pagesRead = 0;

  // Enhanced statistics
  SessionStats _sessionStats = const SessionStats(
    totalSessions: 0,
    totalMinutes: 0,
    totalPages: 0,
  );

  // Chart data
  List<DailyActivity> _readingTimeData = [];
  List<DailyActivity> _pagesReadData = [];
  List<MonthlyStats> _monthlyStats = [];
  List<GenreStats> _genreDistribution = [];
  ReadingStreak _streak = ReadingStreak.empty;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get error => _error;

  StatsPeriod get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  int get totalBooks => _totalBooks;
  int get goalsCompleted => _goalsCompleted;
  int get totalReadingMinutes => _totalReadingMinutes;
  int get pagesRead => _pagesRead;

  SessionStats get sessionStats => _sessionStats;
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
    final hours = _totalReadingMinutes / 60;
    if (hours < 1) return '${_totalReadingMinutes}m';
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

  /// Loads statistics data.
  Future<void> loadStatistics() async {
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

  void _loadSampleData() {
    // Summary stats (varies by period)
    _updateDataForPeriod();

    // Genre distribution (constant)
    _genreDistribution = GenreStats.sample;

    // Streak
    _streak = ReadingStreak.sample;

    // Monthly stats
    _monthlyStats = _generateMonthlyStats();
  }

  void _updateDataForPeriod() {
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        _totalBooks = 2;
        _goalsCompleted = 1;
        _totalReadingMinutes = 210; // 3.5 hours
        _pagesRead = 89;
        _readingTimeData = DailyActivity.sampleWeek;
        _pagesReadData = DailyActivity.sampleWeek;
        _sessionStats = const SessionStats(
          totalSessions: 8,
          totalMinutes: 210,
          totalPages: 89,
        );
        break;

      case StatsPeriod.month:
        _totalBooks = 8;
        _goalsCompleted = 4;
        _totalReadingMinutes = 900; // 15 hours
        _pagesRead = 380;
        _readingTimeData = _generateMonthlyData();
        _pagesReadData = _generateMonthlyData();
        _sessionStats = const SessionStats(
          totalSessions: 32,
          totalMinutes: 900,
          totalPages: 380,
        );
        break;

      case StatsPeriod.year:
        _totalBooks = 45;
        _goalsCompleted = 12;
        _totalReadingMinutes = 2730; // 45.5 hours
        _pagesRead = 4230;
        _readingTimeData = _generateYearlyData();
        _pagesReadData = _generateYearlyData();
        _sessionStats = const SessionStats(
          totalSessions: 156,
          totalMinutes: 2730,
          totalPages: 4230,
        );
        break;

      case StatsPeriod.allTime:
        _totalBooks = 135;
        _goalsCompleted = 24;
        _totalReadingMinutes = 8100; // 135 hours
        _pagesRead = 12500;
        _readingTimeData = _generateYearlyData();
        _pagesReadData = _generateYearlyData();
        _sessionStats = const SessionStats(
          totalSessions: 520,
          totalMinutes: 8100,
          totalPages: 12500,
        );
        break;

      case StatsPeriod.custom:
        // Use custom range if set, otherwise use default
        if (_customStartDate != null && _customEndDate != null) {
          final days = _customEndDate!.difference(_customStartDate!).inDays + 1;
          _totalBooks = (days / 7 * 2).round().clamp(1, 50);
          _goalsCompleted = (days / 30).round().clamp(0, 10);
          _totalReadingMinutes = (days * 30).clamp(0, 5000);
          _pagesRead = (days * 13).clamp(0, 8000);
          _readingTimeData = _generateCustomRangeData(days);
          _pagesReadData = _generateCustomRangeData(days);
          _sessionStats = SessionStats(
            totalSessions: (days * 1.5).round(),
            totalMinutes: _totalReadingMinutes,
            totalPages: _pagesRead,
          );
        }
        break;
    }
  }

  List<DailyActivity> _generateMonthlyData() {
    // Generate 4 weeks of sample data
    final now = DateTime.now();
    return List.generate(28, (i) {
      final date = now.subtract(Duration(days: 27 - i));
      final seed = (i * 17) % 60;
      return DailyActivity(
        date: date,
        readingMinutes: seed + 10,
        pagesRead: (seed + 10) ~/ 2,
        booksRead: [],
      );
    });
  }

  List<DailyActivity> _generateYearlyData() {
    // Generate monthly averages as daily activity (12 entries)
    final now = DateTime.now();
    const monthlyMinutes = [180, 210, 150, 240, 200, 120, 180, 220, 190, 160, 140, 0];
    return List.generate(12, (i) {
      if (i >= now.month) {
        return DailyActivity(
          date: DateTime(now.year, i + 1, 1),
          readingMinutes: 0,
          pagesRead: 0,
          booksRead: [],
        );
      }
      return DailyActivity(
        date: DateTime(now.year, i + 1, 1),
        readingMinutes: monthlyMinutes[i],
        pagesRead: monthlyMinutes[i] ~/ 2,
        booksRead: [],
      );
    });
  }

  List<DailyActivity> _generateCustomRangeData(int days) {
    final now = DateTime.now();
    return List.generate(days.clamp(1, 60), (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final seed = (i * 13 + 7) % 55;
      return DailyActivity(
        date: date,
        readingMinutes: seed + 15,
        pagesRead: (seed + 15) ~/ 2,
        booksRead: [],
      );
    });
  }

  List<MonthlyStats> _generateMonthlyStats() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final month = ((now.month - 1 - i) % 12) + 1;
      final year = now.year - ((now.month - 1 - i) < 0 ? 1 : 0);
      final seed = (i * 7 + 3) % 5;
      return MonthlyStats(
        month: month,
        year: year,
        booksRead: seed + 2,
        pagesRead: (seed + 2) * 150,
        readingMinutes: (seed + 2) * 120,
      );
    }).reversed.toList();
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
