import 'package:flutter/foundation.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';

enum FavoriteFilter { any, favorites, notFavorites }

@immutable
class LibraryProgressRange {
  final double start;
  final double end;

  const LibraryProgressRange(this.start, this.end) : assert(start >= 0), assert(end <= 1), assert(start <= end);

  bool contains(double progress) => progress >= start && progress <= end;

  @override
  bool operator ==(Object other) {
    return other is LibraryProgressRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class LibraryDateRange {
  final DateTime start;
  final DateTime end;

  LibraryDateRange(DateTime start, DateTime end)
    : start = _dateOnly(start),
      end = _dateOnly(end),
      assert(!_dateOnly(end).isBefore(_dateOnly(start)));

  bool contains(DateTime? value) {
    if (value == null) {
      return false;
    }

    final date = _dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static DateTime _dateOnly(DateTime value) {
    final localValue = value.toLocal();
    return DateTime(localValue.year, localValue.month, localValue.day);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryDateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class LibraryFilters {
  static const _notProvided = Object();

  final Set<String> authors;
  final Set<String> languages;
  final Set<String> formats;
  final Set<String> topicIds;
  final Set<String> shelfIds;
  final Set<String> publishers;
  final Set<String> seriesNames;
  final Set<LibraryReadingStatus> statuses;
  final FavoriteFilter favoriteFilter;
  final LibraryProgressRange? progressRange;
  final Set<int> ratings;
  final bool includeUnrated;
  final LibraryDateRange? publicationDateRange;
  final LibraryDateRange? dateAddedRange;
  final LibraryDateRange? lastReadDateRange;

  LibraryFilters({
    Set<String> authors = const {},
    Set<String> languages = const {},
    Set<String> formats = const {},
    Set<String> topicIds = const {},
    Set<String> shelfIds = const {},
    Set<String> publishers = const {},
    Set<String> seriesNames = const {},
    Set<LibraryReadingStatus> statuses = const {},
    this.favoriteFilter = FavoriteFilter.any,
    this.progressRange,
    Set<int> ratings = const {},
    this.includeUnrated = false,
    this.publicationDateRange,
    this.dateAddedRange,
    this.lastReadDateRange,
  }) : authors = Set.unmodifiable(authors),
       languages = Set.unmodifiable(languages),
       formats = Set.unmodifiable(formats),
       topicIds = Set.unmodifiable(topicIds),
       shelfIds = Set.unmodifiable(shelfIds),
       publishers = Set.unmodifiable(publishers),
       seriesNames = Set.unmodifiable(seriesNames),
       statuses = Set.unmodifiable(statuses),
       ratings = Set.unmodifiable(ratings);

  int get activeCategoryCount {
    var count = 0;
    if (authors.isNotEmpty) count++;
    if (languages.isNotEmpty) count++;
    if (formats.isNotEmpty) count++;
    if (topicIds.isNotEmpty) count++;
    if (shelfIds.isNotEmpty) count++;
    if (publishers.isNotEmpty) count++;
    if (seriesNames.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (favoriteFilter != FavoriteFilter.any) count++;
    if (progressRange != null) count++;
    if (ratings.isNotEmpty || includeUnrated) count++;
    if (publicationDateRange != null) count++;
    if (dateAddedRange != null) count++;
    if (lastReadDateRange != null) count++;
    return count;
  }

  bool get isEmpty => activeCategoryCount == 0;

  LibraryFilters copyWith({
    Set<String>? authors,
    Set<String>? languages,
    Set<String>? formats,
    Set<String>? topicIds,
    Set<String>? shelfIds,
    Set<String>? publishers,
    Set<String>? seriesNames,
    Set<LibraryReadingStatus>? statuses,
    FavoriteFilter? favoriteFilter,
    Object? progressRange = _notProvided,
    Set<int>? ratings,
    bool? includeUnrated,
    Object? publicationDateRange = _notProvided,
    Object? dateAddedRange = _notProvided,
    Object? lastReadDateRange = _notProvided,
  }) {
    return LibraryFilters(
      authors: authors ?? this.authors,
      languages: languages ?? this.languages,
      formats: formats ?? this.formats,
      topicIds: topicIds ?? this.topicIds,
      shelfIds: shelfIds ?? this.shelfIds,
      publishers: publishers ?? this.publishers,
      seriesNames: seriesNames ?? this.seriesNames,
      statuses: statuses ?? this.statuses,
      favoriteFilter: favoriteFilter ?? this.favoriteFilter,
      progressRange: identical(progressRange, _notProvided)
          ? this.progressRange
          : progressRange as LibraryProgressRange?,
      ratings: ratings ?? this.ratings,
      includeUnrated: includeUnrated ?? this.includeUnrated,
      publicationDateRange: identical(publicationDateRange, _notProvided)
          ? this.publicationDateRange
          : publicationDateRange as LibraryDateRange?,
      dateAddedRange: identical(dateAddedRange, _notProvided)
          ? this.dateAddedRange
          : dateAddedRange as LibraryDateRange?,
      lastReadDateRange: identical(lastReadDateRange, _notProvided)
          ? this.lastReadDateRange
          : lastReadDateRange as LibraryDateRange?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryFilters &&
        setEquals(other.authors, authors) &&
        setEquals(other.languages, languages) &&
        setEquals(other.formats, formats) &&
        setEquals(other.topicIds, topicIds) &&
        setEquals(other.shelfIds, shelfIds) &&
        setEquals(other.publishers, publishers) &&
        setEquals(other.seriesNames, seriesNames) &&
        setEquals(other.statuses, statuses) &&
        other.favoriteFilter == favoriteFilter &&
        other.progressRange == progressRange &&
        setEquals(other.ratings, ratings) &&
        other.includeUnrated == includeUnrated &&
        other.publicationDateRange == publicationDateRange &&
        other.dateAddedRange == dateAddedRange &&
        other.lastReadDateRange == lastReadDateRange;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(authors),
    Object.hashAllUnordered(languages),
    Object.hashAllUnordered(formats),
    Object.hashAllUnordered(topicIds),
    Object.hashAllUnordered(shelfIds),
    Object.hashAllUnordered(publishers),
    Object.hashAllUnordered(seriesNames),
    Object.hashAllUnordered(statuses),
    favoriteFilter,
    progressRange,
    Object.hashAllUnordered(ratings),
    includeUnrated,
    publicationDateRange,
    dateAddedRange,
    lastReadDateRange,
  );
}
