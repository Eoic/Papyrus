/// Represents an active filter for UI display.
/// Used by the Active Filter Bar to show removable filter chips.
class ActiveFilter {
  /// Type of filter (quick or query-based)
  final ActiveFilterType type;

  /// Display label for the filter
  final String label;

  /// The filter value
  final String value;

  /// The query string representation (for query-based filters)
  final String? queryString;

  /// Icon to display with the filter
  final String? iconName;

  const ActiveFilter({
    required this.type,
    required this.label,
    required this.value,
    this.queryString,
    this.iconName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveFilter &&
        other.type == type &&
        other.label == label &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(type, label, value);

  @override
  String toString() {
    if (type == ActiveFilterType.quick) {
      return label;
    }
    return queryString ?? '$label:$value';
  }
}

/// Type of active filter.
enum ActiveFilterType {
  /// Quick filter (Reading, Favorites, etc.)
  quick,

  /// Query-based filter (author:, format:, etc.)
  query,
}
