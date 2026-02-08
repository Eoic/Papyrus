import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/empty_notes_state.dart';
import 'package:papyrus/widgets/book_details/note_card.dart';
import 'package:papyrus/widgets/input/search_field.dart';

/// Sort options for notes within a single book.
enum _NoteSort { dateNewest, dateOldest, title }

/// Notes tab content for the book details page.
///
/// Displays a searchable list of notes associated with a book. Supports
/// desktop and mobile layouts with optimized interactions.
///
/// ## Features
///
/// - **Search**: Filter notes by title, content, or tags
/// - **Add note**: Button to create new notes (desktop layout)
/// - **Responsive**: Adapts layout to screen size
/// - **Empty states**: Shows helpful message when no notes exist
///
/// ## Layout Variants
///
/// - **Desktop** (>=840px): Search field and "Add note" button in header row
/// - **Mobile** (<840px): Full-width search field at top
///
/// ## Example
///
/// ```dart
/// BookNotes(
///   notes: bookProvider.notes,
///   onAddNote: () => _showAddNoteDialog(context),
///   onNoteTap: (note) => _showNoteDetail(note),
///   onNoteActions: (note) => _showNoteActions(note),
/// )
/// ```
class BookNotes extends StatefulWidget {
  /// List of notes to display.
  final List<Note> notes;

  /// Called when the user wants to add a new note.
  final VoidCallback? onAddNote;

  /// Called when a note is tapped.
  final Function(Note)? onNoteTap;

  /// Called when the user requests actions menu for a note (long press).
  final Function(Note)? onNoteActions;

  /// Creates a notes tab widget.
  const BookNotes({
    super.key,
    required this.notes,
    this.onAddNote,
    this.onNoteTap,
    this.onNoteActions,
  });

  @override
  State<BookNotes> createState() => _BookNotesState();
}

class _BookNotesState extends State<BookNotes> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _NoteSort _sortOption = _NoteSort.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> get _filteredAndSortedNotes {
    var result = widget.notes.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    result.sort((a, b) {
      switch (_sortOption) {
        case _NoteSort.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case _NoteSort.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case _NoteSort.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return result;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (widget.notes.isEmpty) {
      return SingleChildScrollView(
        child: EmptyNotesState(onAddNote: widget.onAddNote),
      );
    }

    if (isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAndSortedNotes;

    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildNotesList(
                  filtered,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    Spacing.md,
                  ),
                  separatorHeight: Spacing.md,
                  showActionMenu: true,
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Search notes...',
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _buildSortButton(),
          const SizedBox(width: Spacing.md),
          FilledButton.icon(
            onPressed: widget.onAddNote,
            icon: const Icon(Icons.add),
            label: const Text('Add note'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAndSortedNotes;

    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildNotesList(
                  filtered,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.md,
                  ),
                  separatorHeight: Spacing.sm,
                  showActionMenu: false,
                ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Search notes...',
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_NoteSort>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort notes',
      onSelected: (option) => setState(() => _sortOption = option),
      itemBuilder: (context) => [
        _buildSortMenuItem(_NoteSort.dateNewest, 'Newest first'),
        _buildSortMenuItem(_NoteSort.dateOldest, 'Oldest first'),
        _buildSortMenuItem(_NoteSort.title, 'By title'),
      ],
    );
  }

  PopupMenuItem<_NoteSort> _buildSortMenuItem(_NoteSort option, String label) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == _sortOption
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable notes list.
  Widget _buildNotesList(
    List<Note> notes, {
    required EdgeInsets padding,
    required double separatorHeight,
    required bool showActionMenu,
  }) {
    return ListView.separated(
      padding: padding,
      itemCount: notes.length,
      separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          showActionMenu: showActionMenu,
          onTap: () => widget.onNoteTap?.call(note),
          onLongPress: () => widget.onNoteActions?.call(note),
        );
      },
    );
  }

  /// Empty state shown when search yields no results.
  Widget _buildNoResultsState(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.xxl,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'No notes found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Try a different search term',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
