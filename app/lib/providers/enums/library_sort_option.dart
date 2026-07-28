enum LibrarySortOption {
  dateAddedNewest,
  dateAddedOldest,
  titleAZ,
  titleZA,
  authorAZ,
  authorZA,
  lastRead,
  progressAsc,
  progressDesc,
  ratingAsc,
  ratingDesc,
}

extension LibrarySortOptionExtension on LibrarySortOption {
  String get label {
    switch (this) {
      case LibrarySortOption.dateAddedNewest:
        return 'Date added (newest)';
      case LibrarySortOption.dateAddedOldest:
        return 'Date added (oldest)';
      case LibrarySortOption.titleAZ:
        return 'Title (A-Z)';
      case LibrarySortOption.titleZA:
        return 'Title (Z-A)';
      case LibrarySortOption.authorAZ:
        return 'Author (A-Z)';
      case LibrarySortOption.authorZA:
        return 'Author (Z-A)';
      case LibrarySortOption.lastRead:
        return 'Last read';
      case LibrarySortOption.progressAsc:
        return 'Progress (Ascending)';
      case LibrarySortOption.progressDesc:
        return 'Progress (Descending)';
      case LibrarySortOption.ratingAsc:
        return 'Rating (Ascending)';
      case LibrarySortOption.ratingDesc:
        return 'Rating (Descending)';
    }
  }
}
