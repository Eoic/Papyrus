import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/widgets/library/acquisition_job_visibility.dart';

void main() {
  group('isDownloadingFilterStatus', () {
    for (final status in [
      AcquisitionJobStatus.queued,
      AcquisitionJobStatus.submitted,
      AcquisitionJobStatus.downloading,
      AcquisitionJobStatus.needsFileSelection,
      AcquisitionJobStatus.importing,
      AcquisitionJobStatus.failed,
      AcquisitionJobStatus.unknown,
    ]) {
      test('$status appears in Downloading', () {
        expect(isDownloadingFilterStatus(status), isTrue);
      });
    }

    for (final status in [AcquisitionJobStatus.completed, AcquisitionJobStatus.cancelled]) {
      test('$status does not appear in Downloading', () {
        expect(isDownloadingFilterStatus(status), isFalse);
      });
    }
  });

  group('buildAcquisitionLibraryItems', () {
    test('links an active job to its synchronized book', () {
      final job = _job(id: 'job-1', bookId: 'book-1');

      final items = buildAcquisitionLibraryItems(books: [_book('book-1')], jobs: [job]);

      expect(items.linkedJobsByBookId, {'book-1': job});
      expect(items.orphanJobs, isEmpty);
      expect(items.downloadingBookIds, {'book-1'});
      expect(items.downloadingOrphanJobs, isEmpty);
      expect(items.hasDownloadingItems, isTrue);
    });

    test('keeps an active orphan as a placeholder', () {
      final job = _job(id: 'job-1', bookId: null);

      final items = buildAcquisitionLibraryItems(books: const [], jobs: [job]);

      expect(items.linkedJobsByBookId, isEmpty);
      expect(items.orphanJobs, [job]);
      expect(items.downloadingBookIds, isEmpty);
      expect(items.downloadingOrphanJobs, [job]);
      expect(items.hasDownloadingItems, isTrue);
    });

    test('does not resurrect a completed job as an orphan placeholder', () {
      final job = _job(id: 'job-1', bookId: 'book-1', status: AcquisitionJobStatus.completed);

      final pendingItems = buildAcquisitionLibraryItems(books: const [], jobs: [job]);
      final synchronizedItems = buildAcquisitionLibraryItems(books: [_book('book-1')], jobs: [job]);

      expect(pendingItems.orphanJobs, isEmpty);
      expect(pendingItems.hasDownloadingItems, isFalse);
      expect(synchronizedItems.linkedJobsByBookId, isEmpty);
      expect(synchronizedItems.orphanJobs, isEmpty);
      expect(synchronizedItems.hasDownloadingItems, isFalse);
    });

    test('keeps cancelled orphan in All until removal', () {
      final job = _job(id: 'job-1', bookId: null, status: AcquisitionJobStatus.cancelled);

      final items = buildAcquisitionLibraryItems(books: const [], jobs: [job]);

      expect(items.orphanJobs, [job]);
      expect(items.downloadingOrphanJobs, isEmpty);
      expect(items.hasDownloadingItems, isFalse);
    });

    test('does not create a placeholder for a synchronized book', () {
      final job = _job(id: 'job-1', bookId: 'book-1');

      final items = buildAcquisitionLibraryItems(books: [_book('book-1')], jobs: [job]);

      expect(items.linkedJobsByBookId.values, [job]);
      expect(items.orphanJobs, isEmpty);
      expect(items.downloadingOrphanJobs, isEmpty);
    });

    test('deduplicates repeated jobs and pending book placeholders', () {
      final first = _job(id: 'job-1', bookId: 'pending-book');
      final duplicateId = _job(id: 'job-1', bookId: null);
      final duplicateBook = _job(id: 'job-2', bookId: 'pending-book');

      final items = buildAcquisitionLibraryItems(books: const [], jobs: [first, duplicateId, duplicateBook]);

      expect(items.orphanJobs, [first]);
      expect(items.downloadingOrphanJobs, [first]);
    });

    test('claims a duplicated job for the first synchronized book in book order', () {
      final secondBookJob = _job(id: 'job-1', bookId: 'book-2');
      final firstBookJob = _job(id: 'job-1', bookId: 'book-1');

      final items = buildAcquisitionLibraryItems(
        books: [_book('book-1'), _book('book-2')],
        jobs: [secondBookJob, firstBookJob],
      );

      expect(items.linkedJobsByBookId, {'book-1': firstBookJob});
      expect(items.downloadingBookIds, {'book-1'});
      expect(items.orphanJobs, isEmpty);
    });

    test('does not report Downloading when only terminal jobs remain', () {
      final items = buildAcquisitionLibraryItems(
        books: const [],
        jobs: [
          _job(id: 'completed', bookId: null, status: AcquisitionJobStatus.completed),
          _job(id: 'cancelled', bookId: null, status: AcquisitionJobStatus.cancelled),
        ],
      );

      expect(items.orphanJobs, hasLength(1));
      expect(items.orphanJobs.single.status, AcquisitionJobStatus.cancelled);
      expect(items.downloadingBookIds, isEmpty);
      expect(items.downloadingOrphanJobs, isEmpty);
      expect(items.hasDownloadingItems, isFalse);
    });
  });
}

Book _book(String id) {
  return Book(id: id, title: 'Book $id', author: 'Author', addedAt: DateTime(2026));
}

AcquisitionJob _job({
  required String id,
  required String? bookId,
  AcquisitionJobStatus status = AcquisitionJobStatus.downloading,
}) {
  return AcquisitionJob(
    id: id,
    endpointId: 'endpoint-1',
    ruleId: null,
    bookId: bookId,
    title: 'Release $id',
    status: status,
    clientReference: null,
    clientHash: null,
    clientState: null,
    progressBasisPoints: null,
    downloadedBytes: null,
    totalBytes: null,
    downloadSpeedBytesPerSecond: null,
    etaSeconds: null,
    selectedFilePath: null,
    retryCount: 0,
    error: null,
    nextPollAt: null,
    createdAt: null,
    updatedAt: null,
    submittedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
  );
}
