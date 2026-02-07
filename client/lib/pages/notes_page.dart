import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/notes_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/book_group_header.dart';
import 'package:papyrus/widgets/book_details/note_action_sheet.dart';
import 'package:papyrus/widgets/book_details/note_card.dart';
import 'package:papyrus/widgets/book_details/note_dialog.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:provider/provider.dart';

/// Notes page showing all notes across all books.
///
/// Features search, tag filtering, sorting, and grouping by book.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late NotesProvider _provider;
  final _searchController = TextEditingController();
  bool _showMobileSearch = false;
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _provider = NotesProvider();
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
      child: Consumer<NotesProvider>(
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

  Widget _buildMobileLayout(BuildContext context, NotesProvider provider) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/notes'),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Library sections',
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showMobileSearch ? Icons.search_off : Icons.search,
                    ),
                    onPressed: () {
                      setState(() {
                        _showMobileSearch = !_showMobileSearch;
                        if (!_showMobileSearch) {
                          _searchController.clear();
                          provider.clearSearch();
                        }
                      });
                    },
                    tooltip: 'Search notes',
                  ),
                  _buildSortButton(provider),
                ],
              ),
            ),

            // Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Row(
                children: [
                  Text(
                    '${provider.totalCount} ${provider.totalCount == 1 ? 'note' : 'notes'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar (toggled)
            if (_showMobileSearch) ...[
              const SizedBox(height: Spacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: _buildSearchField(provider),
              ),
            ],

            // Tag filter chips
            if (provider.hasNotes && provider.allTags.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              _buildTagFilterChips(provider),
            ],

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

  Widget _buildDesktopLayout(BuildContext context, NotesProvider provider) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Text('Notes', style: textTheme.headlineMedium),
                const SizedBox(width: Spacing.lg),
                Text(
                  '${provider.totalCount} ${provider.totalCount == 1 ? 'note' : 'notes'}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 300, child: _buildSearchField(provider)),
                const SizedBox(width: Spacing.md),
                _buildSortButton(provider),
              ],
            ),
          ),

          // Tag filter chips
          if (provider.hasNotes && provider.allTags.isNotEmpty)
            _buildTagFilterChips(provider),

          // Content
          Expanded(child: _buildContent(context, provider)),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildSearchField(NotesProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search notes...',
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
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
      ),
    );
  }

  Widget _buildSortButton(NotesProvider provider) {
    return PopupMenuButton<NoteSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort notes',
      onSelected: provider.setSortOption,
      itemBuilder: (context) => [
        _buildSortMenuItem(
          NoteSortOption.dateNewest,
          'Newest first',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          NoteSortOption.dateOldest,
          'Oldest first',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          NoteSortOption.bookTitle,
          'By book title',
          provider.sortOption,
        ),
        _buildSortMenuItem(
          NoteSortOption.pinnedFirst,
          'Pinned first',
          provider.sortOption,
        ),
      ],
    );
  }

  PopupMenuItem<NoteSortOption> _buildSortMenuItem(
    NoteSortOption option,
    String label,
    NoteSortOption current,
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

  Widget _buildTagFilterChips(NotesProvider provider) {
    final sortedTags = provider.allTags.toList()..sort();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        children: [
          // Clear chip (shown when filters are active)
          if (provider.activeTags.isNotEmpty) ...[
            ActionChip(
              label: const Text('Clear'),
              onPressed: provider.clearTagFilters,
              avatar: const Icon(Icons.clear, size: 16),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          // Tag chips
          ...sortedTags.map((tag) {
            final isSelected = provider.activeTags.contains(tag);

            return Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: FilterChip(
                selected: isSelected,
                label: Text(tag),
                onSelected: (_) => provider.toggleTagFilter(tag),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotesProvider provider) {
    if (!provider.hasNotes) {
      return const EmptyState(
        icon: Icons.note_outlined,
        title: 'No notes yet',
        subtitle: 'Notes you create while reading will appear here',
      );
    }

    if (!provider.hasResults) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No notes found',
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

    return _buildNoteList(context, provider);
  }

  Widget _buildNoteList(BuildContext context, NotesProvider provider) {
    final groups = provider.notesByBook;
    final items = <Widget>[];

    for (final entry in groups.entries) {
      final isCollapsed = _collapsedGroups.contains(entry.key);
      items.add(
        BookGroupHeader(
          bookTitle: provider.getBookTitle(entry.key),
          coverUrl: provider.getBookCoverUrl(entry.key),
          count: entry.value.length,
          itemLabel: 'note',
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
        for (final note in entry.value) {
          items.add(
            NoteCard(
              note: note,
              onTap: () => _navigateToBook(context, note.bookId),
              onLongPress: () => _showNoteActions(context, provider, note),
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

  void _showNoteActions(
    BuildContext context,
    NotesProvider provider,
    Note note,
  ) async {
    final action = await NoteActionSheet.show(context, note: note);
    if (!mounted || action == null) return;

    switch (action) {
      case NoteAction.edit:
        final updatedNote = await NoteDialog.show(
          this.context,
          bookId: note.bookId,
          existingNote: note,
        );
        if (updatedNote != null && mounted) {
          provider.updateNote(updatedNote);
        }
      case NoteAction.delete:
        final confirmed = await DeleteNoteDialog.show(this.context, note: note);
        if (confirmed && mounted) {
          provider.deleteNote(note.id);
        }
    }
  }
}
