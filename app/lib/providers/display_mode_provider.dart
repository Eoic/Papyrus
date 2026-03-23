import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_theme.dart';

/// Provider for managing the application's display mode.
/// Allows switching between standard and e-ink display modes at runtime.
class DisplayModeProvider extends ChangeNotifier {
  DisplayMode _displayMode = DisplayMode.standard;

  /// Current display mode
  DisplayMode get displayMode => _displayMode;

  /// Whether e-ink mode is active
  bool get isEinkMode => _displayMode == DisplayMode.eink;

  /// Whether standard mode is active
  bool get isStandardMode => _displayMode == DisplayMode.standard;

  /// Set the display mode
  void setDisplayMode(DisplayMode mode) {
    if (_displayMode != mode) {
      _displayMode = mode;
      notifyListeners();
    }
  }

  /// Toggle between standard and e-ink modes
  void toggleEinkMode() {
    setDisplayMode(isEinkMode ? DisplayMode.standard : DisplayMode.eink);
  }

  /// Get the appropriate theme for the current display mode and brightness
  ThemeData getTheme(Brightness brightness) {
    if (isEinkMode) {
      return AppTheme.eink;
    }
    return brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  }
}
