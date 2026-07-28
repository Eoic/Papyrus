import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/reader/reader_book_adapter.dart';
import 'package:papyrus_reader/papyrus_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ReaderBookAdapter', () {
    test('maps only EPUB and PDF formats', () {
      expect(ReaderBookAdapter.formatFor(BookFormat.epub), ReaderFormat.epub);
      expect(ReaderBookAdapter.formatFor(BookFormat.pdf), ReaderFormat.pdf);
      expect(ReaderBookAdapter.formatFor(BookFormat.mobi), isNull);
      expect(ReaderBookAdapter.formatFor(null), isNull);
    });

    test('restores a versioned locator from book metadata', () {
      final book = buildTestBook(
        customMetadata: {
          ReaderBookAdapter.locatorMetadataKey: {
            'version': 1,
            'type': 'epub',
            'cfi': 'epubcfi(/6/2)',
            'spineIndex': 2,
            'localProgression': 0.25,
            'totalProgression': 0.4,
          },
        },
      );

      expect(
        ReaderBookAdapter.restoreLocator(book),
        EpubReaderLocator(cfi: 'epubcfi(/6/2)', spineIndex: 2, localProgression: 0.25, totalProgression: 0.4),
      );
    });

    test('ignores malformed locator metadata', () {
      final book = buildTestBook(
        customMetadata: {
          ReaderBookAdapter.locatorMetadataKey: {'version': 99},
        },
      );

      expect(ReaderBookAdapter.restoreLocator(book), isNull);
    });

    test('ignores a locator for a different book format', () {
      final book = buildTestBook(
        fileFormat: BookFormat.pdf,
        customMetadata: {
          ReaderBookAdapter.locatorMetadataKey: {
            'version': 1,
            'type': 'epub',
            'cfi': 'epubcfi(/6/2)',
            'spineIndex': 0,
            'localProgression': 0.1,
            'totalProgression': 0.1,
          },
        },
      );

      expect(ReaderBookAdapter.restoreLocator(book), isNull);
    });

    test('persists the full locator and client summary fields', () {
      final now = DateTime.utc(2026, 7, 27, 12);
      final book = buildTestBook(fileFormat: BookFormat.pdf, customMetadata: {'source': 'import'});
      final locator = PdfReaderLocator(pageIndex: 4, pageOffset: 0.2, totalProgression: 0.35);

      final updated = ReaderBookAdapter.applyLocator(book, locator, now: now);

      expect(updated.customMetadata?['source'], 'import');
      expect(updated.customMetadata?[ReaderBookAdapter.locatorMetadataKey], locator.toJson());
      expect(updated.currentPage, 5);
      expect(updated.currentPosition, 0.35);
      expect(updated.readingStatus, LibraryReadingStatus.inProgress);
      expect(updated.lastReadAt, now);
      expect(updated.startedAt, now);
    });

    test('maps application reading defaults and active colors', () async {
      SharedPreferences.setMockInitialValues({
        'default_font': 'Georgia',
        'default_font_size': 20.0,
        'line_spacing': 'relaxed',
        'margins': 'large',
        'reading_mode': 'scroll',
      });
      final provider = PreferencesProvider(await SharedPreferences.getInstance());
      final colors = ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark);

      final preferences = ReaderBookAdapter.preferencesFor(provider, colors);

      expect(preferences.fontFamily, 'Georgia');
      expect(preferences.fontSize, 20);
      expect(preferences.lineHeight, 1.75);
      expect(preferences.pageMargins, const EdgeInsets.all(40));
      expect(preferences.layoutMode, ReaderLayoutMode.scroll);
      expect(preferences.backgroundColor, colors.surface);
      expect(preferences.foregroundColor, colors.onSurface);
      expect(preferences.brightness, Brightness.dark);
    });

    test('persists reader setting changes as application defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PreferencesProvider(await SharedPreferences.getInstance());
      const readerPreferences = ReaderPreferences(
        fontFamily: 'Atkinson Hyperlegible',
        fontSize: 22,
        lineHeight: 1.8,
        pageMargins: EdgeInsets.all(42),
        layoutMode: ReaderLayoutMode.scroll,
      );

      ReaderBookAdapter.persistPreferences(provider, readerPreferences);

      expect(provider.defaultFont, 'Atkinson Hyperlegible');
      expect(provider.defaultFontSize, 22);
      expect(provider.lineSpacing, 'relaxed');
      expect(provider.margins, 'large');
      expect(provider.readingMode, 'scroll');
    });
  });
}
