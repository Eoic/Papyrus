import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/pages/reader_page.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('explains when a book format is not supported', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesProvider(await SharedPreferences.getInstance());
    final dataStore = DataStore()
      ..loadData(
        books: [buildTestBook(id: 'mobi-book', fileFormat: BookFormat.mobi)],
      );
    addTearDown(dataStore.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dataStore),
          ChangeNotifierProvider.value(value: preferences),
        ],
        child: const MaterialApp(home: ReaderPage(bookId: 'mobi-book')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This book format is not supported yet.'), findsOneWidget);
  });
}
