import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/pages/annotations_page.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';
import 'package:provider/provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('annotation menu opens the complete prefilled editor and saves all fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = DataStore();
    store.addBook(buildTestBook(id: 'book', isPhysical: true));
    await store.addAnnotation(
      Annotation(
        id: 'annotation',
        bookId: 'book',
        selectedText: 'Original passage',
        color: HighlightColor.blue,
        location: const BookLocation(pageNumber: 12, chapterTitle: 'Chapter', chapter: 2, percentage: 0.2),
        note: 'Attached note',
        createdAt: DateTime.utc(2026),
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const MaterialApp(home: AnnotationsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(AnnotationCard));
    await tester.pumpAndSettle();
    expect(find.text('Edit annotation'), findsOneWidget);
    await tester.tap(find.text('Edit annotation'));
    await tester.pumpAndSettle();
    expect(find.text('Original passage'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Chapter'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Attached note'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Edited passage');
    await tester.enterText(fields.at(1), '24');
    await tester.enterText(fields.at(2), 'New chapter');
    await tester.enterText(fields.at(3), '');
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Highlight color'), findsOneWidget);
    await tester.tap(find.byKey(const Key('annotation-color-green')));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = store.getAnnotation('annotation')!;
    expect(saved.selectedText, 'Edited passage');
    expect(saved.location.pageNumber, 24);
    expect(saved.location.chapterTitle, 'New chapter');
    expect(saved.location.chapter, 2);
    expect(saved.location.percentage, 0.2);
    expect(saved.note, isNull);
    expect(saved.color, HighlightColor.green);
    await tester.pumpWidget(const SizedBox());
    unawaited(store.disposeBookRepository());
    await tester.pump();
    store.dispose();
  });
}
