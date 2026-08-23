import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/platform/book_import_drop_registration.dart';
import 'package:web/web.dart' as web;

void main() {
  test('installs browser drag-and-drop handlers', () {
    web.window.ondrop = null;
    web.window.ondragenter = null;
    web.window.ondragover = null;

    ensureBookImportDropPluginRegistered();

    expect(web.window.ondrop, isNotNull);
    expect(web.window.ondragenter, isNotNull);
    expect(web.window.ondragover, isNotNull);
  });
}
