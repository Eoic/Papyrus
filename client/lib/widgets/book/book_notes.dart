import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/empty_notes_state.dart';
import 'package:papyrus/widgets/book_details/note_card.dart';
import 'package:papyrus/widgets/input/search_field.dart';
import 'package:provider/provider.dart';

/// Notes tab content for the book details page.
///
/// Displays a searchable list of notes associated with a book. Supports
/// three display modes: desktop, mobile, and e-ink, each with optimized
/// layouts and interactions.
///
/// ## Features
///
/// - **Search**: Filter notes by title, content, or tags
/// - **Add note**: Button to create new notes (desktop/e-ink layouts)
/// - **Responsive**: Adapts layout to screen size and display mode
/// - **Empty states**: Shows helpful message when no notes exist
///
/// ## Layout Variants
///
/// - **Desktop** (>=840px): Search field and "Add Note" button in header row
/// - **Mobile** (<840px): Full-width search field at top
/// - **E-ink**: High-contrast styling with larger touch targets
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

  /// Called when a note should be edited.
  final Function(Note)? onNoteEdit;

  /// Called when a note should be deleted.
  final Function(Note)? onNoteDelete;

  /// Called when the user requests actions menu for a note (long press).
  final Function(Note)? onNoteActions;

  /// Creates a notes tab widget.
  const BookNotes({
    super.key,
    required this.notes,
    this.onAddNote,
    this.onNoteTap,
    this.onNoteEdit,
    this.onNoteDelete,
    this.onNoteActions,
  });

  @override
  State<BookNotes> createState() => _BookNotesState();
}

class _BookNotesState extends State<BookNotes> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns notes filtered by the current search query.
  ///
  /// Matches against note title, content, and tags (case-insensitive).
  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return widget.notes;

    final query = _searchQuery.toLowerCase();
    return widget.notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
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
    final displayMode = context.watch<DisplayModeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (widget.notes.isEmpty) {
      return SingleChildScrollView(
        child: EmptyNotesState(
          isEinkMode: displayMode.isEinkMode,
          onAddNote: widget.onAddNote,
        ),
      );
    }

    if (displayMode.isEinkMode) return _buildEinkLayout(context);
    if (isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  /// Desktop layout with search field and add button in a header row.
  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredNotes = _filteredNotes;

    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildNotesList(
                  filteredNotes,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  separatorHeight: Spacing.md,
                ),
        ),
      ],
    );
  }

  /// Desktop header with search field and "Add Note" button.
  Widget _buildDesktopHeader() {
    // +4 accounts for Card's default margin to align with card borders
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg + 4,
        Spacing.lg,
        Spacing.lg + 4,
        Spacing.md,
      ),
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
          const SizedBox(width: Spacing.md),
          FilledButton.icon(
            onPressed: widget.onAddNote,
            icon: const Icon(Icons.add),
            label: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  /// Mobile layout with full-width search field at top.
  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredNotes = _filteredNotes;

    return Column(
      children: [
        _buildMobileSearchBar(),
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildNotesList(
                  filteredNotes,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.md,
                  ),
                  separatorHeight: Spacing.sm,
                ),
        ),
      ],
    );
  }

  /// Mobile search bar section.
  Widget _buildMobileSearchBar() {
    // +4 accounts for Card's default margin to align with card borders
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md + 4,
        Spacing.md,
        Spacing.md + 4,
        Spacing.sm,
      ),
      child: SearchField(
        controller: _searchController,
        hintText: 'Search notes...',
        onChanged: _onSearchChanged,
        onClear: _clearSearch,
      ),
    );
  }

  /// E-ink optimized layout with high-contrast styling.
  Widget _buildEinkLayout(BuildContext context) {
    final filteredNotes = _filteredNotes;

    return Column(
      children: [
        _buildEinkHeader(),
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildEinkNoResultsState(context)
              : _buildNotesList(
                  filteredNotes,
                  padding: EdgeInsets.fromLTRB(
                    Spacing.pageMarginsEink,
                    0,
                    Spacing.pageMarginsEink,
                    Spacing.pageMarginsEink,
                  ),
                  separatorHeight: Spacing.md,
                  isEinkMode: true,
                ),
        ),
      ],
    );
  }

  /// E-ink header with search field and add button.
  Widget _buildEinkHeader() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.pageMarginsEink),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Search notes...',
              isEinkMode: true,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(width: Spacing.md),
          SizedBox(
            height: TouchTargets.einkMin,
            child: OutlinedButton.icon(
              onPressed: widget.onAddNote,
              icon: const Icon(Icons.add),
              label: const Text('ADD NOTE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkDefault,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
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
    bool isEinkMode = false,
  }) {
    return ListView.separated(
      padding: padding,
      itemCount: notes.length,
      separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          isEinkMode: isEinkMode,
          onTap: () => widget.onNoteTap?.call(note),
          onLongPress: () => widget.onNoteActions?.call(note),
        );
      },
    );
  }

  /// Empty state shown when search yields no results (standard mode).
  Widget _buildNoResultsState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ],
      ),
    );
  }

  /// Empty state shown when search yields no results (e-ink mode).
  Widget _buildEinkNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NO NOTES FOUND',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
