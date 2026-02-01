import 'package:flutter/foundation.dart';

/// Provider for managing sidebar state on desktop platforms.
class SidebarProvider extends ChangeNotifier {
  bool _isCollapsed = false;
  bool _isLibraryExpanded = true;

  /// Whether the sidebar is in collapsed (icon-only) mode.
  bool get isCollapsed => _isCollapsed;

  /// Whether the library sub-menu is expanded.
  bool get isLibraryExpanded => _isLibraryExpanded;

  /// Current sidebar width based on collapse state.
  double get sidebarWidth => _isCollapsed ? 72.0 : 280.0;

  /// Toggle sidebar collapse state.
  void toggleCollapsed() {
    _isCollapsed = !_isCollapsed;
    // When collapsing, also collapse library submenu
    if (_isCollapsed) {
      _isLibraryExpanded = false;
    }
    notifyListeners();
  }

  /// Set collapsed state directly.
  void setCollapsed(bool collapsed) {
    if (_isCollapsed != collapsed) {
      _isCollapsed = collapsed;
      if (_isCollapsed) {
        _isLibraryExpanded = false;
      }
      notifyListeners();
    }
  }

  /// Toggle library sub-menu expansion.
  void toggleLibraryExpanded() {
    // Can only expand library when sidebar is not collapsed
    if (!_isCollapsed) {
      _isLibraryExpanded = !_isLibraryExpanded;
      notifyListeners();
    }
  }

  /// Set library expanded state directly.
  void setLibraryExpanded(bool expanded) {
    if (_isLibraryExpanded != expanded && !_isCollapsed) {
      _isLibraryExpanded = expanded;
      notifyListeners();
    }
  }
}
