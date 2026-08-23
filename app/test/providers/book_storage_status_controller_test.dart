import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/media/media_models.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/book_storage_status_controller.dart';

Book _book({String id = 'book-1', bool physical = false, String? fileMediaId}) {
  return Book(
    id: id,
    title: 'Book',
    author: 'Author',
    addedAt: DateTime.utc(2026),
    isPhysical: physical,
    fileMediaId: fileMediaId,
  );
}

void main() {
  test('account state includes saved, syncing, and failed', () {
    expect(
      resolveBookAccountStatus(book: _book(fileMediaId: 'media-1'), isAccountLibrary: true),
      BookAccountStatus.saved,
    );
    expect(resolveBookAccountStatus(book: _book(), isAccountLibrary: true), BookAccountStatus.syncing);
    expect(
      resolveBookAccountStatus(
        book: _book(),
        isAccountLibrary: true,
        mediaTasks: const [
          MediaUploadTask(
            id: 'book-1:book_file',
            bookId: 'book-1',
            kind: MediaKind.bookFile,
            filename: 'book.epub',
            contentType: 'application/epub+zip',
            status: MediaUploadTaskStatus.failed,
          ),
        ],
      ),
      BookAccountStatus.failed,
    );
  });

  test('guest books have no account state', () {
    expect(resolveBookAccountStatus(book: _book(), isAccountLibrary: false), isNull);
  });

  test('local file checks are asynchronous and cached', () async {
    final checked = Completer<bool>();
    var calls = 0;
    final controller = BookStorageStatusController.detached(
      hasBookFile: (_) {
        calls++;
        return checked.future;
      },
    );

    expect(controller.deviceStatus(_book()), BookDeviceStatus.checking);
    final firstCheck = controller.ensureDeviceStatus(_book());
    final secondCheck = controller.ensureDeviceStatus(_book());
    expect(calls, 1);

    checked.complete(false);
    await Future.wait([firstCheck, secondCheck]);
    expect(controller.deviceStatus(_book()), BookDeviceStatus.missing);
    expect(calls, 1);

    controller.dispose();
  });
}
