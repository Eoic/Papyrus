import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/library_filter_options.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/providers/enums/library_view_mode.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/bulk_book_actions.dart';
import 'package:papyrus/widgets/library/acquisition_confirmation_dialog.dart';
import 'package:papyrus/widgets/library/book_grid.dart';
import 'package:papyrus/widgets/library/book_list_item.dart';
import 'package:papyrus/widgets/library/acquisition_job_sheets.dart';
import 'package:papyrus/widgets/library/acquisition_job_visibility.dart';
import 'package:papyrus/widgets/library/acquisition_placeholder_list_item.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/library/library_advanced_filter_sheet.dart';
import 'package:papyrus/widgets/library/library_filter_chips.dart';
import 'package:papyrus/widgets/library/online_books_header.dart';
import 'package:papyrus/widgets/library/online_results_view.dart';
import 'package:papyrus/widgets/library/selection_header.dart';
import 'package:papyrus/widgets/search/library_search_bar.dart';
import 'package:papyrus/widgets/add_book/add_book_choice_sheet.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:provider/provider.dart';

/// Main library page with responsive layouts for all platforms.
/// - Mobile: AppBar with search, filter chips, 2-column grid, FAB
/// - Desktop: Header row, filter chips, 5-column grid or list view
class LibraryPage extends StatefulWidget {
  final Shelf? shelf;
  final VoidCallback? onBack;
  final VoidCallback? onEditShelf;

  const LibraryPage({super.key, this.shelf, this.onBack, this.onEditShelf});

  bool get isShelfView => shelf != null;

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
  int _presentationGeneration = 0;
  bool _showDownloadingOnly = false;
  AcquisitionDownloadsProvider? _visibleDownloadsProvider;
  late final TextEditingController _onlineSearchController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _BooksPresentationMode _presentationMode = _BooksPresentationMode.local;

  @override
  void initState() {
    super.initState();
    _onlineSearchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.isShelfView ? null : context.read<AcquisitionDownloadsProvider?>();

    _updateVisibleDownloadsProvider(provider);
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isShelfView == widget.isShelfView) {
      return;
    }

    final provider = widget.isShelfView ? null : context.read<AcquisitionDownloadsProvider?>();
    _updateVisibleDownloadsProvider(provider);

    if (widget.isShelfView) {
      _presentationMode = _BooksPresentationMode.local;
      _showDownloadingOnly = false;
    }
  }

  void _updateVisibleDownloadsProvider(AcquisitionDownloadsProvider? provider) {
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
    final downloadsProvider = widget.isShelfView ? null : context.watch<AcquisitionDownloadsProvider?>();
    final dataStore = context.watch<DataStore>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;
    final sourceBooks = _sourceBooks(dataStore);
    final filterOptions = _filterOptions(dataStore, sourceBooks);
    final books = _getFilteredBooks(libraryProvider, dataStore, sourceBooks);
    final isLoading = !dataStore.isLoaded;

    if (isDesktop) {
      return _buildDesktopLayout(
        context,
        books,
        sourceBooks,
        filterOptions,
        libraryProvider,
        downloadsProvider,
        isLoading,
      );
    }

    return _buildMobileLayout(
      context,
      books,
      sourceBooks,
      filterOptions,
      libraryProvider,
      downloadsProvider,
      isLoading,
    );
  }

  List<Book> _sourceBooks(DataStore dataStore) {
    final shelf = widget.shelf;
    return shelf == null ? dataStore.books : dataStore.getBooksInShelf(shelf.id);
  }

  LibraryFilterOptions _filterOptions(DataStore dataStore, List<Book> sourceBooks) {
    return widget.isShelfView
        ? LibraryFilterOptions.fromDataStore(dataStore, books: sourceBooks)
        : LibraryFilterOptions.fromDataStore(dataStore);
  }

  List<Book> _getFilteredBooks(LibraryProvider provider, DataStore dataStore, List<Book> sourceBooks) {
    final books = provider.filterBooks(sourceBooks, dataStore: dataStore);
    return provider.sortBooks(books);
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    List<Book> books,
    List<Book> sourceBooks,
    LibraryFilterOptions filterOptions,
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    bool isLoading,
  ) {
    final isOnline =
        !widget.isShelfView && _presentationMode == _BooksPresentationMode.online && downloadsProvider != null;
    final isBookSelection = libraryProvider.isSelectionMode;
    final localItems = buildAcquisitionLibraryItems(
      books: sourceBooks,
      jobs: widget.isShelfView ? const [] : downloadsProvider?.jobs ?? const [],
    );
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
      drawer: widget.isShelfView ? null : const LibraryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
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
                  : _buildMobileLocalHeader(libraryProvider),
            ),

            if (!isOnline)
              Column(
                children: [
                  SizedBox(height: Spacing.sm),
                  LibraryFilterChips(
                    filterOptions: filterOptions,
                    showDownloading: !widget.isShelfView && localItems.hasDownloadingItems,
                    isDownloadingSelected: showDownloadingOnly,
                    onDownloadingTapped: () => setState(() => _showDownloadingOnly = !_showDownloadingOnly),
                    onLibraryFilterTapped: () {
                      if (_showDownloadingOnly) {
                        setState(() => _showDownloadingOnly = false);
                      }
                    },
                  ),
                ],
              ),

            Expanded(
              child: _buildBookContent(
                context,
                libraryProvider,
                downloadsProvider,
                isLoading,
                acquisitionView,
                sourceBooks.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: hideLocalControls
          ? null
          : FloatingActionButton(
              onPressed: widget.isShelfView ? () {} : () => _showAddBook(downloadsProvider),
              tooltip: widget.isShelfView ? 'Add to shelf' : null,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: isOnline && downloadsProvider.selectedReleaseTokens.isNotEmpty
          ? _buildMobileOnlineAction(downloadsProvider)
          : hasJobSelection
          ? _buildMobileJobActions(downloadsProvider!, selectedJobs)
          : isBookSelection
          ? buildMobileBottomActionBar(context, libraryProvider)
          : null,
    );
  }

  Widget _buildMobileLocalHeader(LibraryProvider libraryProvider) {
    if (!widget.isShelfView) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Library sections',
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(child: _buildSearchBar(libraryProvider)),
        ],
      );
    }

    return Column(
      children: [
        _buildShelfIdentity(context, showBack: true, compact: true),
        const SizedBox(height: Spacing.md),
        SizedBox(width: double.infinity, child: _buildSearchBar(libraryProvider)),
      ],
    );
  }

  Widget _buildSearchBar(LibraryProvider libraryProvider) {
    return LibrarySearchBar(
      initialQuery: libraryProvider.searchQuery,
      activeFilterCount: libraryProvider.activeFilterCount,
      onFilterTap: _showAdvancedFilters,
      onQueryChanged: (query) {
        if (query.isEmpty) {
          libraryProvider.clearSearch();
        } else {
          libraryProvider.setSearchQuery(query);
        }
      },
    );
  }

  Future<void> _showAdvancedFilters() async {
    final libraryProvider = context.read<LibraryProvider>();
    final dataStore = context.read<DataStore>();
    final sourceBooks = _sourceBooks(dataStore);
    final filters = await LibraryAdvancedFilterSheet.show(
      context,
      libraryProvider: libraryProvider,
      dataStore: dataStore,
      sourceBooks: sourceBooks,
      filterOptions: _filterOptions(dataStore, sourceBooks),
    );

    if (filters != null && mounted) {
      libraryProvider.applyFilters(filters);
    }
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

  Widget _buildDesktopLayout(
    BuildContext context,
    List<Book> books,
    List<Book> sourceBooks,
    LibraryFilterOptions filterOptions,
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    bool isLoading,
  ) {
    const double controlHeight = 40.0;
    final isOnline =
        !widget.isShelfView && _presentationMode == _BooksPresentationMode.online && downloadsProvider != null;
    final isBookSelection = libraryProvider.isSelectionMode;
    final localItems = buildAcquisitionLibraryItems(
      books: sourceBooks,
      jobs: widget.isShelfView ? const [] : downloadsProvider?.jobs ?? const [],
    );
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
                    : _buildDesktopLocalHeader(libraryProvider, downloadsProvider, controlHeight),
              ),
              if (!isOnline)
                Column(
                  children: [
                    SizedBox(height: Spacing.sm),
                    LibraryFilterChips(
                      horizontalPadding: Spacing.lg,
                      filterOptions: filterOptions,
                      showDownloading: !widget.isShelfView && localItems.hasDownloadingItems,
                      isDownloadingSelected: showDownloadingOnly,
                      onDownloadingTapped: () => setState(() => _showDownloadingOnly = !_showDownloadingOnly),
                      onLibraryFilterTapped: () {
                        if (_showDownloadingOnly) {
                          setState(() => _showDownloadingOnly = false);
                        }
                      },
                    ),
                  ],
                ),

              // Book grid or list
              Expanded(
                child: _buildBookContent(
                  context,
                  libraryProvider,
                  downloadsProvider,
                  isLoading,
                  acquisitionView,
                  sourceBooks.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLocalHeader(
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    double controlHeight,
  ) {
    final searchAndAction = Row(
      children: [
        Expanded(child: _buildSearchBar(libraryProvider)),
        const SizedBox(width: Spacing.md),
        FilledButton.icon(
          onPressed: widget.isShelfView ? () {} : () => _showAddBook(downloadsProvider),
          icon: const Icon(Icons.add),
          label: Text(widget.isShelfView ? 'Add to shelf' : 'Add book'),
          style: FilledButton.styleFrom(minimumSize: Size(0, controlHeight)),
        ),
      ],
    );

    if (!widget.isShelfView) {
      return searchAndAction;
    }

    return Column(
      children: [
        _buildShelfIdentity(context, showBack: true, compact: false),
        const SizedBox(height: Spacing.md),
        searchAndAction,
      ],
    );
  }

  Widget _buildShelfIdentity(BuildContext context, {required bool showBack, required bool compact}) {
    final shelf = widget.shelf!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = shelf.description?.trim();
    final titleStyle = compact ? textTheme.titleLarge : textTheme.headlineSmall;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack && widget.onBack != null) ...[
          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back), tooltip: 'Back to shelves'),
          const SizedBox(width: Spacing.sm),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shelf.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (widget.onEditShelf != null) ...[
                      const SizedBox(width: Spacing.sm),
                      if (compact)
                        IconButton(
                          onPressed: widget.onEditShelf,
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit shelf',
                        )
                      else
                        Semantics(
                          label: 'Edit shelf',
                          button: true,
                          enabled: true,
                          onTap: widget.onEditShelf,
                          excludeSemantics: true,
                          child: Tooltip(
                            message: 'Edit shelf',
                            child: TextButton.icon(
                              onPressed: widget.onEditShelf,
                              icon: const Icon(Icons.edit_outlined, size: IconSizes.small),
                              label: const Text('Edit'),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  description == null || description.isEmpty ? 'Add a description' : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookContent(
    BuildContext context,
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    bool isLoading,
    _AcquisitionLibraryView acquisitionView,
    int sourceBookCount,
  ) {
    if (!widget.isShelfView && _presentationMode == _BooksPresentationMode.online && downloadsProvider != null) {
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
      return _buildEmptyState(libraryProvider, downloadsProvider, sourceBookCount);
    }

    void showJob(AcquisitionJob job) {
      if (downloadsProvider != null) {
        showAcquisitionJobDetailsSheet(context: context, provider: downloadsProvider, job: job);
      }
    }

    void toggleJob(AcquisitionJob job) {
      downloadsProvider?.toggleJobSelection(job.id);
    }

    if (libraryProvider.viewMode == LibraryViewMode.list) {
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
      libraryViewMode: libraryProvider.viewMode,
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

  Widget _buildEmptyState(
    LibraryProvider libraryProvider,
    AcquisitionDownloadsProvider? downloadsProvider,
    int sourceBookCount,
  ) {
    final query = libraryProvider.searchQuery.trim();

    if (widget.isShelfView) {
      if (sourceBookCount == 0) {
        return EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No books in this shelf',
          subtitle: 'Add books from your library to organize them here',
          action: FilledButton(onPressed: () {}, child: const Text('Add to shelf')),
        );
      }

      return const EmptyState(
        icon: Icons.search_off,
        title: 'No books found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

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
