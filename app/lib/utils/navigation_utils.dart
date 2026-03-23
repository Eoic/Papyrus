import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';

/// Check if a navigation item is selected based on the current path.
///
/// Returns true if:
/// - The current path exactly matches the item path
/// - The current path starts with the item path (and item path is not '/')
/// - Any child of the item has a path that the current path starts with
bool isNavItemSelected(String currentPath, AppShellNavItem item) {
  if (currentPath == item.path) return true;
  if (currentPath.startsWith(item.path) && item.path != '/') return true;
  if (item.children != null) {
    return item.children!.any((child) => currentPath.startsWith(child.path));
  }
  return false;
}

/// Check if a path is a child path (has more than one segment).
///
/// For example:
/// - '/library' returns false (single segment)
/// - '/library/books' returns true (two segments)
bool isChildPath(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  return segments.length > 1;
}
