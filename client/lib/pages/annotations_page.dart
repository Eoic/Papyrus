import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/providers/annotations_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/book_group_header.dart';
import 'package:papyrus/widgets/annotations/annotation_action_sheet.dart';
import 'package:papyrus/widgets/book_details/annotation_action_sheet.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:provider/provider.dart';

/// Annotations page showing all annotations across all books.
///
/// Features search, color filtering, sorting, and grouping by book.
class AnnotationsPage extends StatefulWidget {
  const AnnotationsPage({super.key});

  @override
  State<AnnotationsPage> createState() => _AnnotationsPageState();
}

class _AnnotationsPageState extends State<AnnotationsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnnotationsProvider _provider;
  final _searchController = TextEditingController();
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _provider = AnnotationsProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataStore = context.read<DataStore>();
    _provider.attach(dataStore);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<AnnotationsProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (isDesktop) {
            return _buildDesktopLayout(context, provider);
          }
          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    AnnotationsProvider provider,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/annotations'),
      body: SafeArea(
        child: Column(
          children: [
            // Row 1: Menu + Search + Sort
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.md,
                left: Spacing.md,
                right: Spacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Library sections',
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(child: _buildSearchField(provider)),
                  const SizedBox(width: Spacing.sm),
                  _buildSortButton(provider),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Color filter chips
            if (provider.hasAnnotations) _buildColorFilterChips(provider),

            const SizedBox(height: Spacing.sm),

            // Content
            Expanded(child: _buildContent(context, provider)),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    AnnotationsProvider provider,
  ) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.only(
              top: Spacing.lg,
              left: Spacing.lg,
              right: Spacing.lg,
            ),
            child: Row(
              children: [
                Expanded(child: _buildSearchField(provider)),
                const SizedBox(width: Spacing.md),
                _buildSortButton(provider),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Color filter chips
          if (provider.hasAnnotations) _buildColorFilterChips(provider),

          // Content
          Expanded(child: _buildContent(context, provider)),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildSearchField(AnnotationsProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search annotations...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
              )
            : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        isDense: true,
      ),
    );
  }

  Widget _buildSortButton(AnnotationsProvider provider) {
    return PopupMenuButton<AnnotationSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort annotations',
      onSelected: provider.setSortOption,
      itemBuilder: (context) => [
        _buildSortMenuItem(
          AnnotationSortOption.dateNewest,
          'Newest first',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          AnnotationSortOption.dateOldest,
          'Oldest first',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          AnnotationSortOption.bookTitle,
          'By book title',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          AnnotationSortOption.position,
          'By position',
          provider.sortOption,
        ),
      ],
    );
  }

  PopupMenuItem<AnnotationSortOption> _buildSortMenuItem(
    AnnotationSortOption option,
    String label,
    AnnotationSortOption current,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (option == current)
            Icon(
              Icons.check,
              size: IconSizes.small,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildColorFilterChips(AnnotationsProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        children: [
          // Clear chip (shown when filters are active)
          if (provider.activeColors.isNotEmpty) ...[
            ActionChip(
              label: const Text('Clear'),
              onPressed: provider.clearColorFilters,
              avatar: const Icon(Icons.clear, size: 16),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          // Color chips
          ...HighlightColor.values.map((highlightColor) {
            final isSelected = provider.activeColors.contains(highlightColor);

            return Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: FilterChip(
                selected: isSelected,
                label: Text(highlightColor.displayName),
                avatar: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: highlightColor.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                onSelected: (_) => provider.toggleColorFilter(highlightColor),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnnotationsProvider provider) {
    if (!provider.hasAnnotations) {
      return const EmptyState(
        icon: Icons.highlight_outlined,
        title: 'No annotations yet',
        subtitle: 'Annotations you create while reading will appear here',
      );
    }

    if (!provider.hasResults) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No annotations found',
        subtitle: 'Try adjusting your search or filters',
        action: TextButton(
          onPressed: () {
            _searchController.clear();
            provider.clearAllFilters();
          },
          child: const Text('Clear filters'),
        ),
      );
    }

    return _buildAnnotationList(context, provider);
  }

  Widget _buildAnnotationList(
    BuildContext context,
    AnnotationsProvider provider,
  ) {
    final groups = provider.annotationsByBook;
    final items = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    for (final entry in groups.entries) {
      final isCollapsed = _collapsedGroups.contains(entry.key);
      items.add(
        BookGroupHeader(
          bookTitle: provider.getBookTitle(entry.key),
          coverUrl: provider.getBookCoverUrl(entry.key),
          count: entry.value.length,
          itemLabel: 'annotation',
          isCollapsed: isCollapsed,
          onToggle: () {
            setState(() {
              if (_collapsedGroups.contains(entry.key)) {
                _collapsedGroups.remove(entry.key);
              } else {
                _collapsedGroups.add(entry.key);
              }
            });
          },
        ),
      );
      if (!isCollapsed) {
        for (final annotation in entry.value) {
          items.add(
            AnnotationCard(
              annotation: annotation,
              showActionMenu: isDesktop,
              onTap: () => _navigateToBook(context, annotation.bookId),
              onLongPress: () =>
                  _onAnnotationActions(context, provider, annotation),
            ),
          );
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      children: items,
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _navigateToBook(BuildContext context, String bookId) {
    context.goNamed('BOOK_DETAILS', pathParameters: {'bookId': bookId});
  }

  void _onAnnotationActions(
    BuildContext context,
    AnnotationsProvider provider,
    Annotation annotation,
  ) async {
    final action = await AnnotationActionSheet.show(
      context,
      annotation: annotation,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case AnnotationAction.editNote:
        _onEditAnnotationNote(provider, annotation);
      case AnnotationAction.delete:
        _onDeleteAnnotation(provider, annotation);
    }
  }

  void _onEditAnnotationNote(
    AnnotationsProvider provider,
    Annotation annotation,
  ) async {
    final note = await AnnotationNoteSheet.show(
      context,
      annotation: annotation,
    );
    if (!mounted) return;

    if (note != null) {
      provider.updateAnnotationNote(annotation.id, note.isEmpty ? null : note);
    }
  }

  void _onDeleteAnnotation(
    AnnotationsProvider provider,
    Annotation annotation,
  ) async {
    final bookTitle = provider.getBookTitle(annotation.bookId);
    final confirmed = await DeleteAnnotationDialog.show(
      context,
      annotation: annotation,
      bookTitle: bookTitle,
    );
    if (confirmed && mounted) {
      provider.deleteAnnotation(annotation.id);
    }
  }
}
