import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/reader/reader_session.dart';
import 'package:papyrus_reader/papyrus_reader.dart';

import '../helpers/test_helpers.dart';

void main() {
  test('coalesces rapid locator changes into the latest saved book', () async {
    final saved = <Book>[];
    final session = ReaderSession(
      book: buildTestBook(fileFormat: BookFormat.pdf),
      saveBook: saved.add,
      debounceDuration: Duration.zero,
      now: () => DateTime.utc(2026, 7, 27),
    );

    session.updateLocator(PdfReaderLocator(pageIndex: 1, pageOffset: 0, totalProgression: 0.1));
    session.updateLocator(PdfReaderLocator(pageIndex: 4, pageOffset: 0, totalProgression: 0.4));
    await Future<void>.delayed(Duration.zero);

    expect(saved, hasLength(1));
    expect(saved.single.currentPage, 5);
    expect(saved.single.currentPosition, 0.4);
    session.dispose();
  });

  test('dispose flushes the final pending locator', () {
    final saved = <Book>[];
    final session = ReaderSession(
      book: buildTestBook(fileFormat: BookFormat.epub),
      saveBook: saved.add,
      debounceDuration: const Duration(days: 1),
      now: () => DateTime.utc(2026, 7, 27),
    );

    session.updateLocator(
      EpubReaderLocator(cfi: 'epubcfi(/6/4)', spineIndex: 1, localProgression: 0.5, totalProgression: 0.25),
    );
    session.dispose();

    expect(saved, hasLength(1));
    expect(saved.single.currentCfi, 'epubcfi(/6/4)');
    expect(saved.single.currentPosition, 0.25);
  });
}
