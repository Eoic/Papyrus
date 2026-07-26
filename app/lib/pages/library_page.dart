import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/active_filter.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/bulk_book_actions.dart';
import 'package:papyrus/utils/search_query_parser.dart';
import 'package:papyrus/widgets/filter/filter_bottom_sheet.dart';
import 'package:papyrus/widgets/filter/filter_dialog.dart';
import 'package:papyrus/widgets/library/acquisition_confirmation_dialog.dart';
import 'package:papyrus/widgets/library/book_grid.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/acquisition_job_sheets.dart';
import 'package:papyrus/widgets/library/acquisition_job_visibility.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_list_item.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/library/online_books_header.dart';
import 'package:papyrus/widgets/library/online_results_view.dart';
import 'package:papyrus/widgets/library/selection_header.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/add_book/add_book_choice_sheet.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';
import 'package:provider/provider.dart';

/// Main library page with responsive layouts for all platforms.
/// - Mobile: AppBar with search, filter chips, 2-column grid, FAB
/// - Desktop: Header row, filter chips, 5-column grid or list view
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

enum _BooksPresentationMode { local, online }

class _AcquisitionLibraryView {
  const _AcquisitionLibraryView({required this.books, required this.placeholderJobs, required this.selectableJobs});

  final List<Book> books;
  final List<AcquisitionJob> placeholderJobs;
  final List<AcquisitionJob> selectableJobs;
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AcquisitionDownloadsProvider? _visibleDownloadsProvider;
  _BooksPresentationMode _presentationMode = _BooksPresentationMode.local;
  bool _showDownloadingOnly = false;
  int _presentationGeneration = 0;
  late final TextEditingController _onlineSearchController;

  @override
  void initState() {
    super.initState();
    _onlineSearchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AcquisitionDownloadsProvider?>();

    if (!identical(provider, _visibleDownloadsProvider)) {
      _presentationGeneration += 1;
      _visibleDownloadsProvider?.setLibraryVisible(false);
      _visibleDownloadsProvider = provider;
      provider?.setLibraryVisible(true);
    }
  }

  @override
  void dispose() {
    _visibleDownloadsProvider?.setLibraryVisible(false);
    _onlineSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final downloadsProvider = context.watch<AcquisitionDownloadsProvider?>();
    final dataStore = context.watch<DataStore>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    // Get filtered books from DataStore (single source of truth)
    final books = _getFilteredBooks(libraryProvider, dataStore);
    final isLoading = !dataStore.isLoaded;

    if (isDesktop) {
      return _buildDesktopLayout(context, books, dataStore, libraryProvider, downloadsProvider, isLoading);
    }

    return _buildMobileLayout(context, books, dataStore, libraryProvider, downloadsProvider, isLoading);
  }

  List<Book> _getFilteredBooks(LibraryProvider provider, DataStore dataStore) {
    var books = dataStore.books;

    // Apply search filter using query parser
    if (provider.searchQuery.isNotEmpty) {
      final searchQuery = SearchQueryParser.parse(provider.searchQuery);
      if (searchQuery.isNotEmpty) {
        books = books.where((book) => searchQuery.matches(book, dataStore: dataStore)).toList();
      }
    }

    // Apply category filters (quick filters from chips)
    if (!provider.isFilterActive(LibraryFilterType.all)) {
      if (provider.isFilterActive(LibraryFilterType.favorites)) {
        books = books.where((book) => provider.isBookFavorite(book.id, book.isFavorite)).toList();
      }
      if (provider.isFilterActive(LibraryFilterType.reading)) {
        books = books.where((book) => book.isReading).toList();
      }
      if (provider.isFilterActive(LibraryFilterType.finished)) {
        books = books.where((book) => book.isFinished).toList();
      }
      if (provider.isFilterActive(LibraryFilterType.unread)) {
        books = books.where((book) => book.readingStatus == ReadingStatus.notStarted).toList();
      }
      if (provider.isFilterActive(LibraryFilterType.shelves) && provider.selectedShelf != null) {
        books = books
            .where((book) => dataStore.getShelvesForBook(book.id).any((s) => s.name == provider.selectedShelf))
            .toList();
      }
      if (provider.isFilterActive(LibraryFilterType.topics) && provider.selectedTopic != null) {
        books = books
            .where((book) => dataStore.getTagsForBook(book.id).any((t) => t.name == provider.selectedTopic))
            .toList();
      }
    }

    return provider.sortBooks(books);
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    List<Book> books,
    DataStore dataStore,
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    bool isLoading,
  ) {
    final isOnline = _presentationMode == _BooksPresentationMode.online && downloadsProvider != null;
    final isBookSelection = libraryProvider.isSelectionMode;
    final localItems = buildAcquisitionLibraryItems(books: dataStore.books, jobs: downloadsProvider?.jobs ?? const []);
    final showDownloadingOnly = _showDownloadingOnly && localItems.hasDownloadingItems;
    final acquisitionView = _buildAcquisitionLibraryView(
      books: books,
      items: localItems,
      libraryProvider: libraryProvider,
      showDownloadingOnly: showDownloadingOnly,
    );
    final selectedJobs = _visibleSelectedJobs(downloadsProvider, acquisitionView.selectableJobs);
    final hasJobSelection = selectedJobs.isNotEmpty;
    final hideLocalControls = isOnline || hasJobSelection || isBookSelection;
    _pruneHiddenJobSelection(downloadsProvider, acquisitionView.selectableJobs);
    _clearUnavailableDownloadingFilter(localItems);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header: selection header or normal header
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md, left: Spacing.md, right: Spacing.md),
              child: isOnline
                  ? _buildOnlineHeader(downloadsProvider)
                  : hasJobSelection
                  ? _buildJobSelectionHeader(
                      downloadsProvider!,
                      selectableJobs: acquisitionView.selectableJobs,
                      includeActions: false,
                    )
                  : isBookSelection
                  ? SelectionHeader(
                      selectedCount: libraryProvider.selectedCount,
                      totalCount: books.length,
                      onClose: libraryProvider.exitSelectionMode,
                      onSelectAll: () => libraryProvider.selectAll(books.map((b) => b.id).toList()),
                      onDeselectAll: libraryProvider.deselectAll,
                    )
                  : Row(
                      children: [
                        // Drawer hamburger button
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          tooltip: 'Library sections',
                        ),
                        const SizedBox(width: Spacing.xs),
                        // Search bar
                        Expanded(child: _buildSearchBar(libraryProvider)),
                        const SizedBox(width: Spacing.sm),
                        _buildSortButton(libraryProvider),
                      ],
                    ),
            ),

            // Quick filter chips
            if (!isOnline)
              LibraryFilterChips(
                showDownloading: localItems.hasDownloadingItems,
                isDownloadingSelected: showDownloadingOnly,
                onDownloadingTapped: () => setState(() => _showDownloadingOnly = true),
                onLibraryFilterTapped: () {
                  if (_showDownloadingOnly) {
                    setState(() => _showDownloadingOnly = false);
                  }
                },
              ),

            // View toggle row
            if (!hideLocalControls)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.md, right: Spacing.md, bottom: Spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLoading ? 'Loading books…' : '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    _buildViewToggle(libraryProvider),
                  ],
                ),
              ),

            // Book grid or list
            Expanded(child: _buildBookContent(context, libraryProvider, downloadsProvider, isLoading, acquisitionView)),
          ],
        ),
      ),
      floatingActionButton: hideLocalControls
          ? null
          : FloatingActionButton(onPressed: () => _showAddBook(downloadsProvider), child: const Icon(Icons.add)),
      bottomNavigationBar: isOnline && downloadsProvider.selectedReleaseTokens.isNotEmpty
          ? _buildMobileOnlineAction(downloadsProvider)
          : hasJobSelection
          ? _buildMobileJobActions(downloadsProvider!, selectedJobs)
          : isBookSelection
          ? buildMobileBottomActionBar(context, libraryProvider)
          : null,
    );
  }

  /// Build list of active filters for display.
  /// Uses a Set to prevent duplicate filters.
  /// Quick filters (Reading, Favorites, Finished) are excluded because they
  /// are already shown as highlighted buttons in the QuickFilterChips bar.
  List<ActiveFilter> _buildActiveFilters(LibraryProvider provider) {
    final filters = <ActiveFilter>{};

    if (provider.selectedShelf != null) {
      filters.add(
        ActiveFilter(
          type: ActiveFilterType.query,
          label: 'shelf',
          value: provider.selectedShelf!,
          queryString: 'shelf:"${provider.selectedShelf}"',
        ),
      );
    }
    if (provider.selectedTopic != null) {
      filters.add(
        ActiveFilter(
          type: ActiveFilterType.query,
          label: 'topic',
          value: provider.selectedTopic!,
          queryString: 'topic:"${provider.selectedTopic}"',
        ),
      );
    }

    // Parse search query into individual filters
    // Skip shelf/topic if already added from provider to avoid duplicates
    if (provider.searchQuery.isNotEmpty && provider.searchQuery.contains(':')) {
      final query = SearchQueryParser.parse(provider.searchQuery);
      for (final filter in query.filters) {
        if (filter.field.name != 'any') {
          // Skip if this field is already represented by provider selection
          if (filter.field.name == 'shelf' && provider.selectedShelf != null) {
            continue;
          }
          if (filter.field.name == 'topic' && provider.selectedTopic != null) {
            continue;
          }
          filters.add(
            ActiveFilter(
              type: ActiveFilterType.query,
              label: filter.field.name,
              value: filter.value,
              queryString: '${filter.field.name}:${filter.value}',
            ),
          );
        }
      }
    }

    return filters.toList();
  }

  /// Show the filter bottom sheet.
  Future<void> _showFilterBottomSheet(BuildContext context) async {
    final libraryProvider = context.read<LibraryProvider>();
    final dataStore = context.read<DataStore>();
    final filterOptions = FilterOptions.fromBooks(
      dataStore.books,
      shelfNames: dataStore.shelves.map((s) => s.name).toList(),
      topicNames: dataStore.tags.map((t) => t.name).toList(),
    );

    final result = await FilterBottomSheet.show(
      context,
      filterOptions: filterOptions,
      initialFilters: AppliedFilters.fromQueryString(
        libraryProvider.searchQuery,
        filterReading: libraryProvider.isFilterActive(LibraryFilterType.reading),
        filterFavorites: libraryProvider.isFilterActive(LibraryFilterType.favorites),
        filterFinished: libraryProvider.isFilterActive(LibraryFilterType.finished),
        filterUnread: libraryProvider.isFilterActive(LibraryFilterType.unread),
        shelf: libraryProvider.selectedShelf,
        topic: libraryProvider.selectedTopic,
      ),
    );

    if (result != null) {
      _applyFilterResult(result);
    }
  }

  /// Show the filter dialog (desktop).
  Future<void> _showFilterDialog(BuildContext context) async {
    final libraryProvider = context.read<LibraryProvider>();
    final dataStore = context.read<DataStore>();
    final filterOptions = FilterOptions.fromBooks(
      dataStore.books,
      shelfNames: dataStore.shelves.map((s) => s.name).toList(),
      topicNames: dataStore.tags.map((t) => t.name).toList(),
    );

    final result = await FilterDialog.show(
      context,
      filterOptions: filterOptions,
      initialFilters: AppliedFilters.fromQueryString(
        libraryProvider.searchQuery,
        filterReading: libraryProvider.isFilterActive(LibraryFilterType.reading),
        filterFavorites: libraryProvider.isFilterActive(LibraryFilterType.favorites),
        filterFinished: libraryProvider.isFilterActive(LibraryFilterType.finished),
        filterUnread: libraryProvider.isFilterActive(LibraryFilterType.unread),
        shelf: libraryProvider.selectedShelf,
        topic: libraryProvider.selectedTopic,
      ),
    );
    if (result != null) {
      _applyFilterResult(result);
    }
  }

  /// Apply the filter result from either the bottom sheet or dialog.
  void _applyFilterResult(AppliedFilters result) {
    final libraryProvider = context.read<LibraryProvider>();

    // Apply quick filters
    if (result.filterReading) {
      libraryProvider.addFilter(LibraryFilterType.reading);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.reading);
    }
    if (result.filterFavorites) {
      libraryProvider.addFilter(LibraryFilterType.favorites);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.favorites);
    }
    if (result.filterFinished) {
      libraryProvider.addFilter(LibraryFilterType.finished);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.finished);
    }
    if (result.filterUnread) {
      libraryProvider.addFilter(LibraryFilterType.unread);
    } else {
      libraryProvider.removeFilter(LibraryFilterType.unread);
    }

    // Apply shelf/topic
    libraryProvider.selectShelf(result.shelf);
    libraryProvider.selectTopic(result.topic);

    // Set or clear search query from advanced filters
    final queryString = result.toQueryString();
    if (queryString.isNotEmpty) {
      libraryProvider.setSearchQuery(queryString);
    } else {
      libraryProvider.clearSearch();
    }
  }

  Widget _buildSearchBar(LibraryProvider libraryProvider) {
    final activeFilters = _buildActiveFilters(libraryProvider);
    final isDesktop = MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

    return LibrarySearchBar(
      initialQuery: libraryProvider.searchQuery,
      activeFilterCount: activeFilters.length,
      onQueryChanged: (query) {
        if (query.isEmpty) {
          libraryProvider.clearSearch();
        } else {
          libraryProvider.setSearchQuery(query);
        }
      },
      onFilterTap: () => isDesktop ? _showFilterDialog(context) : _showFilterBottomSheet(context),
    );
  }

  void _enterOnlineMode(
    AcquisitionDownloadsProvider provider, {
    String initialQuery = '',
    bool submitImmediately = false,
  }) {
    _presentationGeneration += 1;
    _onlineSearchController.text = initialQuery;
    setState(() => _presentationMode = _BooksPresentationMode.online);

    if (submitImmediately && initialQuery.trim().isNotEmpty) {
      unawaited(provider.searchRemote(initialQuery));
    }
  }

  void _leaveOnlineMode(AcquisitionDownloadsProvider provider) {
    _presentationGeneration += 1;
    provider.clearRemoteResults();
    setState(() => _presentationMode = _BooksPresentationMode.local);
  }

  void _showAddBook(AcquisitionDownloadsProvider? provider) {
    AddBookChoiceSheet.show(
      context,
      onFindOnline: provider?.isManagedAcquisitionReady == true ? () => _enterOnlineMode(provider!) : null,
    );
  }

  Widget _buildOnlineHeader(AcquisitionDownloadsProvider provider) {
    if (provider.selectedReleaseTokens.isNotEmpty) {
      final isDesktop = MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

      return SelectionHeader(
        selectedCount: provider.selectedReleaseTokens.length,
        totalCount: provider.remoteResults.length,
        onClose: provider.clearReleaseSelection,
        onSelectAll: provider.selectAllRemoteReleases,
        onDeselectAll: provider.clearReleaseSelection,
        actions: isDesktop
            ? FilledButton.icon(
                onPressed: provider.isSubmitting ? null : () => _submitSelected(provider),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download'),
              )
            : null,
      );
    }

    return OnlineBooksHeader(
      controller: _onlineSearchController,
      autofocus: provider.remoteQuery == null && _onlineSearchController.text.isEmpty,
      isSearching: provider.isSearching,
      onBack: () => _leaveOnlineMode(provider),
      onSearch: provider.searchRemote,
    );
  }

  Widget _buildMobileOnlineAction(AcquisitionDownloadsProvider provider) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: FilledButton.icon(
          onPressed: provider.isSubmitting ? null : () => _submitSelected(provider),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download'),
        ),
      ),
    );
  }

  Future<void> _submitSelected(AcquisitionDownloadsProvider provider) async {
    final presentationGeneration = _presentationGeneration;
    final libraryProvider = context.read<LibraryProvider>();
    final clients = provider.downloadClients;
    final client = clients.length == 1 ? clients.single : await _chooseDownloadClient(clients);

    if (client == null || !_isCurrentOnlinePresentation(provider, presentationGeneration)) {
      return;
    }

    final outcome = await provider.submitSelectedReleases(client.id);

    if (!_isCurrentOnlinePresentation(provider, presentationGeneration)) {
      return;
    }

    if (outcome.allSucceeded) {
      libraryProvider.clearSearch();
      _leaveOnlineMode(provider);
    }
  }

  bool _isCurrentOnlinePresentation(AcquisitionDownloadsProvider provider, int presentationGeneration) {
    return mounted &&
        presentationGeneration == _presentationGeneration &&
        _presentationMode == _BooksPresentationMode.online &&
        identical(provider, _visibleDownloadsProvider);
  }

  Future<AcquisitionEndpoint?> _chooseDownloadClient(List<AcquisitionEndpoint> clients) {
    if (clients.isEmpty) {
      return Future.value();
    }

    return showModalBottomSheet<AcquisitionEndpoint>(
      context: context,
      useSafeArea: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.md),
            Text('Download with', style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: Spacing.sm),
            for (final client in clients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_outlined),
                title: Text(client.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(sheetContext).pop(client),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobSelectionHeader(
    AcquisitionDownloadsProvider provider, {
    required List<AcquisitionJob> selectableJobs,
    required bool includeActions,
  }) {
    final selectedJobs = _visibleSelectedJobs(provider, selectableJobs);

    return SelectionHeader(
      selectedCount: selectedJobs.length,
      totalCount: selectableJobs.length,
      onClose: provider.clearJobSelection,
      onSelectAll: () => provider.selectJobs(selectableJobs.map((job) => job.id)),
      onDeselectAll: provider.clearJobSelection,
      actions: includeActions ? _buildJobActions(provider, selectedJobs) : null,
    );
  }

  Widget _buildJobActions(AcquisitionDownloadsProvider provider, List<AcquisitionJob> selectedJobs) {
    final canCancel = selectedJobs.isNotEmpty && selectedJobs.every((job) => job.canCancel);
    final canRetry = selectedJobs.isNotEmpty && selectedJobs.every((job) => job.canRetryImport);
    final canRemove =
        selectedJobs.isNotEmpty &&
        selectedJobs.every(
          (job) => job.status == AcquisitionJobStatus.cancelled || job.status == AcquisitionJobStatus.failed,
        );

    return Wrap(
      spacing: Spacing.sm,
      children: [
        if (canCancel)
          FilledButton.icon(
            onPressed: provider.isMutatingJobs ? null : () => _cancelSelectedJobs(provider, selectedJobs),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Cancel'),
          ),
        if (canRetry)
          FilledButton.icon(
            onPressed: provider.isMutatingJobs ? null : () => _retrySelectedJobs(provider, selectedJobs),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        if (canRemove)
          FilledButton.icon(
            onPressed: provider.isMutatingJobs ? null : () => _removeSelectedJobs(provider, selectedJobs),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
      ],
    );
  }

  Widget _buildMobileJobActions(AcquisitionDownloadsProvider provider, List<AcquisitionJob> selectedJobs) {
    return SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.all(Spacing.md), child: _buildJobActions(provider, selectedJobs)),
    );
  }

  Future<void> _cancelSelectedJobs(AcquisitionDownloadsProvider provider, List<AcquisitionJob> selectedJobs) async {
    final presentationGeneration = _presentationGeneration;
    final confirmed = await showAcquisitionConfirmationDialog(
      context: context,
      title: 'Cancel downloads',
      message: 'Cancel ${selectedJobs.length} selected ${selectedJobs.length == 1 ? 'download' : 'downloads'}?',
      actionLabel: 'Cancel downloads',
    );

    if (confirmed && _isCurrentLocalPresentation(provider, presentationGeneration)) {
      final outcome = await provider.cancelSelectedJobs();
      _showJobActionFailure(provider, presentationGeneration, outcome);
    }
  }

  Future<void> _retrySelectedJobs(AcquisitionDownloadsProvider provider, List<AcquisitionJob> selectedJobs) async {
    final presentationGeneration = _presentationGeneration;
    provider.retainJobSelection(selectedJobs.map((job) => job.id).toSet());
    final outcome = await provider.retrySelectedJobs();
    _showJobActionFailure(provider, presentationGeneration, outcome);
  }

  Future<void> _removeSelectedJobs(AcquisitionDownloadsProvider provider, List<AcquisitionJob> selectedJobs) async {
    final presentationGeneration = _presentationGeneration;
    final confirmed = await showAcquisitionConfirmationDialog(
      context: context,
      title: 'Remove downloads',
      message: 'Remove ${selectedJobs.length} selected ${selectedJobs.length == 1 ? 'download' : 'downloads'}?',
      actionLabel: 'Remove',
    );

    if (confirmed && _isCurrentLocalPresentation(provider, presentationGeneration)) {
      final outcome = await provider.removeSelectedJobs();
      _showJobActionFailure(provider, presentationGeneration, outcome);
    }
  }

  bool _isCurrentLocalPresentation(AcquisitionDownloadsProvider provider, int presentationGeneration) {
    return mounted &&
        presentationGeneration == _presentationGeneration &&
        _presentationMode == _BooksPresentationMode.local &&
        identical(provider, _visibleDownloadsProvider);
  }

  void _showJobActionFailure(
    AcquisitionDownloadsProvider provider,
    int presentationGeneration,
    AcquisitionJobActionOutcome outcome,
  ) {
    final message = outcome.error;

    if (message == null || !_isCurrentLocalPresentation(provider, presentationGeneration)) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildViewToggle(LibraryProvider libraryProvider) {
    return ViewModeToggle(
      isGridView: libraryProvider.isGridView,
      onChanged: (isGrid) => libraryProvider.setViewMode(isGrid ? LibraryViewMode.grid : LibraryViewMode.list),
    );
  }

  Widget _buildAddBookButton(double height, AcquisitionDownloadsProvider? downloadsProvider) {
    return FilledButton.icon(
      onPressed: () => _showAddBook(downloadsProvider),
      icon: const Icon(Icons.add),
      label: const Text('Add book'),
      style: FilledButton.styleFrom(minimumSize: Size(0, height)),
    );
  }

  Widget _buildSortButton(LibraryProvider provider) {
    return PopupMenuButton<LibrarySortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort books',
      onSelected: provider.setSortOption,
      itemBuilder: (context) => [
        _buildSortMenuItem(LibrarySortOption.dateAddedNewest, 'Date added (newest)', provider.sortOption),
        _buildSortMenuItem(LibrarySortOption.dateAddedOldest, 'Date added (oldest)', provider.sortOption),
        const PopupMenuDivider(),
        _buildSortMenuItem(LibrarySortOption.titleAZ, 'Title (A\u2013Z)', provider.sortOption),
        _buildSortMenuItem(LibrarySortOption.titleZA, 'Title (Z\u2013A)', provider.sortOption),
        const PopupMenuDivider(),
        _buildSortMenuItem(LibrarySortOption.authorAZ, 'Author (A\u2013Z)', provider.sortOption),
        _buildSortMenuItem(LibrarySortOption.authorZA, 'Author (Z\u2013A)', provider.sortOption),
        const PopupMenuDivider(),
        _buildSortMenuItem(LibrarySortOption.lastRead, 'Last read', provider.sortOption),
        _buildSortMenuItem(LibrarySortOption.rating, 'Rating', provider.sortOption),
        _buildSortMenuItem(LibrarySortOption.progress, 'Progress', provider.sortOption),
      ],
    );
  }

  PopupMenuItem<LibrarySortOption> _buildSortMenuItem(
    LibrarySortOption option,
    String label,
    LibrarySortOption current,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == current ? Theme.of(context).colorScheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<Book> books,
    DataStore dataStore,
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    bool isLoading,
  ) {
    const double controlHeight = 40.0;
    final isOnline = _presentationMode == _BooksPresentationMode.online && downloadsProvider != null;
    final isBookSelection = libraryProvider.isSelectionMode;
    final localItems = buildAcquisitionLibraryItems(books: dataStore.books, jobs: downloadsProvider?.jobs ?? const []);
    final showDownloadingOnly = _showDownloadingOnly && localItems.hasDownloadingItems;
    final acquisitionView = _buildAcquisitionLibraryView(
      books: books,
      items: localItems,
      libraryProvider: libraryProvider,
      showDownloadingOnly: showDownloadingOnly,
    );
    final selectedJobs = _visibleSelectedJobs(downloadsProvider, acquisitionView.selectableJobs);
    final hasJobSelection = selectedJobs.isNotEmpty;
    _pruneHiddenJobSelection(downloadsProvider, acquisitionView.selectableJobs);
    _clearUnavailableDownloadingFilter(localItems);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (isOnline) {
            if (downloadsProvider.selectedReleaseTokens.isNotEmpty) {
              downloadsProvider.clearReleaseSelection();
            } else {
              _leaveOnlineMode(downloadsProvider);
            }
          } else if (hasJobSelection) {
            downloadsProvider?.clearJobSelection();
          } else if (libraryProvider.isSelectionMode) {
            libraryProvider.exitSelectionMode();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.only(top: Spacing.lg, left: Spacing.lg, right: Spacing.lg),
                child: isOnline
                    ? _buildOnlineHeader(downloadsProvider)
                    : hasJobSelection
                    ? _buildJobSelectionHeader(
                        downloadsProvider!,
                        selectableJobs: acquisitionView.selectableJobs,
                        includeActions: true,
                      )
                    : isBookSelection
                    ? SelectionHeader(
                        selectedCount: libraryProvider.selectedCount,
                        totalCount: books.length,
                        onClose: libraryProvider.exitSelectionMode,
                        onSelectAll: () => libraryProvider.selectAll(books.map((b) => b.id).toList()),
                        onDeselectAll: libraryProvider.deselectAll,
                        actions: buildBulkActionBar(context, libraryProvider),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final useCompactLayout = constraints.maxWidth < 800;

                          if (useCompactLayout) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildSearchBar(libraryProvider)),
                                    const SizedBox(width: Spacing.sm),
                                    _buildSortButton(libraryProvider),
                                  ],
                                ),
                                const SizedBox(height: Spacing.md),
                                Row(
                                  children: [
                                    const Spacer(),
                                    _buildViewToggle(libraryProvider),
                                    const SizedBox(width: Spacing.sm),
                                    _buildAddBookButton(controlHeight, downloadsProvider),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: _buildSearchBar(libraryProvider)),
                              const SizedBox(width: Spacing.md),
                              _buildSortButton(libraryProvider),
                              const SizedBox(width: Spacing.md),
                              _buildViewToggle(libraryProvider),
                              const SizedBox(width: Spacing.md),
                              _buildAddBookButton(controlHeight, downloadsProvider),
                            ],
                          );
                        },
                      ),
              ),
              // Filter chips
              if (!isOnline)
                LibraryFilterChips(
                  horizontalPadding: Spacing.lg,
                  showDownloading: localItems.hasDownloadingItems,
                  isDownloadingSelected: showDownloadingOnly,
                  onDownloadingTapped: () => setState(() => _showDownloadingOnly = true),
                  onLibraryFilterTapped: () {
                    if (_showDownloadingOnly) {
                      setState(() => _showDownloadingOnly = false);
                    }
                  },
                ),
              // Book grid or list
              Expanded(
                child: _buildBookContent(context, libraryProvider, downloadsProvider, isLoading, acquisitionView),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookContent(
    BuildContext context,
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    bool isLoading,
    _AcquisitionLibraryView acquisitionView,
  ) {
    if (_presentationMode == _BooksPresentationMode.online && downloadsProvider != null) {
      return OnlineResultsView(
        hasSearched: downloadsProvider.remoteQuery != null,
        isSearching: downloadsProvider.isSearching,
        query: downloadsProvider.remoteQuery ?? _onlineSearchController.text,
        error: downloadsProvider.searchError,
        releases: downloadsProvider.remoteResults,
        selectedReleaseTokens: downloadsProvider.selectedReleaseTokens,
        errorsByReleaseToken: downloadsProvider.submissionErrorsByReleaseToken,
        onRetry: () => downloadsProvider.searchRemote(downloadsProvider.remoteQuery ?? _onlineSearchController.text),
        onToggleSelection: downloadsProvider.toggleReleaseSelection,
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleBooks = acquisitionView.books;
    final visiblePlaceholderJobs = acquisitionView.placeholderJobs;

    if (visibleBooks.isEmpty && visiblePlaceholderJobs.isEmpty) {
      return _buildEmptyState(libraryProvider, downloadsProvider);
    }

    void showJob(AcquisitionJob job) {
      if (downloadsProvider != null) {
        showAcquisitionJobDetailsSheet(context: context, provider: downloadsProvider, job: job);
      }
    }

    void toggleJob(AcquisitionJob job) {
      downloadsProvider?.toggleJobSelection(job.id);
    }

    if (libraryProvider.isListView) {
      return _buildBookList(
        context,
        visibleBooks,
        linkedJobsByBookId: _linkedJobsByBookId(acquisitionView.selectableJobs),
        placeholderJobs: visiblePlaceholderJobs,
        downloadsProvider: downloadsProvider,
        onAcquisitionTap: showJob,
        onAcquisitionSelectionToggle: toggleJob,
      );
    }

    return BookGrid(
      books: visibleBooks,
      acquisitionJobsByBookId: _linkedJobsByBookId(acquisitionView.selectableJobs),
      placeholderJobs: visiblePlaceholderJobs,
      selectedAcquisitionJobIds: downloadsProvider?.selectedJobIds ?? const {},
      onAcquisitionTap: showJob,
      onAcquisitionSelectionToggle: toggleJob,
      onBookTap: (book) => _navigateToBookDetails(context, book),
    );
  }

  _AcquisitionLibraryView _buildAcquisitionLibraryView({
    required List<Book> books,
    required AcquisitionLibraryItems items,
    required LibraryProvider libraryProvider,
    required bool showDownloadingOnly,
  }) {
    final visibleBooks = showDownloadingOnly
        ? books.where((book) => items.downloadingBookIds.contains(book.id)).toList()
        : books;
    final candidatePlaceholders = showDownloadingOnly ? items.downloadingOrphanJobs : items.orphanJobs;
    final normalizedQuery = libraryProvider.searchQuery.trim().toLowerCase();
    final visiblePlaceholderJobs = normalizedQuery.isEmpty
        ? candidatePlaceholders
        : candidatePlaceholders.where((job) => job.title.toLowerCase().contains(normalizedQuery)).toList();
    final selectableJobs = <AcquisitionJob>[];
    final seenJobIds = <String>{};

    for (final book in visibleBooks) {
      final job = items.linkedJobsByBookId[book.id];

      if (job != null && seenJobIds.add(job.id)) {
        selectableJobs.add(job);
      }
    }

    for (final job in visiblePlaceholderJobs) {
      if (job.status != AcquisitionJobStatus.completed && seenJobIds.add(job.id)) {
        selectableJobs.add(job);
      }
    }

    return _AcquisitionLibraryView(
      books: List.unmodifiable(visibleBooks),
      placeholderJobs: List.unmodifiable(visiblePlaceholderJobs),
      selectableJobs: List.unmodifiable(selectableJobs),
    );
  }

  List<AcquisitionJob> _visibleSelectedJobs(
    AcquisitionDownloadsProvider? provider,
    List<AcquisitionJob> selectableJobs,
  ) {
    if (provider == null) {
      return const [];
    }

    return selectableJobs.where((job) => provider.selectedJobIds.contains(job.id)).toList();
  }

  Map<String, AcquisitionJob> _linkedJobsByBookId(List<AcquisitionJob> selectableJobs) {
    return {for (final job in selectableJobs) ?job.bookId: job};
  }

  void _pruneHiddenJobSelection(AcquisitionDownloadsProvider? provider, List<AcquisitionJob> selectableJobs) {
    if (provider == null || provider.selectedJobIds.isEmpty) {
      return;
    }

    final selectableJobIds = selectableJobs.map((job) => job.id).toSet();

    if (provider.selectedJobIds.every(selectableJobIds.contains)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(context.read<AcquisitionDownloadsProvider?>(), provider)) {
        return;
      }

      provider.retainJobSelection(selectableJobIds);
    });
  }

  void _clearUnavailableDownloadingFilter(AcquisitionLibraryItems items) {
    if (!_showDownloadingOnly || items.hasDownloadingItems) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showDownloadingOnly) {
        setState(() => _showDownloadingOnly = false);
      }
    });
  }

  Widget _buildBookList(
    BuildContext context,
    List<Book> books, {
    required Map<String, AcquisitionJob> linkedJobsByBookId,
    required List<AcquisitionJob> placeholderJobs,
    required AcquisitionDownloadsProvider? downloadsProvider,
    required ValueChanged<AcquisitionJob> onAcquisitionTap,
    required ValueChanged<AcquisitionJob> onAcquisitionSelectionToggle,
  }) {
    final libraryProvider = context.watch<LibraryProvider>();
    final isSelectionMode = libraryProvider.isSelectionMode;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: books.length + placeholderJobs.length,
      itemBuilder: (context, index) {
        if (index >= books.length) {
          final job = placeholderJobs[index - books.length];
          final canSelect = job.status != AcquisitionJobStatus.completed;

          return AcquisitionPlaceholderListItem(
            job: job,
            onTap: () => onAcquisitionTap(job),
            isSelectionMode: canSelect && downloadsProvider?.selectedJobIds.isNotEmpty == true,
            isSelected: downloadsProvider?.selectedJobIds.contains(job.id) == true,
            onSelectToggle: canSelect ? () => onAcquisitionSelectionToggle(job) : null,
            onEnterSelectionMode: canSelect ? () => onAcquisitionSelectionToggle(job) : null,
          );
        }

        final book = books[index];
        final acquisitionJob = linkedJobsByBookId[book.id];
        final isFavorite = libraryProvider.isBookFavorite(book.id, book.isFavorite);

        return BookListItem(
          book: book,
          isFavorite: isFavorite,
          onTap: () => _navigateToBookDetails(context, book),
          isSelectionMode: isSelectionMode,
          isSelected: libraryProvider.isBookSelected(book.id),
          onSelectToggle: () => libraryProvider.toggleBookSelection(book.id),
          acquisitionJob: acquisitionJob,
          onAcquisitionTap: acquisitionJob == null ? null : () => onAcquisitionTap(acquisitionJob),
          isAcquisitionSelectionMode: downloadsProvider?.selectedJobIds.isNotEmpty == true,
          isAcquisitionSelected:
              acquisitionJob != null && downloadsProvider?.selectedJobIds.contains(acquisitionJob.id) == true,
          onAcquisitionSelectionToggle: acquisitionJob == null
              ? null
              : () => onAcquisitionSelectionToggle(acquisitionJob),
        );
      },
    );
  }

  void _navigateToBookDetails(BuildContext context, Book book) {
    context.go('/library/details/${book.id}');
  }

  Widget _buildEmptyState(LibraryProvider libraryProvider, AcquisitionDownloadsProvider? downloadsProvider) {
    final query = libraryProvider.searchQuery.trim();

    if (query.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No books found',
        subtitle: 'No books in your library match “$query”.',
        action: downloadsProvider?.isManagedAcquisitionReady == true
            ? FilledButton(
                onPressed: () => _enterOnlineMode(downloadsProvider!, initialQuery: query, submitImmediately: true),
                child: Text('Search online for “$query”'),
              )
            : null,
      );
    }

    return EmptyState(
      icon: Icons.library_books_outlined,
      title: 'No books found',
      subtitle: 'Try adjusting your filters or add some books',
      action: FilledButton(onPressed: () => _showAddBook(downloadsProvider), child: const Text('Add book')),
    );
  }
}
