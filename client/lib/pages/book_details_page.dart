import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/book_details_provider.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book/book_annotations.dart';
import 'package:papyrus/widgets/book/book_details.dart';
import 'package:papyrus/widgets/book/book_notes.dart';
import 'package:papyrus/widgets/book_details/book_header.dart';
import 'package:papyrus/widgets/book_details/eink_book_details_tab_bar.dart';
import 'package:papyrus/widgets/book_details/note_action_sheet.dart';
import 'package:papyrus/widgets/book_details/note_dialog.dart';
import 'package:provider/provider.dart';

/// Book details page with responsive layouts for desktop, mobile, and e-ink.
class BookDetailsPage extends StatefulWidget {
  final String? id;

  const BookDetailsPage({super.key, required this.id});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage>
    with SingleTickerProviderStateMixin {
  late BookDetailsProvider _provider;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _provider = BookDetailsProvider();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    if (widget.id != null) {
      _provider.loadBook(widget.id!);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _provider.setTabIndex(_tabController.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<BookDetailsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }
          if (provider.error != null) {
            return _buildErrorState(context, provider.error!);
          }
          if (!provider.hasBook) {
            return _buildNotFoundState(context);
          }

          final displayMode = context.watch<DisplayModeProvider>();
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (displayMode.isEinkMode) {
            return _buildEinkLayout(context, provider);
          }
          if (isDesktop) {
            return _buildDesktopLayout(context, provider);
          }
          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Loading...'),
      ),
      body: Center(
        child: displayMode.isEinkMode
            ? Text(
                'LOADING...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: Spacing.md),
            Text(
              'Failed to load book',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.sm),
            Text(error),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () {
                if (widget.id != null) {
                  _provider.loadBook(widget.id!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64),
            const SizedBox(height: Spacing.md),
            Text(
              'Book not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () => context.go('/library/books'),
              child: const Text('Back to Library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, BookDetailsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back navigation
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/library/books'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Library'),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                BookHeader(
                  book: provider.book!,
                  isDesktop: true,
                  onContinueReading: _onContinueReading,
                  onAddToShelf: _onAddToShelf,
                  onEdit: _onEdit,
                ),
                const SizedBox(height: Spacing.xl),

                // Tab bar
                _buildDesktopTabBar(context, provider),
                const SizedBox(height: Spacing.md),

                // Tab content (embedded, not TabBarView)
                SizedBox(
                  height: 600,
                  child: _buildTabContent(provider),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTabBar(
      BuildContext context, BookDetailsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          const Tab(text: 'Details'),
          Tab(text: 'Annotations (${provider.annotationCount})'),
          Tab(text: 'Notes (${provider.noteCount})'),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, BookDetailsProvider provider) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          provider.book!.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Share'),
              ),
              const PopupMenuItem(
                value: 'favorite',
                child: Text('Add to Favorites'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: BookHeader(
              book: provider.book!,
              isDesktop: false,
              onContinueReading: _onContinueReading,
              onAddToShelf: _onAddToShelf,
              onEdit: _onEdit,
            ),
          ),
        ],
        body: Column(
          children: [
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Details'),
                Tab(text: 'Annotations (${provider.annotationCount})'),
                Tab(text: 'Notes (${provider.noteCount})'),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BookDetails(
                    book: provider.book!,
                    isDescriptionExpanded: provider.isDescriptionExpanded,
                    onToggleDescription: provider.toggleDescriptionExpanded,
                  ),
                  BookAnnotations(
                    annotations: provider.annotations,
                  ),
                  BookNotes(
                    notes: provider.notes,
                    onAddNote: _onAddNote,
                    onNoteActions: _onNoteActions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: provider.selectedTab == BookDetailsTab.notes
          ? FloatingActionButton(
              onPressed: _onAddNote,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEinkLayout(BuildContext context, BookDetailsProvider provider) {
    return Scaffold(
      body: Column(
        children: [
          // E-ink header bar
          Container(
            height: ComponentSizes.einkHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: BorderWidths.einkDefault,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/library/books'),
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 28,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'BOOK DETAILS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  BookHeader(
                    book: provider.book!,
                    isEinkMode: true,
                    onContinueReading: _onContinueReading,
                    onAddToShelf: _onAddToShelf,
                    onEdit: _onEdit,
                  ),

                  // Divider
                  Container(
                    height: BorderWidths.einkDefault,
                    color: Colors.black,
                  ),

                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.all(Spacing.pageMarginsEink),
                    child: EinkBookDetailsTabBar(
                      selectedTab: provider.selectedTab,
                      annotationCount: provider.annotationCount,
                      noteCount: provider.noteCount,
                      onTabChanged: provider.setTab,
                    ),
                  ),

                  // Tab content
                  SizedBox(
                    height: 600,
                    child: _buildTabContent(provider, isEink: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BookDetailsProvider provider, {bool isEink = false}) {
    switch (provider.selectedTab) {
      case BookDetailsTab.details:
        return BookDetails(
          book: provider.book!,
          isDescriptionExpanded: provider.isDescriptionExpanded,
          onToggleDescription: provider.toggleDescriptionExpanded,
        );
      case BookDetailsTab.annotations:
        return BookAnnotations(
          annotations: provider.annotations,
        );
      case BookDetailsTab.notes:
        return BookNotes(
          notes: provider.notes,
          onAddNote: _onAddNote,
          onNoteActions: _onNoteActions,
        );
    }
  }

  void _onContinueReading() {
    // TODO: Navigate to reader
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening book reader...')),
    );
  }

  void _onAddToShelf() {
    // TODO: Show shelf selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add to shelf functionality coming soon')),
    );
  }

  void _onEdit() {
    // TODO: Navigate to edit page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _onAddNote() async {
    if (_provider.book == null) return;

    final note = await NoteDialog.show(
      context,
      bookId: _provider.book!.id,
    );

    if (note != null && mounted) {
      _provider.addNote(note);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added')),
      );
    }
  }

  void _onNoteActions(Note note) async {
    final action = await NoteActionSheet.show(
      context,
      note: note,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case NoteAction.edit:
        _onEditNote(note);
      case NoteAction.delete:
        _onDeleteNote(note);
    }
  }

  void _onEditNote(Note note) async {
    if (_provider.book == null) return;

    final updatedNote = await NoteDialog.show(
      context,
      bookId: _provider.book!.id,
      existingNote: note,
    );

    if (updatedNote != null && mounted) {
      _provider.updateNote(note.id, updatedNote);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated')),
      );
    }
  }

  void _onDeleteNote(Note note) async {
    final confirmed = await DeleteNoteDialog.show(
      context,
      note: note,
    );

    if (confirmed && mounted) {
      _provider.deleteNote(note.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
    }
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share functionality coming soon')),
        );
      case 'favorite':
        _provider.toggleFavorite();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _provider.book!.isFavorite
                  ? 'Added to favorites'
                  : 'Removed from favorites',
            ),
          ),
        );
      case 'delete':
        // TODO: Confirm and delete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete functionality coming soon')),
        );
    }
  }
}
