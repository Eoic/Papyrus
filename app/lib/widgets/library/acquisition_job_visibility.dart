import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/models/book.dart';

class AcquisitionLibraryItems {
  final Map<String, AcquisitionJob> linkedJobsByBookId;
  final List<AcquisitionJob> orphanJobs;
  final Set<String> downloadingBookIds;
  final List<AcquisitionJob> downloadingOrphanJobs;

  const AcquisitionLibraryItems({
    required this.linkedJobsByBookId,
    required this.orphanJobs,
    required this.downloadingBookIds,
    required this.downloadingOrphanJobs,
  });

  bool get hasDownloadingItems => downloadingBookIds.isNotEmpty || downloadingOrphanJobs.isNotEmpty;
}

bool isDownloadingFilterStatus(AcquisitionJobStatus status) => switch (status) {
  AcquisitionJobStatus.queued ||
  AcquisitionJobStatus.submitted ||
  AcquisitionJobStatus.downloading ||
  AcquisitionJobStatus.needsFileSelection ||
  AcquisitionJobStatus.importing ||
  AcquisitionJobStatus.failed ||
  AcquisitionJobStatus.unknown => true,
  AcquisitionJobStatus.completed || AcquisitionJobStatus.cancelled => false,
};

AcquisitionLibraryItems buildAcquisitionLibraryItems({
  required Iterable<Book> books,
  required Iterable<AcquisitionJob> jobs,
}) {
  final bookList = books.toList();
  final jobList = jobs.toList();
  final synchronizedBookIds = bookList.map((book) => book.id).toSet();
  final jobsByBookId = <String, AcquisitionJob>{};

  for (final job in jobList) {
    final bookId = job.bookId;

    if (bookId != null) {
      jobsByBookId.putIfAbsent(bookId, () => job);
    }
  }

  final linkedJobsByBookId = <String, AcquisitionJob>{};
  final downloadingBookIds = <String>{};
  final claimedJobIds = <String>{};

  for (final book in bookList) {
    final job = jobsByBookId[book.id];

    if (job == null || !claimedJobIds.add(job.id)) {
      continue;
    }

    if (job.status == AcquisitionJobStatus.completed) {
      continue;
    }

    linkedJobsByBookId[book.id] = job;

    if (isDownloadingFilterStatus(job.status)) {
      downloadingBookIds.add(book.id);
    }
  }

  final orphanJobs = <AcquisitionJob>[];
  final downloadingOrphanJobs = <AcquisitionJob>[];
  final seenJobIds = <String>{...claimedJobIds};
  final seenPendingBookIds = <String>{};

  for (final job in jobList) {
    if (!seenJobIds.add(job.id)) {
      continue;
    }

    if (job.status == AcquisitionJobStatus.completed) {
      continue;
    }

    final bookId = job.bookId;

    if (bookId != null && (synchronizedBookIds.contains(bookId) || !seenPendingBookIds.add(bookId))) {
      continue;
    }

    orphanJobs.add(job);

    if (isDownloadingFilterStatus(job.status)) {
      downloadingOrphanJobs.add(job);
    }
  }

  return AcquisitionLibraryItems(
    linkedJobsByBookId: Map.unmodifiable(linkedJobsByBookId),
    orphanJobs: List.unmodifiable(orphanJobs),
    downloadingBookIds: Set.unmodifiable(downloadingBookIds),
    downloadingOrphanJobs: List.unmodifiable(downloadingOrphanJobs),
  );
}
