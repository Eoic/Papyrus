import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus_reader/papyrus_reader.dart';

final class ReaderBookAdapter {
  const ReaderBookAdapter._();

  static const locatorMetadataKey = 'reader_locator';

  static ReaderFormat? formatFor(BookFormat? format) {
    return switch (format) {
      BookFormat.epub => ReaderFormat.epub,
      BookFormat.pdf => ReaderFormat.pdf,
      _ => null,
    };
  }

  static ReaderLocator? restoreLocator(Book book) {
    final stored = book.customMetadata?[locatorMetadataKey];
    if (stored is! Map) return null;

    try {
      final locator = ReaderLocator.fromJson(stored.map((key, value) => MapEntry(key.toString(), value)));
      final format = formatFor(book.fileFormat);
      if (format == ReaderFormat.epub && locator is! EpubReaderLocator) {
        return null;
      }
      if (format == ReaderFormat.pdf && locator is! PdfReaderLocator) {
        return null;
      }

      return locator;
    } on FormatException {
      return null;
    }
  }

  static Book applyLocator(Book book, ReaderLocator locator, {required DateTime now}) {
    final metadata = Map<String, dynamic>.from(book.customMetadata ?? const {});
    metadata[locatorMetadataKey] = locator.toJson();

    final position = _totalProgression(locator);
    final page = switch (locator) {
      EpubReaderLocator(:final spineIndex) => spineIndex + 1,
      PdfReaderLocator(:final pageIndex) => pageIndex + 1,
    };
    final cfi = switch (locator) {
      EpubReaderLocator(:final cfi) => cfi,
      PdfReaderLocator() => null,
    };
    final status = position >= 1
        ? LibraryReadingStatus.completed
        : position > 0
        ? LibraryReadingStatus.inProgress
        : book.readingStatus;

    return book.copyWith(
      currentPage: page,
      currentPosition: position,
      currentCfi: cfi,
      readingStatus: status,
      customMetadata: metadata,
      startedAt: book.startedAt ?? (position > 0 ? now : null),
      completedAt: position >= 1 ? now : book.completedAt,
      lastReadAt: now,
    );
  }

  static ReaderPreferences preferencesFor(PreferencesProvider preferences, ColorScheme colors) {
    return ReaderPreferences(
      fontFamily: preferences.defaultFont,
      fontSize: preferences.defaultFontSize,
      lineHeight: switch (preferences.lineSpacing) {
        'compact' => 1.25,
        'relaxed' => 1.75,
        _ => 1.5,
      },
      pageMargins: EdgeInsets.all(switch (preferences.margins) {
        'small' => 16,
        'large' => 40,
        _ => 24,
      }),
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      brightness: colors.brightness,
      layoutMode: preferences.readingMode == 'scroll' ? ReaderLayoutMode.scroll : ReaderLayoutMode.paginated,
    );
  }

  static void persistPreferences(PreferencesProvider target, ReaderPreferences preferences) {
    final fontFamily = preferences.fontFamily;
    if (fontFamily != null && target.defaultFont != fontFamily) {
      target.defaultFont = fontFamily;
    }
    if (target.defaultFontSize != preferences.fontSize) {
      target.defaultFontSize = preferences.fontSize;
    }

    final lineSpacing = switch (preferences.lineHeight) {
      < 1.4 => 'compact',
      > 1.6 => 'relaxed',
      _ => 'normal',
    };
    if (target.lineSpacing != lineSpacing) {
      target.lineSpacing = lineSpacing;
    }

    final margin = preferences.pageMargins.left;
    final margins = switch (margin) {
      < 20 => 'small',
      > 32 => 'large',
      _ => 'medium',
    };
    if (target.margins != margins) {
      target.margins = margins;
    }

    final readingMode = preferences.layoutMode == ReaderLayoutMode.scroll ? 'scroll' : 'paginated';
    if (target.readingMode != readingMode) {
      target.readingMode = readingMode;
    }
  }

  static double _totalProgression(ReaderLocator locator) {
    return switch (locator) {
      EpubReaderLocator(:final totalProgression) => totalProgression,
      PdfReaderLocator(:final totalProgression) => totalProgression,
    };
  }
}
