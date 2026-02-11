import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/book_details_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book/book_annotations.dart';
import 'package:papyrus/widgets/book/book_bookmarks.dart';
import 'package:papyrus/widgets/book/book_details.dart';
import 'package:papyrus/widgets/book/book_notes.dart';
import 'package:papyrus/widgets/book_details/annotation_dialog.dart';
import 'package:papyrus/widgets/book_details/book_header.dart';
import 'package:papyrus/widgets/book_details/bookmark_dialog.dart';
import 'package:papyrus/widgets/book_details/annotation_action_sheet.dart';
import 'package:papyrus/widgets/book_details/note_action_sheet.dart';
import 'package:papyrus/widgets/book_details/note_dialog.dart';
import 'package:papyrus/widgets/book_details/update_progress_sheet.dart';
import 'package:papyrus/widgets/annotations/annotation_action_sheet.dart'
    as annotation_sheets;
import 'package:papyrus/widgets/bookmarks/bookmark_action_sheet.dart';
import 'package:provider/provider.dart';

/// Book details page with responsive layouts for desktop and mobile.
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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Connect to DataStore for persistent storage
    final dataStore = context.read<DataStore>();
    _provider.setDataStore(dataStore);

    // Load book if ID is provided and not currently loading
    if (widget.id != null && !_provider.isLoading) {
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

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Loading...'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Error')),
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
        title: const Text('Not found'),
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
              child: const Text('Back to library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    BookDetailsProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  onUpdateProgress: _onUpdateProgress,
                  onToggleFavorite: _provider.toggleFavorite,
                  onEdit: _onEdit,
                ),
                const SizedBox(height: Spacing.xl),

                // Tab bar
                _buildDesktopTabBar(context, provider),
                const SizedBox(height: Spacing.md),

                // Tab content (embedded, not TabBarView)
                SizedBox(height: 600, child: _buildTabContent(provider)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTabBar(
    BuildContext context,
    BookDetailsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          const Tab(text: 'Details'),
          Tab(text: 'Bookmarks (${provider.bookmarkCount})'),
          Tab(text: 'Annotations (${provider.annotationCount})'),
          Tab(text: 'Notes (${provider.noteCount})'),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    BookDetailsProvider provider,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(provider.book!.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
              onUpdateProgress: _onUpdateProgress,
              onToggleFavorite: _provider.toggleFavorite,
              onEdit: _onEdit,
            ),
          ),
        ],
        body: Column(
          children: [
            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'Details'),
                Tab(text: 'Bookmarks (${provider.bookmarkCount})'),
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
                  BookBookmarks(
                    bookmarks: provider.bookmarks,
                    bookTitle: provider.book!.title,
                    isPhysical: provider.book!.isPhysical,
                    onAddBookmark: _onAddBookmark,
                    onBookmarkActions: _onBookmarkActions,
                  ),
                  BookAnnotations(
                    annotations: provider.annotations,
                    isPhysical: provider.book!.isPhysical,
                    onAddAnnotation: _onAddAnnotation,
                    onAnnotationActions: _onAnnotationActions,
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
      floatingActionButton: _buildFab(provider),
    );
  }

  Widget _buildTabContent(BookDetailsProvider provider) {
    switch (provider.selectedTab) {
      case BookDetailsTab.details:
        return BookDetails(
          book: provider.book!,
          isDescriptionExpanded: provider.isDescriptionExpanded,
          onToggleDescription: provider.toggleDescriptionExpanded,
        );
      case BookDetailsTab.bookmarks:
        return BookBookmarks(
          bookmarks: provider.bookmarks,
          bookTitle: provider.book!.title,
          isPhysical: provider.book!.isPhysical,
          onAddBookmark: _onAddBookmark,
          onBookmarkActions: _onBookmarkActions,
        );
      case BookDetailsTab.annotations:
        return BookAnnotations(
          annotations: provider.annotations,
          isPhysical: provider.book!.isPhysical,
          onAddAnnotation: _onAddAnnotation,
          onAnnotationActions: _onAnnotationActions,
        );
      case BookDetailsTab.notes:
        return BookNotes(
          notes: provider.notes,
          onAddNote: _onAddNote,
          onNoteActions: _onNoteActions,
        );
    }
  }

  Widget? _buildFab(BookDetailsProvider provider) {
    final isPhysical = provider.book?.isPhysical ?? false;

    switch (provider.selectedTab) {
      case BookDetailsTab.notes:
        return FloatingActionButton(
          onPressed: _onAddNote,
          child: const Icon(Icons.add),
        );
      case BookDetailsTab.bookmarks:
        if (isPhysical) {
          return FloatingActionButton(
            onPressed: _onAddBookmark,
            child: const Icon(Icons.add),
          );
        }
        return null;
      case BookDetailsTab.annotations:
        if (isPhysical) {
          return FloatingActionButton(
            onPressed: _onAddAnnotation,
            child: const Icon(Icons.add),
          );
        }
        return null;
      case BookDetailsTab.details:
        return null;
    }
  }

  void _onUpdateProgress() {
    if (_provider.book == null) return;

    UpdateProgressSheet.show(
      context,
      book: _provider.book!,
      onSave: (page, position) {
        _provider.updatePageProgress(page, position);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Progress updated')));
        }
      },
    );
  }

  void _onContinueReading() {
    // TODO: Navigate to reader
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening book reader...')));
  }

  void _onEdit() {
    if (_provider.book != null) {
      context.pushNamed(
        'BOOK_EDIT',
        pathParameters: {'bookId': _provider.book!.id},
      );
    }
  }

  void _onAddNote() async {
    if (_provider.book == null) return;

    final note = await NoteDialog.show(context, bookId: _provider.book!.id);

    if (note != null && mounted) {
      _provider.addNote(note);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note added')));
    }
  }

  void _onAddBookmark() async {
    if (_provider.book == null) return;

    final bookmark = await BookmarkDialog.show(
      context,
      bookId: _provider.book!.id,
      pageCount: _provider.book!.pageCount,
    );

    if (bookmark != null && mounted) {
      _provider.addBookmark(bookmark);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookmark added')));
    }
  }

  void _onAddAnnotation() async {
    if (_provider.book == null) return;

    final annotation = await AnnotationDialog.show(
      context,
      bookId: _provider.book!.id,
    );

    if (annotation != null && mounted) {
      _provider.addAnnotation(annotation);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Annotation added')));
    }
  }

  void _onNoteActions(Note note) async {
    final action = await NoteActionSheet.show(context, note: note);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note updated')));
    }
  }

  void _onDeleteNote(Note note) async {
    final confirmed = await DeleteNoteDialog.show(context, note: note);

    if (confirmed && mounted) {
      _provider.deleteNote(note.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted')));
    }
  }

  void _onAnnotationActions(Annotation annotation) async {
    final action = await AnnotationActionSheet.show(
      context,
      annotation: annotation,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case AnnotationAction.editNote:
        _onEditAnnotationNote(annotation);
      case AnnotationAction.delete:
        _onDeleteAnnotation(annotation);
    }
  }

  void _onEditAnnotationNote(Annotation annotation) async {
    final note = await annotation_sheets.AnnotationNoteSheet.show(
      context,
      annotation: annotation,
    );
    if (!mounted) return;

    if (note != null) {
      _provider.updateAnnotationNote(annotation.id, note.isEmpty ? null : note);
    }
  }

  void _onDeleteAnnotation(Annotation annotation) async {
    final confirmed = await annotation_sheets.DeleteAnnotationDialog.show(
      context,
      annotation: annotation,
      bookTitle: _provider.book?.title ?? '',
    );
    if (confirmed && mounted) {
      _provider.deleteAnnotation(annotation.id);
    }
  }

  void _onBookmarkActions(Bookmark bookmark) async {
    final action = await BookmarkActionSheet.show(context, bookmark: bookmark);

    if (action == null || !mounted) return;

    switch (action) {
      case BookmarkAction.editNote:
        _onEditBookmarkNote(bookmark);
      case BookmarkAction.changeColor:
        _onChangeBookmarkColor(bookmark);
      case BookmarkAction.delete:
        _onDeleteBookmark(bookmark);
    }
  }

  void _onEditBookmarkNote(Bookmark bookmark) async {
    final note = await BookmarkNoteSheet.show(context, bookmark: bookmark);
    if (!mounted) return;

    if (note != null) {
      _provider.updateBookmarkNote(bookmark.id, note.isEmpty ? null : note);
    }
  }

  void _onChangeBookmarkColor(Bookmark bookmark) async {
    final colorHex = await BookmarkColorSheet.show(context, bookmark: bookmark);
    if (colorHex != null && mounted) {
      _provider.updateBookmarkColor(bookmark.id, colorHex);
    }
  }

  void _onDeleteBookmark(Bookmark bookmark) async {
    final confirmed = await DeleteBookmarkDialog.show(
      context,
      bookmark: bookmark,
      bookTitle: _provider.book?.title ?? '',
    );
    if (confirmed && mounted) {
      _provider.deleteBookmark(bookmark.id);
    }
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'delete':
        // TODO: Confirm and delete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete functionality coming soon')),
        );
    }
  }
}
