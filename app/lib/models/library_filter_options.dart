import 'package:papyrus/data/data_store.dart';
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

  const LibraryFilterOptions({
    required this.authors,
    required this.languages,
    required this.formats,
    required this.topics,
    required this.shelves,
    required this.publishers,
    required this.series,
  });

  factory LibraryFilterOptions.fromDataStore(DataStore dataStore) {
    final authors = <String, String>{};
    final languages = <String, String>{};
    final formats = <String, String>{};
    final publishers = <String, String>{};
    final series = <String, String>{};

    for (final book in dataStore.books) {
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
    }

    return LibraryFilterOptions(
      authors: _stringOptions(authors),
      languages: _stringOptions(languages),
      formats: _stringOptions(formats),
      topics: _sortedOptions(dataStore.tags.map((topic) => LibraryFilterOption(value: topic.id, label: topic.name))),
      shelves: _sortedOptions(
        dataStore.shelves.map((shelf) => LibraryFilterOption(value: shelf.id, label: shelf.name)),
      ),
      publishers: _stringOptions(publishers),
      series: _stringOptions(series),
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
