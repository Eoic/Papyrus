import 'package:papyrus/models/search_filter.dart';

/// Parser for search query language.
///
/// Supports:
/// - Simple text: `tolkien` (searches title and author)
/// - Field-specific: `author:tolkien`, `format:epub`
/// - Quoted phrases: `author:"J.R.R. Tolkien"`
/// - Comparisons: `progress:>50`, `progress:<100`
/// - Boolean operators: `AND`, `OR`, `NOT`
/// - Multiple filters: `author:tolkien format:epub` (implicit AND)
class SearchQueryParser {
  /// Parse a query string into a SearchQuery.
  static SearchQuery parse(String input) {
    if (input.trim().isEmpty) {
      return const SearchQuery();
    }

    final tokens = _tokenize(input);
    return _parseTokens(tokens);
  }

  /// Tokenize the input string.
  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (char == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  /// Parse tokens into a SearchQuery.
  static SearchQuery _parseTokens(List<String> tokens) {
    final filters = <SearchFilter>[];
    final notFilters = <SearchFilter>[];
    final operators = <LogicalOperator>[];
    LogicalOperator? pendingOperator;
    bool pendingNot = false;

    for (final token in tokens) {
      final upperToken = token.toUpperCase();

      // Check for logical operators
      if (upperToken == 'AND') {
        pendingOperator = LogicalOperator.and;
        continue;
      }
      if (upperToken == 'OR') {
        pendingOperator = LogicalOperator.or;
        continue;
      }
      if (upperToken == 'NOT') {
        pendingNot = true;
        continue;
      }

      // Parse the filter
      final filter = _parseFilter(token);

      if (pendingNot) {
        notFilters.add(filter);
        pendingNot = false;
      } else {
        if (filters.isNotEmpty) {
          operators.add(pendingOperator ?? LogicalOperator.and);
        }
        filters.add(filter);
      }
      pendingOperator = null;
    }

    return SearchQuery(
      filters: filters,
      operators: operators,
      notFilters: notFilters,
    );
  }

  /// Parse a single filter token.
  static SearchFilter _parseFilter(String token) {
    // Check for negation prefix
    if (token.startsWith('-') && token.length > 1) {
      final inner = _parseFilter(token.substring(1));
      return SearchFilter(
        field: inner.field,
        operator: SearchOperator.notEquals,
        value: inner.value,
      );
    }

    // Check for field:value pattern
    final colonIndex = token.indexOf(':');
    if (colonIndex > 0) {
      final fieldName = token.substring(0, colonIndex).toLowerCase();
      var value = token.substring(colonIndex + 1);

      // Remove quotes from value
      if (value.startsWith('"') && value.endsWith('"') && value.length > 1) {
        value = value.substring(1, value.length - 1);
      }

      // Check for comparison operators
      SearchOperator operator = SearchOperator.contains;
      if (value.startsWith('>')) {
        operator = SearchOperator.greaterThan;
        value = value.substring(1);
      } else if (value.startsWith('<')) {
        operator = SearchOperator.lessThan;
        value = value.substring(1);
      }

      final field = _parseField(fieldName);

      return SearchFilter(
        field: field,
        operator: operator,
        value: value,
      );
    }

    // Simple text search - search title and author
    var value = token;
    if (value.startsWith('"') && value.endsWith('"') && value.length > 1) {
      value = value.substring(1, value.length - 1);
    }

    return SearchFilter(
      field: SearchField.any,
      operator: SearchOperator.contains,
      value: value,
    );
  }

  /// Parse field name string to SearchField enum.
  static SearchField _parseField(String name) {
    switch (name) {
      case 'title':
        return SearchField.title;
      case 'author':
        return SearchField.author;
      case 'format':
        return SearchField.format;
      case 'shelf':
        return SearchField.shelf;
      case 'topic':
        return SearchField.topic;
      case 'status':
        return SearchField.status;
      case 'progress':
        return SearchField.progress;
      default:
        return SearchField.any;
    }
  }

  /// Get suggestions for field names.
  static List<String> get fieldSuggestions => [
        'title:',
        'author:',
        'format:',
        'shelf:',
        'topic:',
        'status:',
        'progress:',
      ];

  /// Get suggestions for status values.
  static List<String> get statusSuggestions => [
        'status:reading',
        'status:finished',
        'status:unread',
      ];

  /// Get suggestions for format values.
  static List<String> get formatSuggestions => [
        'format:epub',
        'format:pdf',
        'format:mobi',
        'format:physical',
        'format:txt',
      ];
}
