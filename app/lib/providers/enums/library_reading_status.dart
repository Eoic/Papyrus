import 'package:flutter/material.dart';

enum LibraryReadingStatus { unread, inProgress, completed, paused, abandoned }

extension LibraryReadingStatusExtension on LibraryReadingStatus {
  String get label {
    switch (this) {
      case LibraryReadingStatus.unread:
        return 'Not started';
      case LibraryReadingStatus.inProgress:
        return 'Reading';
      case LibraryReadingStatus.completed:
        return 'Completed';
      case LibraryReadingStatus.paused:
        return 'Paused';
      case LibraryReadingStatus.abandoned:
        return 'Abandoned';
    }
  }

  IconData get icon {
    switch (this) {
      case LibraryReadingStatus.unread:
        return Icons.book_outlined;
      case LibraryReadingStatus.inProgress:
        return Icons.auto_stories_outlined;
      case LibraryReadingStatus.completed:
        return Icons.check_circle_outline;
      case LibraryReadingStatus.paused:
        return Icons.pause_circle_outline;
      case LibraryReadingStatus.abandoned:
        return Icons.cancel_outlined;
    }
  }
}
