import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for user preferences persisted via SharedPreferences.
///
/// Manages theme, reading defaults, library display, notification toggles,
/// storage & sync configuration, privacy, and accessibility settings.
/// All changes are written through to disk immediately.
class PreferencesProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  PreferencesProvider(this._prefs);

  // -- Keys -----------------------------------------------------------------

  // Theme
  static const _keyThemeMode = 'theme_mode';

  // Reading
  static const _keyDefaultFont = 'default_font';
  static const _keyDefaultFontSize = 'default_font_size';
  static const _keyLineSpacing = 'line_spacing';
  static const _keyTextAlignment = 'text_alignment';
  static const _keyMargins = 'margins';
  static const _keyReadingMode = 'reading_mode';
  static const _keyPageTurnAnimation = 'page_turn_animation';
  static const _keyDefaultHighlightColor = 'default_highlight_color';

  // Library
  static const _keyDefaultViewMode = 'default_view_mode';
  static const _keyDefaultSortOrder = 'default_sort_order';
  static const _keyMetadataSource = 'metadata_source';
  static const _keyAnnotationExportFormat = 'annotation_export_format';

  // Notifications
  static const _keyGoalReminders = 'goal_reminders';
  static const _keyStreakAlerts = 'streak_alerts';
  static const _keySyncStatusNotifications = 'sync_status_notifications';

  // Storage & sync
  static const _keyStorageBackend = 'storage_backend';
  static const _keySyncEnabled = 'sync_enabled';
  static const _keyServerUrl = 'server_url';
  static const _keyServerType = 'server_type';
  static const _keySyncInterval = 'sync_interval';
  static const _keyConflictResolution = 'conflict_resolution';

  // Privacy
  static const _keyAnalyticsOptIn = 'analytics_opt_in';

  // Accessibility
  static const _keyReduceAnimations = 'reduce_animations';
  static const _keyDyslexiaFont = 'dyslexia_font';

  // -- Theme ----------------------------------------------------------------

  /// Current theme mode preference: 'light', 'dark', or 'system'.
  String get themeModePref => _prefs.getString(_keyThemeMode) ?? 'system';

  /// Resolved [ThemeMode] for use in MaterialApp.
  ThemeMode get themeMode {
    switch (themeModePref) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  set themeModePref(String value) {
    _prefs.setString(_keyThemeMode, value);
    notifyListeners();
  }

  // -- Reading --------------------------------------------------------------

  String get defaultFont => _prefs.getString(_keyDefaultFont) ?? 'Georgia';

  set defaultFont(String value) {
    _prefs.setString(_keyDefaultFont, value);
    notifyListeners();
  }

  double get defaultFontSize => _prefs.getDouble(_keyDefaultFontSize) ?? 16;

  set defaultFontSize(double value) {
    _prefs.setDouble(_keyDefaultFontSize, value);
    notifyListeners();
  }

  /// Line spacing: 'compact', 'normal', or 'relaxed'.
  String get lineSpacing => _prefs.getString(_keyLineSpacing) ?? 'normal';

  set lineSpacing(String value) {
    _prefs.setString(_keyLineSpacing, value);
    notifyListeners();
  }

  /// Text alignment: 'left' or 'justify'.
  String get textAlignment => _prefs.getString(_keyTextAlignment) ?? 'left';

  set textAlignment(String value) {
    _prefs.setString(_keyTextAlignment, value);
    notifyListeners();
  }

  /// Margins: 'small', 'medium', or 'large'.
  String get margins => _prefs.getString(_keyMargins) ?? 'medium';

  set margins(String value) {
    _prefs.setString(_keyMargins, value);
    notifyListeners();
  }

  /// Reading mode: 'paginated' or 'scroll'.
  String get readingMode => _prefs.getString(_keyReadingMode) ?? 'paginated';

  set readingMode(String value) {
    _prefs.setString(_keyReadingMode, value);
    notifyListeners();
  }

  bool get pageTurnAnimation => _prefs.getBool(_keyPageTurnAnimation) ?? true;

  set pageTurnAnimation(bool value) {
    _prefs.setBool(_keyPageTurnAnimation, value);
    notifyListeners();
  }

  /// Highlight color: 'yellow', 'green', 'blue', 'pink', or 'orange'.
  String get defaultHighlightColor =>
      _prefs.getString(_keyDefaultHighlightColor) ?? 'yellow';

  set defaultHighlightColor(String value) {
    _prefs.setString(_keyDefaultHighlightColor, value);
    notifyListeners();
  }

  // -- Library --------------------------------------------------------------

  /// Library view mode: 'grid', 'list', or 'compact'.
  String get defaultViewMode => _prefs.getString(_keyDefaultViewMode) ?? 'grid';

  set defaultViewMode(String value) {
    _prefs.setString(_keyDefaultViewMode, value);
    notifyListeners();
  }

  /// Sort order: 'title', 'author', 'date_added', 'last_read', or 'rating'.
  String get defaultSortOrder =>
      _prefs.getString(_keyDefaultSortOrder) ?? 'date_added';

  set defaultSortOrder(String value) {
    _prefs.setString(_keyDefaultSortOrder, value);
    notifyListeners();
  }

  /// Metadata source: 'Open Library' or 'Google Books'.
  String get metadataSource =>
      _prefs.getString(_keyMetadataSource) ?? 'Open Library';

  set metadataSource(String value) {
    _prefs.setString(_keyMetadataSource, value);
    notifyListeners();
  }

  /// Annotation export format: 'Markdown', 'PDF', 'TXT', or 'HTML'.
  String get annotationExportFormat =>
      _prefs.getString(_keyAnnotationExportFormat) ?? 'Markdown';

  set annotationExportFormat(String value) {
    _prefs.setString(_keyAnnotationExportFormat, value);
    notifyListeners();
  }

  // -- Notifications --------------------------------------------------------

  bool get goalReminders => _prefs.getBool(_keyGoalReminders) ?? true;

  set goalReminders(bool value) {
    _prefs.setBool(_keyGoalReminders, value);
    notifyListeners();
  }

  bool get streakAlerts => _prefs.getBool(_keyStreakAlerts) ?? true;

  set streakAlerts(bool value) {
    _prefs.setBool(_keyStreakAlerts, value);
    notifyListeners();
  }

  bool get syncStatusNotifications =>
      _prefs.getBool(_keySyncStatusNotifications) ?? false;

  set syncStatusNotifications(bool value) {
    _prefs.setBool(_keySyncStatusNotifications, value);
    notifyListeners();
  }

  // -- Storage & sync -------------------------------------------------------

  String get storageBackend => _prefs.getString(_keyStorageBackend) ?? 'Local';

  set storageBackend(String value) {
    _prefs.setString(_keyStorageBackend, value);
    notifyListeners();
  }

  bool get syncEnabled => _prefs.getBool(_keySyncEnabled) ?? false;

  set syncEnabled(bool value) {
    _prefs.setBool(_keySyncEnabled, value);
    notifyListeners();
  }

  String get serverUrl => _prefs.getString(_keyServerUrl) ?? '';

  set serverUrl(String value) {
    _prefs.setString(_keyServerUrl, value);
    notifyListeners();
  }

  /// Server type: 'official' or 'self-hosted'.
  String get serverType => _prefs.getString(_keyServerType) ?? 'official';

  set serverType(String value) {
    _prefs.setString(_keyServerType, value);
    notifyListeners();
  }

  /// Sync interval: 'realtime', '1min', '5min', or 'manual'.
  String get syncInterval => _prefs.getString(_keySyncInterval) ?? '5min';

  set syncInterval(String value) {
    _prefs.setString(_keySyncInterval, value);
    notifyListeners();
  }

  /// Conflict resolution: 'server', 'client', or 'ask'.
  String get conflictResolution =>
      _prefs.getString(_keyConflictResolution) ?? 'server';

  set conflictResolution(String value) {
    _prefs.setString(_keyConflictResolution, value);
    notifyListeners();
  }

  // -- Privacy --------------------------------------------------------------

  bool get analyticsOptIn => _prefs.getBool(_keyAnalyticsOptIn) ?? false;

  set analyticsOptIn(bool value) {
    _prefs.setBool(_keyAnalyticsOptIn, value);
    notifyListeners();
  }

  // -- Accessibility --------------------------------------------------------

  bool get reduceAnimations => _prefs.getBool(_keyReduceAnimations) ?? false;

  set reduceAnimations(bool value) {
    _prefs.setBool(_keyReduceAnimations, value);
    notifyListeners();
  }

  bool get dyslexiaFont => _prefs.getBool(_keyDyslexiaFont) ?? false;

  set dyslexiaFont(bool value) {
    _prefs.setBool(_keyDyslexiaFont, value);
    notifyListeners();
  }
}
