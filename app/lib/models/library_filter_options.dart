import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/utils/book_language.dart';

class LibraryFilterOption<T> {
  final T value;
  final String label;

  const LibraryFilterOption({required this.value, required this.label});
}

class LibraryFilterOptions {
  final List<LibraryFilterOption<String>> authors;
  final List<LibraryFilterOption<String>> languages;
  final List<LibraryFilterOption<String>> formats;
  final List<LibraryFilterOption<String>> topics;
  final List<LibraryFilterOption<String>> shelves;
  final List<LibraryFilterOption<String>> publishers;
  final List<LibraryFilterOption<String>> series;
  final List<LibraryFilterOption<LibraryReadingStatus>> readingStatuses;
  final List<int> ratings;
  final bool hasUnrated;

  const LibraryFilterOptions({
    required this.authors,
    required this.languages,
    required this.formats,
    required this.topics,
    required this.shelves,
    required this.publishers,
    required this.series,
    required this.readingStatuses,
    required this.ratings,
    required this.hasUnrated,
  });

  factory LibraryFilterOptions.fromDataStore(DataStore dataStore, {Iterable<Book>? books}) {
    final isScoped = books != null;
    final sourceBooks = books ?? dataStore.books;
    final authors = <String, String>{};
    final languages = <String, String>{};
    final formats = <String, String>{};
    final publishers = <String, String>{};
    final series = <String, String>{};
    final sourceBookIds = <String>{};
    final topicIds = <String>{};
    final shelfIds = <String>{};
    final readingStatuses = <LibraryReadingStatus>{};
    final ratings = <int>{};
    var hasUnrated = false;

    for (final book in sourceBooks) {
      sourceBookIds.add(book.id);
      for (final author in [book.author, ...book.coAuthors]) {
        _addNormalized(authors, author);
      }

      final language = book.language;
      final normalizedLanguage = normalizeBookLanguage(language);
      if (language != null && normalizedLanguage != null) {
        languages.putIfAbsent(normalizedLanguage, () => bookLanguageLabel(language));
      }

      _addNormalized(formats, book.formatLabel);
      _addNormalized(publishers, book.publisher);
      _addNormalized(series, book.seriesName);
      readingStatuses.add(book.readingStatus);

      final rating = book.rating;
      if (rating == null) {
        hasUnrated = true;
      } else {
        ratings.add(rating);
      }
    }

    for (final relation in dataStore.bookTagRelations) {
      if (sourceBookIds.contains(relation.bookId)) {
        topicIds.add(relation.tagId);
      }
    }

    for (final relation in dataStore.bookShelfRelations) {
      if (sourceBookIds.contains(relation.bookId)) {
        shelfIds.add(relation.shelfId);
      }
    }

    return LibraryFilterOptions(
      authors: _stringOptions(authors),
      languages: _stringOptions(languages),
      formats: _stringOptions(formats),
      topics: _sortedOptions(
        dataStore.tags
            .where((topic) => topicIds.contains(topic.id))
            .map((topic) => LibraryFilterOption(value: topic.id, label: topic.name)),
      ),
      shelves: _sortedOptions(
        dataStore.shelves
            .where((shelf) => shelfIds.contains(shelf.id))
            .map((shelf) => LibraryFilterOption(value: shelf.id, label: shelf.name)),
      ),
      publishers: _stringOptions(publishers),
      series: _stringOptions(series),
      readingStatuses: [
        for (final status in LibraryReadingStatus.values)
          if (!isScoped || readingStatuses.contains(status)) LibraryFilterOption(value: status, label: status.label),
      ],
      ratings: isScoped ? (ratings.toList()..sort()) : const [1, 2, 3, 4, 5],
      hasUnrated: isScoped ? hasUnrated : true,
    );
  }

  static void _addNormalized(Map<String, String> labelsByValue, String? value) {
    final label = value?.trim();
    if (label == null || label.isEmpty) {
      return;
    }

    labelsByValue.putIfAbsent(label.toLowerCase(), () => label);
  }

  static List<LibraryFilterOption<String>> _stringOptions(Map<String, String> labelsByValue) {
    return _sortedOptions(
      labelsByValue.entries.map((entry) => LibraryFilterOption(value: entry.key, label: entry.value)),
    );
  }

  static List<LibraryFilterOption<String>> _sortedOptions(Iterable<LibraryFilterOption<String>> options) {
    return options.toList()..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }
}
