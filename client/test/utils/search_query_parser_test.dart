import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/search_filter.dart';
import 'package:papyrus/utils/search_query_parser.dart';

void main() {
  group('SearchQueryParser', () {
    group('parse simple queries', () {
      test('should return empty query for empty input', () {
        final result = SearchQueryParser.parse('');
        expect(result.isEmpty, true);
      });

      test('should return empty query for whitespace input', () {
        final result = SearchQueryParser.parse('   ');
        expect(result.isEmpty, true);
      });

      test('should parse simple text as "any" field search', () {
        final result = SearchQueryParser.parse('tolkien');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.any);
        expect(result.filters[0].value, 'tolkien');
      });
    });

    group('parse field:value queries', () {
      test('should parse author field', () {
        final result = SearchQueryParser.parse('author:tolkien');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.author);
        expect(result.filters[0].value, 'tolkien');
      });

      test('should parse format field', () {
        final result = SearchQueryParser.parse('format:epub');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.format);
        expect(result.filters[0].value, 'epub');
      });

      test('should parse shelf field', () {
        final result = SearchQueryParser.parse('shelf:Fiction');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.shelf);
        expect(result.filters[0].value, 'Fiction');
      });

      test('should parse topic field', () {
        final result = SearchQueryParser.parse('topic:Science');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.topic);
        expect(result.filters[0].value, 'Science');
      });

      test('should parse status field', () {
        final result = SearchQueryParser.parse('status:reading');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.status);
        expect(result.filters[0].value, 'reading');
      });

      test('should parse progress field', () {
        final result = SearchQueryParser.parse('progress:50');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.progress);
        expect(result.filters[0].value, '50');
      });
    });

    group('parse quoted values', () {
      test('should parse quoted phrase', () {
        final result = SearchQueryParser.parse('author:"J.R.R. Tolkien"');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.author);
        expect(result.filters[0].value, 'J.R.R. Tolkien');
      });

      test('should preserve spaces in quoted values', () {
        final result = SearchQueryParser.parse('shelf:"Science Fiction"');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.shelf);
        expect(result.filters[0].value, 'Science Fiction');
      });
    });

    group('parse comparison operators', () {
      test('should parse greater than operator', () {
        final result = SearchQueryParser.parse('progress:>50');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.progress);
        expect(result.filters[0].operator, SearchOperator.greaterThan);
        expect(result.filters[0].value, '50');
      });

      test('should parse less than operator', () {
        final result = SearchQueryParser.parse('progress:<75');

        expect(result.filters.length, 1);
        expect(result.filters[0].field, SearchField.progress);
        expect(result.filters[0].operator, SearchOperator.lessThan);
        expect(result.filters[0].value, '75');
      });
    });

    group('parse multiple filters', () {
      test('should parse multiple filters with implicit AND', () {
        final result = SearchQueryParser.parse('author:tolkien format:epub');

        expect(result.filters.length, 2);
        expect(result.filters[0].field, SearchField.author);
        expect(result.filters[0].value, 'tolkien');
        expect(result.filters[1].field, SearchField.format);
        expect(result.filters[1].value, 'epub');
        expect(result.operators.length, 1);
        expect(result.operators[0], LogicalOperator.and);
      });

      test('should parse explicit AND operator', () {
        final result = SearchQueryParser.parse('author:tolkien AND format:epub');

        expect(result.filters.length, 2);
        expect(result.operators.length, 1);
        expect(result.operators[0], LogicalOperator.and);
      });

      test('should parse OR operator', () {
        final result = SearchQueryParser.parse('author:tolkien OR author:lewis');

        expect(result.filters.length, 2);
        expect(result.operators.length, 1);
        expect(result.operators[0], LogicalOperator.or);
      });
    });

    group('parse NOT operator', () {
      test('should parse NOT operator', () {
        final result = SearchQueryParser.parse('NOT status:finished');

        expect(result.filters.length, 0);
        expect(result.notFilters.length, 1);
        expect(result.notFilters[0].field, SearchField.status);
        expect(result.notFilters[0].value, 'finished');
      });

      test('should parse negation prefix', () {
        final result = SearchQueryParser.parse('-status:finished');

        expect(result.filters.length, 1);
        expect(result.filters[0].operator, SearchOperator.notEquals);
        expect(result.filters[0].value, 'finished');
      });
    });

    group('field suggestions', () {
      test('should provide field suggestions', () {
        expect(SearchQueryParser.fieldSuggestions, contains('author:'));
        expect(SearchQueryParser.fieldSuggestions, contains('format:'));
        expect(SearchQueryParser.fieldSuggestions, contains('shelf:'));
        expect(SearchQueryParser.fieldSuggestions, contains('topic:'));
        expect(SearchQueryParser.fieldSuggestions, contains('status:'));
        expect(SearchQueryParser.fieldSuggestions, contains('progress:'));
      });

      test('should provide status suggestions', () {
        expect(SearchQueryParser.statusSuggestions, contains('status:reading'));
        expect(SearchQueryParser.statusSuggestions, contains('status:finished'));
        expect(SearchQueryParser.statusSuggestions, contains('status:unread'));
      });

      test('should provide format suggestions', () {
        expect(SearchQueryParser.formatSuggestions, contains('format:epub'));
        expect(SearchQueryParser.formatSuggestions, contains('format:pdf'));
      });
    });
  });

  group('SearchQuery', () {
    test('isEmpty should be true for empty query', () {
      const query = SearchQuery();
      expect(query.isEmpty, true);
      expect(query.isNotEmpty, false);
    });

    test('isNotEmpty should be true when filters exist', () {
      const query = SearchQuery(
        filters: [
          SearchFilter(
            field: SearchField.author,
            operator: SearchOperator.contains,
            value: 'tolkien',
          ),
        ],
      );
      expect(query.isEmpty, false);
      expect(query.isNotEmpty, true);
    });

    test('isNotEmpty should be true when notFilters exist', () {
      const query = SearchQuery(
        notFilters: [
          SearchFilter(
            field: SearchField.status,
            operator: SearchOperator.equals,
            value: 'finished',
          ),
        ],
      );
      expect(query.isEmpty, false);
      expect(query.isNotEmpty, true);
    });
  });
}
