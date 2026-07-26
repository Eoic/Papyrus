import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/pages/book_details_page.dart';
import 'package:provider/provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('Start reading explains unsupported formats', (tester) async {
    final book = buildTestBook(id: 'mobi-book', fileFormat: BookFormat.mobi);
    final dataStore = DataStore()..loadData(books: [book]);
    addTearDown(dataStore.dispose);
    final router = GoRouter(
      initialLocation: '/library/details/${book.id}',
      routes: [
        GoRoute(
          path: '/library/details/:bookId',
          builder: (context, state) => BookDetailsPage(id: state.pathParameters['bookId']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: dataStore,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Read'));
    await tester.pump();

    expect(find.text('This book format is not supported yet.'), findsOneWidget);
  });

  testWidgets('Start reading opens the reader route for EPUB books', (tester) async {
    final book = buildTestBook(id: 'epub-book', fileFormat: BookFormat.epub);
    final dataStore = DataStore()..loadData(books: [book]);
    addTearDown(dataStore.dispose);
    final router = GoRouter(
      initialLocation: '/library/details/${book.id}',
      routes: [
        GoRoute(
          path: '/library/details/:bookId',
          builder: (context, state) => BookDetailsPage(id: state.pathParameters['bookId']),
        ),
        GoRoute(
          name: 'BOOK_READER',
          path: '/library/read/:bookId',
          builder: (context, state) => const Scaffold(body: Text('Reader opened')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: dataStore,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(find.text('Reader opened'), findsOneWidget);
  });
}
