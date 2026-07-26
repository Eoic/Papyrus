import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/library/online_results_view.dart';
import 'package:papyrus/widgets/library/remote_release_list.dart';

void main() {
  const release = TorrentRelease(
    title: 'The Dispossessed EPUB',
    releaseToken: 'token-1',
    protocol: 'torrent',
    indexer: 'Nyaa',
  );

  Widget buildView({
    bool hasSearched = false,
    bool isSearching = false,
    String query = '',
    String? error,
    List<TorrentRelease> releases = const [],
    Set<String> selectedReleaseTokens = const {},
    Map<String, String> errorsByReleaseToken = const {},
    VoidCallback? onRetry,
    ValueChanged<String>? onToggleSelection,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: OnlineResultsView(
          hasSearched: hasSearched,
          isSearching: isSearching,
          query: query,
          error: error,
          releases: releases,
          selectedReleaseTokens: selectedReleaseTokens,
          errorsByReleaseToken: errorsByReleaseToken,
          onRetry: onRetry ?? () {},
          onToggleSelection: onToggleSelection ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('shows guidance before a search', (tester) async {
    await tester.pumpWidget(buildView());

    expect(find.text('Search connected sources'), findsOneWidget);
    expect(find.text('Search by title or author to find available releases.'), findsOneWidget);
    expect(find.byType(RemoteReleaseList), findsNothing);
  });

  testWidgets('shows query-aware loading before stale results', (tester) async {
    await tester.pumpWidget(buildView(isSearching: true, query: 'Dune', releases: const [release]));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Searching connected sources for “Dune”…'), findsOneWidget);
    expect(find.text(release.title), findsNothing);
  });

  testWidgets('shows the passed-in error and retries only after the action is tapped', (tester) async {
    var retryCalls = 0;

    await tester.pumpWidget(
      buildView(
        hasSearched: true,
        error: 'The connected sources are unavailable.',
        releases: const [release],
        onRetry: () => retryCalls += 1,
      ),
    );

    expect(retryCalls, 0);
    expect(find.text('The connected sources are unavailable.'), findsOneWidget);
    expect(find.text(release.title), findsNothing);

    await tester.tap(find.text('Try again'));

    expect(retryCalls, 1);
  });

  testWidgets('shows query-aware empty guidance after a search', (tester) async {
    await tester.pumpWidget(buildView(hasSearched: true, query: 'Dune'));

    expect(find.text('No releases found'), findsOneWidget);
    expect(find.text('No releases found for “Dune”. Try another title or author.'), findsOneWidget);
  });

  testWidgets('delegates results and their selection errors to RemoteReleaseList', (tester) async {
    final toggled = <String>[];

    await tester.pumpWidget(
      buildView(
        hasSearched: true,
        releases: const [release],
        selectedReleaseTokens: const {'token-1'},
        errorsByReleaseToken: const {'token-1': 'The download client rejected this release.'},
        onToggleSelection: toggled.add,
      ),
    );

    expect(find.byType(RemoteReleaseList), findsOneWidget);
    expect(find.text(release.title), findsOneWidget);
    expect(find.text('The download client rejected this release.'), findsOneWidget);

    await tester.tap(find.text(release.title));

    expect(toggled, ['token-1']);
  });
}
