import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/empty_notes_state.dart';
import 'package:papyrus/widgets/book_details/note_card.dart';
import 'package:provider/provider.dart';

/// Notes tab content for book details page.
/// Shows a list of note cards with add and search functionality.
class BookNotes extends StatefulWidget {
  final List<Note> notes;
  final VoidCallback? onAddNote;
  final Function(Note)? onNoteTap;
  final Function(Note)? onNoteEdit;
  final Function(Note)? onNoteDelete;
  final Function(Note)? onNoteActions;

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

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return widget.notes;
    }
    final query = _searchQuery.toLowerCase();
    return widget.notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
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

    if (displayMode.isEinkMode) {
      return _buildEinkLayout(context);
    }
    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredNotes = _filteredNotes;

    return Column(
      children: [
        // Header with search and add button
        // +4 accounts for Card's default margin to align with card borders
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg + 4,
            Spacing.lg,
            Spacing.lg + 4,
            Spacing.md,
          ),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                      ),
                      isDense: true,
                    ),
                  ),
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
        ),
        // Notes list or empty search result
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  itemCount: filteredNotes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.md),
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => widget.onNoteTap?.call(note),
                      onLongPress: () => widget.onNoteActions?.call(note),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredNotes = _filteredNotes;

    return Column(
      children: [
        // Search bar
        // +4 accounts for Card's default margin to align with card borders
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md + 4,
            Spacing.md,
            Spacing.md + 4,
            Spacing.sm,
          ),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
        // Notes list
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.md,
                  ),
                  itemCount: filteredNotes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => widget.onNoteTap?.call(note),
                      onLongPress: () => widget.onNoteActions?.call(note),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEinkLayout(BuildContext context) {
    final filteredNotes = _filteredNotes;

    return Column(
      children: [
        // Header with search and add button
        Padding(
          padding: const EdgeInsets.all(Spacing.pageMarginsEink),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: TouchTargets.einkMin,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: BorderWidths.einkDefault,
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: BorderWidths.einkDefault,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                      ),
                    ),
                  ),
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
        ),
        // Notes list
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildEinkNoResultsState(context)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    Spacing.pageMarginsEink,
                    0,
                    Spacing.pageMarginsEink,
                    Spacing.pageMarginsEink,
                  ),
                  itemCount: filteredNotes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.md),
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      isEinkMode: true,
                      onTap: () => widget.onNoteTap?.call(note),
                      onLongPress: () => widget.onNoteActions?.call(note),
                    );
                  },
                ),
        ),
      ],
    );
  }

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

  Widget _buildEinkNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NO NOTES FOUND',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
