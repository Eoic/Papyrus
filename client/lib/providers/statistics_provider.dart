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
}

/// Provider for statistics page state management.
class StatisticsProvider extends ChangeNotifier {
  // Loading state
  bool _isLoading = false;
  String? _error;

  // Selected period
  StatsPeriod _selectedPeriod = StatsPeriod.week;

  // Summary statistics
  int _totalBooks = 0;
  int _goalsCompleted = 0;
  int _totalReadingMinutes = 0;
  int _pagesRead = 0;

  // Chart data
  List<DailyActivity> _readingTimeData = [];
  List<GenreStats> _genreDistribution = [];
  ReadingStreak _streak = ReadingStreak.empty;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get error => _error;

  StatsPeriod get selectedPeriod => _selectedPeriod;

  int get totalBooks => _totalBooks;
  int get goalsCompleted => _goalsCompleted;
  int get totalReadingMinutes => _totalReadingMinutes;
  int get pagesRead => _pagesRead;

  List<DailyActivity> get readingTimeData => _readingTimeData;
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
    }
  }

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
      _updateDataForPeriod();
      notifyListeners();
    }
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
  }

  void _updateDataForPeriod() {
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        _totalBooks = 2;
        _goalsCompleted = 1;
        _totalReadingMinutes = 210; // 3.5 hours
        _pagesRead = 89;
        _readingTimeData = DailyActivity.sampleWeek;
        break;

      case StatsPeriod.month:
        _totalBooks = 8;
        _goalsCompleted = 4;
        _totalReadingMinutes = 900; // 15 hours
        _pagesRead = 380;
        _readingTimeData = _generateMonthlyData();
        break;

      case StatsPeriod.year:
        _totalBooks = 45;
        _goalsCompleted = 12;
        _totalReadingMinutes = 2730; // 45.5 hours
        _pagesRead = 4230;
        _readingTimeData = _generateYearlyData();
        break;

      case StatsPeriod.allTime:
        _totalBooks = 135;
        _goalsCompleted = 24;
        _totalReadingMinutes = 8100; // 135 hours
        _pagesRead = 12500;
        _readingTimeData = _generateYearlyData();
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
    const monthlyMinutes = [180, 210, 150, 240, 200, 120, 180, 220, 0, 0, 0, 0];
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
}
