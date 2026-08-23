class BookMetadataSyncState {
  final Set<String> pendingBookIds;
  final Set<String> failedBookIds;

  const BookMetadataSyncState({this.pendingBookIds = const {}, this.failedBookIds = const {}});

  bool isPending(String bookId) => pendingBookIds.contains(bookId);

  bool hasFailed(String bookId) => failedBookIds.contains(bookId);
}
