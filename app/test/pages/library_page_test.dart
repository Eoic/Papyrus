import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/repositories/book_repository.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/pages/library_page.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_card.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_list_item.dart';
import 'package:papyrus/widgets/library/book_card.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/library/online_books_header.dart';
import 'package:papyrus/widgets/library/online_results_view.dart';
import 'package:papyrus/widgets/library/selection_header.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';
import 'package:provider/provider.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LibraryPage', () {
    late LibraryProvider libraryProvider;
    late DataStore dataStore;

    setUp(() {
      libraryProvider = LibraryProvider();
      dataStore = createTestDataStore();
    });

    Widget buildPage({
      Size screenSize = const Size(400, 800),
      LibraryProvider? provider,
      DataStore? store,
      AcquisitionDownloadsProvider? downloadsProvider,
      ThemeData? theme,
      TextScaler textScaler = TextScaler.noScaling,
    }) {
      final page = theme == null ? const LibraryPage() : Theme(data: theme, child: const LibraryPage());

      return createTestPage(
        page: MediaQuery(
          data: MediaQueryData(size: screenSize, textScaler: textScaler),
          child: page,
        ),
        libraryProvider: provider ?? libraryProvider,
        dataStore: store ?? dataStore,
        screenSize: screenSize,
        additionalProviders: [
          if (downloadsProvider != null)
            ChangeNotifierProvider<AcquisitionDownloadsProvider>.value(value: downloadsProvider),
        ],
      );
    }

    // ========================================================================
    // Mobile layout tests
    // ========================================================================

    group('mobile layout', () {
      testWidgets('shows loading until the first repository snapshot arrives', (tester) async {
        final repository = _ControlledBookRepository();
        final loadingStore = DataStore(bookRepository: repository);

        await tester.pumpWidget(buildPage(store: loadingStore));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('No books found'), findsNothing);

        repository.controller.add(const []);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('No books found'), findsOneWidget);

        await repository.controller.close();
      });

      testWidgets('renders search bar', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(LibrarySearchBar), findsOneWidget);
      });

      testWidgets('local search stays local and offers an explicit online search when ready', (tester) async {
        final gateway = _LibraryAcquisitionGateway();
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Dune Messiah');

        await tester.pumpWidget(buildPage(screenSize: const Size(400, 1000), downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();

        expect(gateway.searchQueries, isEmpty);
        expect(find.text('Search online for “Dune Messiah”'), findsOneWidget);
        expect(find.textContaining('Downloads'), findsNothing);
        expect(find.byType(OnlineBooksHeader), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('starts visible polling on mount and stops it on provider swap and dispose', (tester) async {
        final firstProvider = _TrackingDownloadsProvider(gateway: _LibraryAcquisitionGateway());
        final secondProvider = _TrackingDownloadsProvider(gateway: _LibraryAcquisitionGateway());

        await tester.pumpWidget(buildPage(downloadsProvider: firstProvider));
        await tester.pump();
        expect(firstProvider.libraryVisibility, [true]);

        await tester.pumpWidget(buildPage(downloadsProvider: secondProvider));
        await tester.pump();
        expect(firstProvider.libraryVisibility, [true, false]);
        expect(secondProvider.libraryVisibility, [true]);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(secondProvider.libraryVisibility, [true, false]);

        firstProvider.dispose();
        secondProvider.dispose();
      });

      testWidgets('does not offer online search when acquisition is unavailable', (tester) async {
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        downloadsProvider.setServerManagedDownloadsReady(false);
        libraryProvider.setSearchQuery('Dune Messiah');

        await tester.pumpWidget(buildPage(screenSize: const Size(400, 1000), downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();

        expect(find.text('Search online for “Dune Messiah”'), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('Add book exposes online search only when acquisition is ready', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1400, 1000);
        addTearDown(tester.view.reset);

        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();

        await tester.pumpWidget(buildPage(screenSize: const Size(400, 1000), downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Find books online'), findsOneWidget);

        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        downloadsProvider.setServerManagedDownloadsReady(false);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Find books online'), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('explicit online search replaces the grid and Back restores local state', (tester) async {
        final gateway = _LibraryAcquisitionGateway();
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider
          ..setSearchQuery('Dune Messiah')
          ..addFilter(LibraryFilterType.favorites)
          ..setViewMode(LibraryViewMode.list);

        await tester.pumpWidget(buildPage(screenSize: const Size(400, 1000), downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Dune Messiah”'));
        await tester.pumpAndSettle();

        expect(gateway.searchQueries, ['Dune Messiah']);
        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(find.byType(OnlineResultsView), findsOneWidget);
        expect(find.text('Remote result'), findsOneWidget);
        expect(find.byType(BookListItem), findsNothing);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsNothing);
        expect(libraryProvider.searchQuery, 'Dune Messiah');
        expect(libraryProvider.isFilterActive(LibraryFilterType.favorites), isTrue);
        expect(libraryProvider.viewMode, LibraryViewMode.list);
        expect(gateway.searchQueries, hasLength(1));

        downloadsProvider.dispose();
      });

      testWidgets('online loading and successful empty states replace local books in-place', (tester) async {
        final searchCompleter = Completer<List<TorrentRelease>>();
        final gateway = _LibraryAcquisitionGateway(searchCompleter: searchCompleter);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Missing title');

        await tester.pumpWidget(buildPage(downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Missing title”'));
        await tester.pump();

        expect(find.byType(OnlineResultsView), findsOneWidget);
        expect(find.text('Searching connected sources for “Missing title”…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(BookCard), findsNothing);

        searchCompleter.complete(const []);
        await tester.pumpAndSettle();

        expect(find.text('No releases found'), findsOneWidget);
        expect(find.textContaining('Missing title'), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(BookCard), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('Back invalidates a hung search so a new online session can search immediately', (tester) async {
        final oldSearch = Completer<List<TorrentRelease>>();
        final gateway = _LibraryAcquisitionGateway(
          searchResponses: [
            oldSearch.future,
            const [
              TorrentRelease(title: 'New result', releaseToken: 'new-token', protocol: 'torrent', indexer: 'Prowlarr'),
            ],
          ],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Old query');

        await tester.pumpWidget(
          buildPage(
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Old query”'));
        await tester.pump();
        expect(downloadsProvider.isSearching, isTrue);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(downloadsProvider.isSearching, isFalse);

        libraryProvider.setSearchQuery('New query');
        await tester.pump();
        await tester.tap(find.text('Search online for “New query”'));
        await tester.pumpAndSettle();

        expect(downloadsProvider.remoteQuery, 'New query');
        expect(find.text('New result'), findsOneWidget);

        oldSearch.complete(const [
          TorrentRelease(title: 'Old result', releaseToken: 'old-token', protocol: 'torrent', indexer: 'Prowlarr'),
        ]);
        await tester.pumpAndSettle();

        expect(downloadsProvider.remoteQuery, 'New query');
        expect(find.text('New result'), findsOneWidget);
        expect(find.text('Old result'), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('Add book enters online mode without searching', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1400, 1000);
        addTearDown(tester.view.reset);

        final gateway = _LibraryAcquisitionGateway();
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(400, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Find books online'));
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(find.text('Search connected sources'), findsOneWidget);
        expect(gateway.searchQueries, isEmpty);

        downloadsProvider.dispose();
      });

      testWidgets('successful release submission returns to local books', (tester) async {
        final gateway = _LibraryAcquisitionGateway(releaseCount: 2);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Dune Messiah');

        await tester.pumpWidget(
          buildPage(
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Dune Messiah”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();

        expect(find.byType(SelectionHeader), findsOneWidget);
        expect(find.text('Select all'), findsOneWidget);

        await tester.tap(find.text('Select all'));
        await tester.pump();
        expect(downloadsProvider.selectedReleaseTokens, {'release-token', 'release-token-2'});

        await tester.tap(find.text('Download'));
        await tester.pumpAndSettle();

        expect(gateway.submittedTokens, ['release-token', 'release-token-2']);
        expect(find.byType(OnlineBooksHeader), findsNothing);
        expect(libraryProvider.searchQuery, 'Dune Messiah');

        downloadsProvider.dispose();
      });

      testWidgets('an old successful submission cannot close a newer online session', (tester) async {
        final submission = Completer<BatchSubmissionResponse>();
        final gateway = _LibraryAcquisitionGateway(
          submissionCompleter: submission,
          searchResponses: const [
            [TorrentRelease(title: 'Old result', releaseToken: 'old-token', protocol: 'torrent', indexer: 'Prowlarr')],
            [TorrentRelease(title: 'New result', releaseToken: 'new-token', protocol: 'torrent', indexer: 'Prowlarr')],
          ],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Old query');

        await tester.pumpWidget(
          buildPage(
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Old query”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text('Download'));
        await tester.pump();

        expect(downloadsProvider.isSubmitting, isTrue);

        await tester.tap(find.byTooltip('Exit selection'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        libraryProvider.setSearchQuery('New query');
        await tester.pump();
        await tester.tap(find.text('Search online for “New query”'));
        await tester.pumpAndSettle();

        expect(downloadsProvider.remoteQuery, 'New query');
        expect(find.text('New result'), findsOneWidget);

        submission.complete(
          BatchSubmissionResponse(
            items: [
              BatchSubmissionItem(
                index: 0,
                job: _libraryJob(
                  AcquisitionJobStatus.submitted,
                  id: 'old-submission',
                  bookId: null,
                  title: 'Old result',
                ),
                error: null,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(downloadsProvider.remoteQuery, 'New query');
        expect(find.text('New result'), findsOneWidget);
        expect(downloadsProvider.jobs.map((job) => job.id), isNot(contains('old-submission')));

        downloadsProvider.dispose();
      });

      testWidgets('a submission from a replaced provider cannot clear the current online state', (tester) async {
        final submission = Completer<BatchSubmissionResponse>();
        final oldProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(submissionCompleter: submission),
          pollingInterval: Duration.zero,
        );
        final currentProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(),
          pollingInterval: Duration.zero,
        );
        await oldProvider.refreshConfiguration();
        currentProvider.setRemoteResults('Current query', const [
          TorrentRelease(
            title: 'Current result',
            releaseToken: 'current-token',
            protocol: 'torrent',
            indexer: 'Prowlarr',
          ),
        ]);
        libraryProvider.setSearchQuery('Old query');

        await tester.pumpWidget(
          buildPage(
            store: createTestDataStore(books: []),
            downloadsProvider: oldProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Old query”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text('Download'));
        await tester.pump();

        await tester.pumpWidget(
          buildPage(
            store: createTestDataStore(books: []),
            downloadsProvider: currentProvider,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(find.text('Current result'), findsOneWidget);

        submission.complete(
          BatchSubmissionResponse(
            items: [
              BatchSubmissionItem(
                index: 0,
                job: _libraryJob(AcquisitionJobStatus.submitted, id: 'old-job', bookId: null),
                error: null,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(currentProvider.remoteQuery, 'Current query');
        expect(find.text('Current result'), findsOneWidget);

        oldProvider.dispose();
        currentProvider.dispose();
      });

      testWidgets('Deselect all clears every selected online release', (tester) async {
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(releaseCount: 2),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Missing title');

        await tester.pumpWidget(buildPage(downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Missing title”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.tap(find.text('Select all'));
        await tester.pump();

        expect(downloadsProvider.selectedReleaseTokens, {'release-token', 'release-token-2'});
        expect(find.text('Deselect all'), findsOneWidget);

        await tester.tap(find.text('Deselect all'));
        await tester.pump();

        expect(downloadsProvider.selectedReleaseTokens, isEmpty);
        expect(find.byType(SelectionHeader), findsNothing);
        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(find.byType(Checkbox), findsNWidgets(2));

        downloadsProvider.dispose();
      });

      testWidgets('failed release submission stays online with its row selected', (tester) async {
        final gateway = _LibraryAcquisitionGateway(submissionError: 'Release token expired');
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Dune Messiah');

        await tester.pumpWidget(buildPage(downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Dune Messiah”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.tap(find.text('Download'));
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsNothing);
        expect(find.byType(SelectionHeader), findsOneWidget);
        expect(find.text('Remote result'), findsOneWidget);
        expect(find.text('This release could not be sent to the download client.'), findsOneWidget);
        expect(downloadsProvider.selectedReleaseTokens, {'release-token'});

        downloadsProvider.dispose();
      });

      testWidgets('partial submission keeps the failed row selected and the successful job', (tester) async {
        final gateway = _LibraryAcquisitionGateway(releaseCount: 2, failedSubmissionIndexes: const {1});
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Remote');

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Remote”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.tap(find.text('Select all'));
        await tester.pump();
        await tester.tap(find.text('Download'));
        await tester.pumpAndSettle();

        expect(find.byType(SelectionHeader), findsOneWidget);
        expect(downloadsProvider.selectedReleaseTokens, {'release-token-2'});
        expect(downloadsProvider.jobs.map((job) => job.id), contains('submitted-job-0'));
        expect(find.text('Remote result 2'), findsOneWidget);
        expect(find.text('This release could not be sent to the download client.'), findsOneWidget);
        expect(find.textContaining('client.invalid'), findsNothing);

        downloadsProvider.clearReleaseSelection();
        await tester.pump();
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(AcquisitionPlaceholderCard), findsOneWidget);
        expect(find.text('Remote result'), findsWidgets);

        downloadsProvider.dispose();
      });

      testWidgets('multiple clients use a content-height choice sheet with user names only', (tester) async {
        final gateway = _LibraryAcquisitionGateway(clientCount: 2);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Dune Messiah');

        await tester.pumpWidget(buildPage(screenSize: const Size(400, 1000), downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Dune Messiah”'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.tap(find.text('Download'));
        await tester.pumpAndSettle();

        expect(find.text('Download with'), findsOneWidget);
        expect(find.text('Download client 1'), findsOneWidget);
        expect(find.text('Download client 2'), findsOneWidget);
        expect(find.textContaining('/downloads'), findsNothing);

        await tester.tap(find.text('Download client 2'));
        await tester.pumpAndSettle();

        expect(gateway.submittedEndpointId, 'client-2');
        expect(find.byType(OnlineBooksHeader), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('online search error retries explicitly in the content area', (tester) async {
        final gateway = _LibraryAcquisitionGateway(failSearch: true);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('Dune Messiah');

        await tester.pumpWidget(buildPage(downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “Dune Messiah”'));
        await tester.pumpAndSettle();

        expect(find.text('Unable to search connected sources'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(gateway.searchQueries, ['Dune Messiah']);

        gateway.failSearch = false;
        await tester.enterText(find.byType(TextField).first, 'Edited query');
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(gateway.searchQueries, ['Dune Messiah', 'Dune Messiah']);
        expect(find.text('Remote result'), findsOneWidget);

        downloadsProvider.dispose();
      });

      testWidgets('renders an orphan placeholder in-place with a Downloading filter', (tester) async {
        final gateway = _LibraryAcquisitionGateway(jobs: [_libraryJob(AcquisitionJobStatus.downloading, bookId: null)]);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();

        final filterChips = tester.widget<LibraryFilterChips>(find.byType(LibraryFilterChips));
        expect(filterChips.showDownloading, isTrue);
        expect(find.textContaining('Downloads'), findsNothing);

        filterChips.onDownloadingTapped!();
        await tester.pumpAndSettle();

        expect(find.byType(AcquisitionPlaceholderCard), findsOneWidget);
        expect(find.byType(BookCard), findsNothing);
        downloadsProvider.dispose();
      });

      testWidgets('renders a linked job once without an orphan duplicate', (tester) async {
        final store = createTestDataStore(
          books: [
            Book(id: 'linked-book', title: 'Linked book', author: 'Author', addedAt: DateTime(2026)),
            Book(id: 'ordinary-book', title: 'Ordinary book', author: 'Author', addedAt: DateTime(2026)),
          ],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(
            jobs: [
              _libraryJob(
                AcquisitionJobStatus.downloading,
                id: 'linked-job',
                bookId: 'linked-book',
                title: 'Linked book',
              ),
            ],
          ),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(800, 1000), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();

        final linkedCards = tester
            .widgetList<BookCard>(find.byType(BookCard))
            .where((card) => card.acquisitionJob?.id == 'linked-job')
            .toList();
        expect(linkedCards, hasLength(1));
        expect(find.byType(BookCard), findsNWidgets(2));
        expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
        expect(find.text('Downloading 0%'), findsOneWidget);

        downloadsProvider.dispose();
      });

      testWidgets('Downloading isolates a linked book and orphan from ordinary books', (tester) async {
        final store = createTestDataStore(
          books: [
            Book(id: 'linked-book', title: 'Linked book', author: 'Author', addedAt: DateTime(2026)),
            Book(id: 'ordinary-book', title: 'Ordinary book', author: 'Author', addedAt: DateTime(2026)),
          ],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(
            jobs: [
              _libraryJob(
                AcquisitionJobStatus.downloading,
                id: 'linked-job',
                bookId: 'linked-book',
                title: 'Linked book',
              ),
              _libraryJob(AcquisitionJobStatus.queued, id: 'orphan-job', bookId: null, title: 'Orphan book'),
            ],
          ),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(800, 1000), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();
        final filterChips = tester.widget<LibraryFilterChips>(find.byType(LibraryFilterChips));
        expect(filterChips.showDownloading, isTrue);

        filterChips.onDownloadingTapped!();
        await tester.pumpAndSettle();

        final visibleCards = tester.widgetList<BookCard>(find.byType(BookCard)).toList();
        final placeholders = tester
            .widgetList<AcquisitionPlaceholderCard>(find.byType(AcquisitionPlaceholderCard))
            .toList();
        expect(visibleCards, hasLength(1));
        expect(visibleCards.single.book.id, 'linked-book');
        expect(placeholders, hasLength(1));
        expect(placeholders.single.job.id, 'orphan-job');
        expect(find.text('Ordinary book'), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('list view integrates linked and orphan jobs without duplication', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        final store = createTestDataStore(
          books: [
            Book(id: 'linked-book', title: 'Linked book', author: 'Author', addedAt: DateTime(2026)),
            Book(id: 'ordinary-book', title: 'Ordinary book', author: 'Author', addedAt: DateTime(2026)),
          ],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(
            jobs: [
              _libraryJob(
                AcquisitionJobStatus.downloading,
                id: 'linked-job',
                bookId: 'linked-book',
                title: 'Linked book',
              ),
              _libraryJob(AcquisitionJobStatus.queued, id: 'orphan-job', bookId: null, title: 'Orphan book'),
            ],
          ),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(800, 1000), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();

        final bookItems = tester.widgetList<BookListItem>(find.byType(BookListItem)).toList();
        final linkedItems = bookItems.where((item) => item.acquisitionJob?.id == 'linked-job').toList();
        final placeholders = tester
            .widgetList<AcquisitionPlaceholderListItem>(find.byType(AcquisitionPlaceholderListItem))
            .toList();
        expect(bookItems, hasLength(2));
        expect(linkedItems, hasLength(1));
        expect(linkedItems.single.onAcquisitionTap, isNotNull);
        expect(linkedItems.single.onAcquisitionSelectionToggle, isNotNull);
        expect(placeholders, hasLength(1));
        expect(placeholders.single.job.id, 'orphan-job');
        expect(placeholders.single.onTap, isNotNull);
        expect(placeholders.single.onEnterSelectionMode, isNotNull);
        expect(find.byType(AcquisitionPlaceholderCard), findsNothing);

        linkedItems.single.onAcquisitionTap!();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('acquisition-job-details-content')), findsOneWidget);

        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        final orphanItem = tester.widget<AcquisitionPlaceholderListItem>(find.byType(AcquisitionPlaceholderListItem));
        orphanItem.onTap!();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('acquisition-job-details-content')), findsOneWidget);

        downloadsProvider.dispose();
      });

      testWidgets('download selection stays separate and shows only valid cancel action', (tester) async {
        final gateway = _LibraryAcquisitionGateway(jobs: [_libraryJob(AcquisitionJobStatus.downloading, bookId: null)]);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        final filterChips = tester.widget<LibraryFilterChips>(find.byType(LibraryFilterChips));
        expect(filterChips.showDownloading, isTrue);
        filterChips.onDownloadingTapped!();
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();

        expect(find.byType(SelectionHeader), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Try again'), findsNothing);
        expect(find.text('Remove'), findsNothing);
        expect(libraryProvider.isSelectionMode, isFalse);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Cancel downloads').last);
        await tester.pumpAndSettle();

        expect(gateway.cancelledJobIds, ['job-1']);
        expect(downloadsProvider.selectedJobIds, isEmpty);

        downloadsProvider.dispose();
      });

      testWidgets('failed bulk cancellation shows a safe message and retains selection', (tester) async {
        final gateway = _LibraryAcquisitionGateway(
          jobs: [_libraryJob(AcquisitionJobStatus.downloading, bookId: null)],
          cancelError: StateError('raw cancel failure at https://client.invalid?token=secret'),
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel downloads').last);
        await tester.pumpAndSettle();

        expect(find.text('Could not cancel the download. Try again.'), findsOneWidget);
        expect(find.textContaining('client.invalid'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);
        expect(downloadsProvider.selectedJobIds, {'job-1'});
        expect(find.byType(SelectionHeader), findsOneWidget);

        downloadsProvider.dispose();
      });

      testWidgets('download Select all includes only rendered jobs and keeps valid actions enabled', (tester) async {
        final store = createTestDataStore(
          books: [
            Book(id: 'visible-1', title: 'Visible one', author: 'Author', addedAt: DateTime(2026)),
            Book(id: 'visible-2', title: 'Visible two', author: 'Author', addedAt: DateTime(2026)),
            Book(id: 'hidden', title: 'Hidden', author: 'Author', addedAt: DateTime(2026)),
          ],
        );
        final gateway = _LibraryAcquisitionGateway(
          jobs: [
            _libraryJob(AcquisitionJobStatus.downloading, id: 'visible-job-1', bookId: 'visible-1'),
            _libraryJob(AcquisitionJobStatus.downloading, id: 'visible-job-2', bookId: 'visible-2'),
            _libraryJob(AcquisitionJobStatus.failed, id: 'hidden-job', bookId: 'hidden', retryable: true),
          ],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshJobs();
        libraryProvider.setSearchQuery('Visible');

        await tester.pumpWidget(
          buildPage(screenSize: const Size(1200, 900), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();

        final firstVisibleCard = tester
            .widgetList<BookCard>(find.byType(BookCard))
            .firstWhere((card) => card.acquisitionJob?.id == 'visible-job-1');
        firstVisibleCard.onEnterSelectionMode!();
        await tester.pump();
        await tester.tap(find.text('Select all'));
        await tester.pump();

        expect(downloadsProvider.selectedJobIds, {'visible-job-1', 'visible-job-2'});
        expect(find.text('2 selected'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Cancel'), findsOneWidget);
        expect(find.text('Try again'), findsNothing);
        expect(find.text('Remove'), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('filtering a selected download out of the grid prunes its selection', (tester) async {
        final store = createTestDataStore(
          books: [Book(id: 'linked-book', title: 'Linked book', author: 'Author', addedAt: DateTime(2026))],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(
            jobs: [_libraryJob(AcquisitionJobStatus.downloading, id: 'linked-job', bookId: 'linked-book')],
          ),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(1200, 900), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();

        tester.widget<BookCard>(find.byType(BookCard)).onEnterSelectionMode!();
        await tester.pump();
        expect(downloadsProvider.selectedJobIds, {'linked-job'});

        libraryProvider.addFilter(LibraryFilterType.finished);
        await tester.pump();
        await tester.pump();

        expect(find.byType(BookCard), findsNothing);
        expect(downloadsProvider.selectedJobIds, isEmpty);
        expect(find.byType(SelectionHeader), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('completed linked download is pruned from selection when it stops rendering', (tester) async {
        final jobs = [_libraryJob(AcquisitionJobStatus.downloading, id: 'linked-job', bookId: 'linked-book')];
        final store = createTestDataStore(
          books: [Book(id: 'linked-book', title: 'Linked book', author: 'Author', addedAt: DateTime(2026))],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(jobs: jobs),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(1200, 900), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();

        tester.widget<BookCard>(find.byType(BookCard)).onEnterSelectionMode!();
        await tester.pump();
        expect(downloadsProvider.selectedJobIds, {'linked-job'});

        jobs[0] = _libraryJob(AcquisitionJobStatus.completed, id: 'linked-job', bookId: 'linked-book');
        await downloadsProvider.refreshJobs();
        await tester.pump();
        await tester.pump();

        expect(downloadsProvider.selectedJobIds, isEmpty);
        expect(find.byType(SelectionHeader), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('cancelled download selection offers only Remove after confirmation', (tester) async {
        final gateway = _LibraryAcquisitionGateway(jobs: [_libraryJob(AcquisitionJobStatus.cancelled, bookId: null)]);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();

        expect(find.text('Remove'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
        expect(find.text('Try again'), findsNothing);

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Remove').last);
        await tester.pumpAndSettle();

        expect(gateway.removedJobIds, ['job-1']);

        downloadsProvider.dispose();
      });

      testWidgets('failed bulk removal shows a safe message and retains selection', (tester) async {
        final gateway = _LibraryAcquisitionGateway(
          jobs: [_libraryJob(AcquisitionJobStatus.cancelled, bookId: null)],
          removeError: StateError('raw remove failure at https://client.invalid?token=secret'),
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Remove').last);
        await tester.pumpAndSettle();

        expect(find.text('Could not remove the download. Try again.'), findsOneWidget);
        expect(find.textContaining('client.invalid'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);
        expect(downloadsProvider.selectedJobIds, {'job-1'});
        expect(find.byType(SelectionHeader), findsOneWidget);

        downloadsProvider.dispose();
      });

      testWidgets('returns to ordinary books when the last Downloading item disappears', (tester) async {
        final jobs = [_libraryJob(AcquisitionJobStatus.downloading, bookId: null)];
        final gateway = _LibraryAcquisitionGateway(jobs: jobs);
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(buildPage(screenSize: const Size(800, 1000), downloadsProvider: downloadsProvider));
        await tester.pumpAndSettle();
        final filterChips = tester.widget<LibraryFilterChips>(find.byType(LibraryFilterChips));
        filterChips.onDownloadingTapped!();
        await tester.pumpAndSettle();

        expect(find.byType(BookCard), findsNothing);

        jobs.clear();
        await downloadsProvider.refreshJobs();
        await tester.pumpAndSettle();

        expect(tester.widget<LibraryFilterChips>(find.byType(LibraryFilterChips)).showDownloading, isFalse);
        expect(find.byType(BookCard), findsWidgets);

        downloadsProvider.dispose();
      });

      testWidgets('tapping a placeholder opens the standard live details sheet', (tester) async {
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(jobs: [_libraryJob(AcquisitionJobStatus.downloading, bookId: null)]),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AcquisitionPlaceholderCard));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('acquisition-job-details-content')), findsOneWidget);
        expect(find.text('Remote result'), findsWidgets);
        expect(find.textContaining('client-1'), findsNothing);

        downloadsProvider.dispose();
      });

      testWidgets('retryable failed selection offers Try again and clears selection', (tester) async {
        final gateway = _LibraryAcquisitionGateway(
          jobs: [_libraryJob(AcquisitionJobStatus.failed, bookId: null, retryable: true)],
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();

        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(gateway.retriedJobIds, ['job-1']);
        expect(downloadsProvider.selectedJobIds, isEmpty);

        downloadsProvider.dispose();
      });

      testWidgets('failed bulk retry shows a safe message and retains selection', (tester) async {
        final gateway = _LibraryAcquisitionGateway(
          jobs: [_libraryJob(AcquisitionJobStatus.failed, bookId: null, retryable: true)],
          retryError: StateError('raw retry failure at https://client.invalid?token=secret'),
        );
        final downloadsProvider = AcquisitionDownloadsProvider(gateway: gateway, pollingInterval: Duration.zero);
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(800, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(find.text('Could not retry the download import. Try again.'), findsOneWidget);
        expect(find.textContaining('client.invalid'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);
        expect(downloadsProvider.selectedJobIds, {'job-1'});
        expect(find.byType(SelectionHeader), findsOneWidget);

        downloadsProvider.dispose();
      });

      testWidgets('completed orphan is replaced when its synchronized book arrives', (tester) async {
        final store = createTestDataStore(books: []);
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(
            jobs: [_libraryJob(AcquisitionJobStatus.completed, bookId: 'imported-book')],
          ),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        await downloadsProvider.refreshJobs();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(800, 1000), store: store, downloadsProvider: downloadsProvider),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AcquisitionPlaceholderCard), findsOneWidget);

        await tester.longPress(find.byType(AcquisitionPlaceholderCard));
        await tester.pump();

        expect(downloadsProvider.selectedJobIds, isEmpty);
        expect(find.byType(SelectionHeader), findsNothing);

        store.loadData(
          books: [Book(id: 'imported-book', title: 'Imported book', author: 'Author', addedAt: DateTime(2026))],
        );
        await tester.pumpAndSettle();

        expect(find.byType(AcquisitionPlaceholderCard), findsNothing);
        expect(find.text('Imported book'), findsWidgets);

        downloadsProvider.dispose();
      });

      testWidgets('renders filter chips', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(LibraryFilterChips), findsOneWidget);
      });

      testWidgets('renders hamburger menu button', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.menu), findsOneWidget);
      });

      testWidgets('renders FAB with add icon', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('displays book count', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('5 books'), findsOneWidget);
      });

      testWidgets('displays singular "book" when only 1 book', (tester) async {
        final singleBookStore = createTestDataStore(books: [createTestBooks().first]);
        await tester.pumpWidget(buildPage(store: singleBookStore));
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('renders grid view by default', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(BookCard), findsWidgets);
      });

      testWidgets('renders view mode toggle', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(ViewModeToggle), findsOneWidget);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
        expect(find.byIcon(Icons.view_list), findsOneWidget);
      });

      testWidgets('switches to list view when list mode is selected', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsWidgets);
        expect(find.byType(BookCard), findsNothing);
      });

      testWidgets('shows empty state when no books match filter', (tester) async {
        final emptyStore = createTestDataStore(books: []);
        await tester.pumpWidget(buildPage(store: emptyStore));
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.text('No books found'), findsOneWidget);
        expect(find.text('Try adjusting your filters or add some books'), findsOneWidget);
      });
    });

    // ========================================================================
    // Desktop layout tests
    // ========================================================================

    group('desktop layout', () {
      const desktopSize = Size(1200, 800);

      testWidgets('renders search bar', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(LibrarySearchBar), findsOneWidget);
      });

      testWidgets('typing a search with acquisition ready keeps the desktop layout valid', (tester) async {
        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();

        await tester.pumpWidget(
          buildPage(screenSize: const Size(1590, 1321), downloadsProvider: downloadsProvider, theme: AppTheme.dark),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 't');
        await tester.pump();

        expect(tester.takeException(), isNull);

        await tester.enterText(find.byType(TextField).first, 'Missing title');
        await tester.pump();

        expect(find.text('Search online for “Missing title”'), findsOneWidget);
        expect(tester.takeException(), isNull);

        downloadsProvider.dispose();
      });

      testWidgets('renders filter chips', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(LibraryFilterChips), findsOneWidget);
      });

      testWidgets('renders "Add book" button', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.text('Add book'), findsOneWidget);
      });

      testWidgets('does not render FAB on desktop', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('does not render hamburger menu on desktop', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        // The menu icon should not be in the desktop layout
        // (it's only in the mobile Scaffold drawer button)
        expect(find.byIcon(Icons.menu), findsNothing);
      });

      testWidgets('renders view toggle buttons', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(ViewModeToggle), findsOneWidget);
      });

      testWidgets('shows grid view by default on desktop', (tester) async {
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(BookCard), findsWidgets);
      });

      testWidgets('switches to list view on desktop', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsWidgets);
      });

      testWidgets('shows empty state when no books on desktop', (tester) async {
        final emptyStore = createTestDataStore(books: []);
        await tester.pumpWidget(buildPage(screenSize: desktopSize, store: emptyStore));
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);
      });

      testWidgets('desktop online mode supports the e-ink theme and enlarged text', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1200, 1000);
        addTearDown(tester.view.reset);

        final downloadsProvider = AcquisitionDownloadsProvider(
          gateway: _LibraryAcquisitionGateway(),
          pollingInterval: Duration.zero,
        );
        await downloadsProvider.refreshConfiguration();
        libraryProvider.setSearchQuery('A deliberately long online book query');

        await tester.pumpWidget(
          buildPage(
            screenSize: const Size(1200, 1000),
            store: createTestDataStore(books: []),
            downloadsProvider: downloadsProvider,
            theme: AppTheme.eink,
            textScaler: const TextScaler.linear(2),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search online for “A deliberately long online book query”'));
        await tester.pumpAndSettle();

        expect(find.byType(OnlineBooksHeader), findsOneWidget);
        expect(find.byType(OnlineResultsView), findsOneWidget);
        expect(find.text('Remote result'), findsOneWidget);
        expect(tester.takeException(), isNull);

        downloadsProvider.dispose();
      });
    });

    // ========================================================================
    // Filtering tests
    // ========================================================================

    group('filtering', () {
      testWidgets('shows all books by default', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('5 books'), findsOneWidget);
      });

      testWidgets('filters to reading books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.reading);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 2 books are reading: The Hobbit and Neuromancer
        expect(find.text('2 books'), findsOneWidget);
      });

      testWidgets('filters to favorite books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.favorites);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 2 books are favorites: The Hobbit and Foundation
        expect(find.text('2 books'), findsOneWidget);
      });

      testWidgets('filters to finished books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.finished);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 1 book is finished: Dune
        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('filters to unread books', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.unread);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // 2 books are unread: 1984 and Foundation
        expect(find.text('2 books'), findsOneWidget);
      });

      testWidgets('shows empty state when no books match filter', (tester) async {
        // Add a filter and clear all books
        libraryProvider.addFilter(LibraryFilterType.reading);
        final storeWithNoReadingBooks = createTestDataStore(
          books: [
            Book(
              id: 'book-1',
              title: 'Test Book',
              author: 'Test Author',
              readingStatus: ReadingStatus.notStarted,
              addedAt: DateTime.now(),
            ),
          ],
        );
        await tester.pumpWidget(buildPage(store: storeWithNoReadingBooks));
        await tester.pumpAndSettle();

        expect(find.text('0 books'), findsOneWidget);
        expect(find.byType(EmptyState), findsOneWidget);
      });

      testWidgets('search filter works with text', (tester) async {
        libraryProvider.setSearchQuery('Hobbit');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('search filter works with author field', (tester) async {
        libraryProvider.setSearchQuery('author:Tolkien');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('filters by shelf', (tester) async {
        // Add a book-shelf relation
        dataStore.addBookToShelf('book-1', 'shelf-1');
        libraryProvider.selectShelf('Fiction');

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('filters by topic', (tester) async {
        // Add a book-tag relation
        dataStore.addTagToBook('book-1', 'tag-1');
        libraryProvider.selectTopic('Fantasy');

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('1 book'), findsOneWidget);
      });
    });

    // ========================================================================
    // View mode interaction tests
    // ========================================================================

    group('view mode switching', () {
      testWidgets('toggling view mode on mobile updates the display', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Initially in grid view
        expect(find.byType(BookCard), findsWidgets);

        // Switch to list view
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsWidgets);
        expect(find.byType(BookCard), findsNothing);
      });

      testWidgets('tapping grid segment on mobile selects grid view', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Tap the grid view segment
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(libraryProvider.viewMode, LibraryViewMode.grid);
      });

      testWidgets('tapping list segment on mobile selects list view', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Tap the list view segment
        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pumpAndSettle();

        expect(libraryProvider.viewMode, LibraryViewMode.list);
      });

      testWidgets('tapping toggle on desktop switches view mode', (tester) async {
        const desktopSize = Size(1200, 800);
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        // Tap the list view toggle
        expect(find.byType(ViewModeToggle), findsOneWidget);

        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pumpAndSettle();

        expect(libraryProvider.viewMode, LibraryViewMode.list);
      });
    });

    // ========================================================================
    // List view specific tests
    // ========================================================================

    group('list view', () {
      testWidgets('list view shows items', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // ListView.builder lazily builds items, so not all may be visible
        expect(find.byType(BookListItem), findsAtLeastNWidgets(1));
        expect(find.byType(ListView), findsAtLeastNWidgets(1));
      });

      testWidgets('list view respects favorite override', (tester) async {
        libraryProvider.setViewMode(LibraryViewMode.list);
        // Toggle favorite for book-3 (originally not favorite)
        libraryProvider.toggleFavorite('book-3', false);

        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // At least some favorite icons should be filled
        expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
      });

      testWidgets('list view on desktop shows items', (tester) async {
        const desktopSize = Size(1200, 800);
        libraryProvider.setViewMode(LibraryViewMode.list);
        await tester.pumpWidget(buildPage(screenSize: desktopSize));
        await tester.pumpAndSettle();

        expect(find.byType(BookListItem), findsAtLeastNWidgets(1));
      });
    });

    // ========================================================================
    // Mobile drawer interaction
    // ========================================================================

    group('mobile drawer', () {
      testWidgets('opens drawer when hamburger menu is tapped', (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Drawer should be open - verify drawer items are visible
        expect(find.text('Books'), findsOneWidget);
        expect(find.text('Shelves'), findsOneWidget);
      });
    });

    // ========================================================================
    // Desktop compact layout
    // ========================================================================

    group('desktop compact layout', () {
      testWidgets('uses compact layout at narrow desktop width', (tester) async {
        // 850px is >= desktopSmall (840) but < 800 in maxWidth
        // after padding. Let's use exactly 860 to trigger desktop
        // but be narrow enough for compact layout.
        const narrowDesktop = Size(860, 800);
        await tester.pumpWidget(buildPage(screenSize: narrowDesktop));
        await tester.pumpAndSettle();

        // Should still show search bar
        expect(find.byType(LibrarySearchBar), findsOneWidget);
      });

      testWidgets('uses normal row layout at wide desktop', (tester) async {
        const wideDesktop = Size(1400, 800);
        await tester.pumpWidget(buildPage(screenSize: wideDesktop));
        await tester.pumpAndSettle();

        expect(find.text('Add book'), findsOneWidget);
      });
    });

    // ========================================================================
    // Multiple filter combinations
    // ========================================================================

    group('combined filters', () {
      testWidgets('reading + favorites shows intersection', (tester) async {
        libraryProvider.addFilter(LibraryFilterType.reading);
        libraryProvider.addFilter(LibraryFilterType.favorites);
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Only The Hobbit is both reading and favorite
        expect(find.text('1 book'), findsOneWidget);
      });

      testWidgets('empty search query shows all books', (tester) async {
        libraryProvider.setSearchQuery('');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        expect(find.text('5 books'), findsOneWidget);
      });
    });
  });
}

class _ControlledBookRepository implements BookRepository {
  final StreamController<List<Book>> controller = StreamController<List<Book>>.broadcast();

  @override
  Stream<List<Book>> watchAll() => controller.stream;

  @override
  Future<Book?> getById(String id) async => null;

  @override
  Future<void> upsert(Book book) async {}

  @override
  Future<void> delete(String id) async {}
}

class _TrackingDownloadsProvider extends AcquisitionDownloadsProvider {
  _TrackingDownloadsProvider({required AcquisitionDownloadsGateway gateway})
    : super(gateway: gateway, pollingInterval: Duration.zero);

  final List<bool> libraryVisibility = [];

  @override
  void setLibraryVisible(bool visible) {
    libraryVisibility.add(visible);
    super.setLibraryVisible(visible);
  }
}

class _LibraryAcquisitionGateway implements AcquisitionDownloadsGateway {
  final List<AcquisitionJob> jobs;
  final String? submissionError;
  final int releaseCount;
  final int clientCount;
  final Completer<List<TorrentRelease>>? searchCompleter;
  final Completer<BatchSubmissionResponse>? submissionCompleter;
  final List<Object> _searchResponses;
  final Set<int> failedSubmissionIndexes;
  final Object? cancelError;
  final Object? retryError;
  final Object? removeError;
  bool failSearch;
  List<String> submittedTokens = [];
  String? submittedEndpointId;
  final List<String> searchQueries = [];
  final List<String> cancelledJobIds = [];
  final List<String> retriedJobIds = [];
  final List<String> removedJobIds = [];

  _LibraryAcquisitionGateway({
    this.jobs = const [],
    this.submissionError,
    this.releaseCount = 1,
    this.clientCount = 1,
    this.searchCompleter,
    this.submissionCompleter,
    List<Object> searchResponses = const [],
    this.failedSubmissionIndexes = const {},
    this.cancelError,
    this.retryError,
    this.removeError,
    this.failSearch = false,
  }) : _searchResponses = [...searchResponses];

  @override
  Future<List<AcquisitionEndpoint>> listEndpoints() async => [
    AcquisitionEndpoint(
      id: 'indexer-1',
      name: 'Prowlarr',
      kind: AcquisitionEndpointKind.prowlarr,
      baseUrl: Uri.parse('http://prowlarr.local'),
      enabled: true,
    ),
    for (var index = 1; index <= clientCount; index += 1)
      AcquisitionEndpoint(
        id: 'client-$index',
        name: 'Download client $index',
        kind: AcquisitionEndpointKind.qbittorrent,
        baseUrl: Uri.parse('http://client-$index.local'),
        downloadRoot: '/downloads/$index',
        enabled: true,
      ),
  ];

  @override
  Future<AcquisitionJobPage> listJobs({int limit = 50, int offset = 0}) async {
    return AcquisitionJobPage(items: jobs, total: jobs.length, limit: 50, offset: 0);
  }

  @override
  Future<List<TorrentRelease>> search(String query, {List<String>? endpointIds}) async {
    searchQueries.add(query);

    if (failSearch) {
      throw StateError('raw source failure');
    }

    if (_searchResponses.isNotEmpty) {
      final response = _searchResponses.removeAt(0);

      if (response is Future<List<TorrentRelease>>) {
        return response;
      }
      if (response is List<TorrentRelease>) {
        return response;
      }

      throw response;
    }

    if (searchCompleter case final completer?) {
      return completer.future;
    }

    return [
      for (var index = 1; index <= releaseCount; index += 1)
        TorrentRelease(
          title: index == 1 ? 'Remote result' : 'Remote result $index',
          releaseToken: index == 1 ? 'release-token' : 'release-token-$index',
          protocol: 'torrent',
          indexer: 'Prowlarr',
          seeders: 12,
          sizeBytes: 2048,
          formatHints: const ['epub'],
        ),
    ];
  }

  @override
  Future<BatchSubmissionResponse> submitReleaseBatch({
    required String endpointId,
    required List<TorrentRelease> releases,
  }) async {
    submittedTokens = releases.map((release) => release.releaseToken).toList();
    submittedEndpointId = endpointId;

    if (submissionCompleter case final completer?) {
      return completer.future;
    }

    return BatchSubmissionResponse(
      items: [
        for (var index = 0; index < releases.length; index += 1)
          BatchSubmissionItem(
            index: index,
            job: submissionError == null && !failedSubmissionIndexes.contains(index)
                ? _libraryJob(
                    AcquisitionJobStatus.submitted,
                    id: 'submitted-job-$index',
                    bookId: null,
                    title: releases[index].title,
                  )
                : null,
            error:
                submissionError ??
                (failedSubmissionIndexes.contains(index) ? 'raw token failure at https://client.invalid' : null),
          ),
      ],
    );
  }

  @override
  Future<List<AcquisitionFileCandidate>> listJobFiles(String jobId) async => const [];

  @override
  Future<AcquisitionJob> selectJobFile(String jobId, int fileIndex) async {
    return _libraryJob(AcquisitionJobStatus.downloading);
  }

  @override
  Future<AcquisitionJob> cancelJob(String jobId) async {
    if (cancelError case final error?) {
      throw error;
    }

    cancelledJobIds.add(jobId);

    return _libraryJob(AcquisitionJobStatus.cancelled);
  }

  @override
  Future<AcquisitionJob> retryJobImport(String jobId) async {
    if (retryError case final error?) {
      throw error;
    }

    retriedJobIds.add(jobId);

    return _libraryJob(AcquisitionJobStatus.downloading);
  }

  @override
  Future<void> removeJob(String jobId) async {
    if (removeError case final error?) {
      throw error;
    }

    removedJobIds.add(jobId);
  }

  @override
  void close() {}
}

AcquisitionJob _libraryJob(
  AcquisitionJobStatus status, {
  String id = 'job-1',
  String? bookId = 'book-1',
  String title = 'Remote result',
  bool retryable = false,
}) {
  return AcquisitionJob(
    id: id,
    endpointId: 'client-1',
    ruleId: null,
    bookId: bookId,
    title: title,
    status: status,
    clientReference: null,
    clientHash: null,
    clientState: null,
    progressBasisPoints: 0,
    downloadedBytes: 0,
    totalBytes: null,
    downloadSpeedBytesPerSecond: null,
    etaSeconds: null,
    selectedFilePath: null,
    retryCount: 0,
    error: null,
    nextPollAt: null,
    createdAt: null,
    updatedAt: null,
    submittedAt: retryable ? DateTime(2026) : null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
  );
}
