import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/active_filter.dart';

void main() {
  group('ActiveFilter', () {
    group('equality', () {
      test('should be equal when type, label, and value match', () {
        const filter1 = ActiveFilter(
          type: ActiveFilterType.quick,
          label: 'Reading',
          value: 'reading',
        );
        const filter2 = ActiveFilter(
          type: ActiveFilterType.quick,
          label: 'Reading',
          value: 'reading',
        );

        expect(filter1, equals(filter2));
        expect(filter1.hashCode, equals(filter2.hashCode));
      });

      test('should not be equal when type differs', () {
        const filter1 = ActiveFilter(
          type: ActiveFilterType.quick,
          label: 'shelf',
          value: 'Fiction',
        );
        const filter2 = ActiveFilter(
          type: ActiveFilterType.query,
          label: 'shelf',
          value: 'Fiction',
        );

        expect(filter1, isNot(equals(filter2)));
      });

      test('should not be equal when label differs', () {
        const filter1 = ActiveFilter(
          type: ActiveFilterType.quick,
          label: 'Reading',
          value: 'reading',
        );
        const filter2 = ActiveFilter(
          type: ActiveFilterType.quick,
          label: 'Finished',
          value: 'reading',
        );

        expect(filter1, isNot(equals(filter2)));
      });

      test('should not be equal when value differs', () {
        const filter1 = ActiveFilter(
          type: ActiveFilterType.query,
          label: 'shelf',
          value: 'Fiction',
        );
        const filter2 = ActiveFilter(
          type: ActiveFilterType.query,
          label: 'shelf',
          value: 'Non-Fiction',
        );

        expect(filter1, isNot(equals(filter2)));
      });
    });

    group('toString', () {
      test('should return label for quick filters', () {
        const filter = ActiveFilter(
          type: ActiveFilterType.quick,
          label: 'Reading',
          value: 'reading',
        );

        expect(filter.toString(), 'Reading');
      });

      test('should return queryString for query filters when provided', () {
        const filter = ActiveFilter(
          type: ActiveFilterType.query,
          label: 'author',
          value: 'Tolkien',
          queryString: 'author:"Tolkien"',
        );

        expect(filter.toString(), 'author:"Tolkien"');
      });

      test(
        'should return label:value for query filters without queryString',
        () {
          const filter = ActiveFilter(
            type: ActiveFilterType.query,
            label: 'author',
            value: 'Tolkien',
          );

          expect(filter.toString(), 'author:Tolkien');
        },
      );
    });
  });

  group('ActiveFilterType', () {
    test('should have quick and query types', () {
      expect(ActiveFilterType.values, contains(ActiveFilterType.quick));
      expect(ActiveFilterType.values, contains(ActiveFilterType.query));
      expect(ActiveFilterType.values.length, 2);
    });
  });
}
