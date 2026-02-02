import 'package:papyrus/models/book.dart';

/// Represents a search filter condition.
class SearchFilter {
  final SearchField field;
  final SearchOperator operator;
  final String value;

  const SearchFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// Check if a book matches this filter.
  bool matches(BookData book) {
    final fieldValue = _getFieldValue(book);
    if (fieldValue == null) return false;

    switch (operator) {
      case SearchOperator.equals:
        return fieldValue.toLowerCase() == value.toLowerCase();
      case SearchOperator.contains:
        return fieldValue.toLowerCase().contains(value.toLowerCase());
      case SearchOperator.greaterThan:
        final numValue = double.tryParse(value);
        final numField = double.tryParse(fieldValue);
        if (numValue == null || numField == null) return false;
        return numField > numValue;
      case SearchOperator.lessThan:
        final numValue = double.tryParse(value);
        final numField = double.tryParse(fieldValue);
        if (numValue == null || numField == null) return false;
        return numField < numValue;
      case SearchOperator.notEquals:
        return fieldValue.toLowerCase() != value.toLowerCase();
    }
  }

  String? _getFieldValue(BookData book) {
    switch (field) {
      case SearchField.title:
        return book.title;
      case SearchField.author:
        return book.author;
      case SearchField.format:
        return book.formatLabel.toLowerCase();
      case SearchField.shelf:
        return book.shelves.join(',');
      case SearchField.topic:
        return book.topics.join(',');
      case SearchField.status:
        if (book.isFinished) return 'finished';
        if (book.isReading) return 'reading';
        if (book.progress == 0) return 'unread';
        return 'reading';
      case SearchField.progress:
        return (book.progress * 100).round().toString();
      case SearchField.any:
        // For 'any' field, we combine title and author
        return '${book.title} ${book.author}';
    }
  }

  @override
  String toString() {
    if (field == SearchField.any) {
      return value;
    }
    final fieldName = field.name;
    switch (operator) {
      case SearchOperator.equals:
      case SearchOperator.contains:
        return '$fieldName:$value';
      case SearchOperator.greaterThan:
        return '$fieldName:>$value';
      case SearchOperator.lessThan:
        return '$fieldName:<$value';
      case SearchOperator.notEquals:
        return '-$fieldName:$value';
    }
  }
}

/// Searchable fields in the library.
enum SearchField {
  any,
  title,
  author,
  format,
  shelf,
  topic,
  status,
  progress,
}

/// Search operators for filter conditions.
enum SearchOperator {
  equals,
  contains,
  greaterThan,
  lessThan,
  notEquals,
}

/// Logical operators for combining filters.
enum LogicalOperator {
  and,
  or,
}

/// A composite search query with multiple filters.
class SearchQuery {
  final List<SearchFilter> filters;
  final List<LogicalOperator> operators;
  final List<SearchFilter> notFilters;

  const SearchQuery({
    this.filters = const [],
    this.operators = const [],
    this.notFilters = const [],
  });

  /// Check if a book matches this query.
  bool matches(BookData book) {
    // Check NOT filters first - if any match, exclude the book
    for (final filter in notFilters) {
      if (filter.matches(book)) {
        return false;
      }
    }

    if (filters.isEmpty) return true;

    bool result = filters[0].matches(book);

    for (int i = 1; i < filters.length; i++) {
      final filterResult = filters[i].matches(book);
      final op = i - 1 < operators.length ? operators[i - 1] : LogicalOperator.and;

      if (op == LogicalOperator.and) {
        result = result && filterResult;
      } else {
        result = result || filterResult;
      }
    }

    return result;
  }

  /// Convert query back to string representation.
  String toQueryString() {
    final parts = <String>[];

    for (final filter in notFilters) {
      parts.add('NOT ${filter.toString()}');
    }

    for (int i = 0; i < filters.length; i++) {
      if (i > 0 && i - 1 < operators.length) {
        parts.add(operators[i - 1] == LogicalOperator.or ? 'OR' : 'AND');
      }
      parts.add(filters[i].toString());
    }

    return parts.join(' ');
  }

  /// Check if query is empty.
  bool get isEmpty => filters.isEmpty && notFilters.isEmpty;

  /// Check if query has any filters.
  bool get isNotEmpty => filters.isNotEmpty || notFilters.isNotEmpty;
}
