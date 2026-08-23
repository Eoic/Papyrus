import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/book_import_item_card.dart';

void main() {
  testWidgets('failed import card prioritizes retry over remove', (tester) async {
    final item = BookImportBatchItem.queued(
      id: 'import-0',
      file: SelectedBookFile(name: 'failed.epub', bytes: Uint8List.fromList([1])),
    ).startProcessing().processingFailed('Could not parse file.');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookImportItemCard(
            item: item,
            presentation: BookImportItemCardPresentation.progress,
            onRetry: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byTooltip('Remove failed.epub'), findsNothing);
    expect(find.text('Could not parse file.'), findsOneWidget);
  });
}
