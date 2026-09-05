import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/repositories/library_repository.dart';
import 'package:papyrus/media/media_cache_service.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/book_details_provider.dart';
import 'package:papyrus/providers/book_storage_status_controller.dart';
import 'package:papyrus/reader/reader_book_adapter.dart';
import 'package:papyrus/services/book_delete_cleanup_service.dart';
import 'package:papyrus/services/book_download_service.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book/book_annotations.dart';
import 'package:papyrus/widgets/book/book_bookmarks.dart';
import 'package:papyrus/widgets/book/book_details.dart';
import 'package:papyrus/widgets/book/book_notes.dart';
import 'package:papyrus/widgets/book_details/annotation_dialog.dart';
import 'package:papyrus/widgets/book_details/book_action_buttons.dart';
import 'package:papyrus/widgets/book_details/book_header.dart';
import 'package:papyrus/widgets/book_details/bookmark_dialog.dart';
import 'package:papyrus/widgets/book_details/annotation_action_sheet.dart';
import 'package:papyrus/widgets/book_details/note_action_sheet.dart';
import 'package:papyrus/widgets/book_details/note_dialog.dart';
import 'package:papyrus/widgets/book_details/update_progress_sheet.dart';
import 'package:papyrus/widgets/annotations/annotation_action_sheet.dart' as annotation_sheets;
import 'package:papyrus/widgets/bookmarks/bookmark_action_sheet.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';

/// Book details page with responsive layouts for desktop and mobile.
class BookDetailsPage extends StatefulWidget {
  final String? id;

  const BookDetailsPage({super.key, required this.id});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> with TickerProviderStateMixin {
  late BookDetailsProvider _provider;
  late TabController _tabController;
  bool _isPreparingReader = false;
  String? _readingError;

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
    final duration = AppMotion.duration(context, kTabScrollDuration);
    if (_tabController.animationDuration != duration) {
      final index = _tabController.index;
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(length: 4, vsync: this, initialIndex: index, animationDuration: duration);
      _tabController.addListener(_onTabChanged);
    }
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
          final book = provider.book!;
          final storageStatusController = context.watch<BookStorageStatusController?>();
          unawaited(storageStatusController?.ensureDeviceStatus(book));
          final readingActionState = _readingActionState(storageStatusController, book);

          if (isDesktop) {
            return _buildDesktopLayout(context, provider, readingActionState);
          }
          return _buildMobileLayout(context, provider, readingActionState);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Loading...')),
      body: const Center(child: AppCircularProgressIndicator()),
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
            Text('Failed to load book', style: Theme.of(context).textTheme.titleLarge),
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
      appBar: AppBar(leading: const BackButton(), title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64),
            const SizedBox(height: Spacing.md),
            Text('Book not found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.lg),
            FilledButton(onPressed: () => context.go('/library/books'), child: const Text('Back to library')),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    BookDetailsProvider provider,
    BookReadingActionState readingActionState,
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
                  readingActionState: readingActionState,
                  readingError: _readingError,
                  onRetryReading: _onContinueReading,
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

  Widget _buildDesktopTabBar(BuildContext context, BookDetailsProvider provider) {
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
    BookReadingActionState readingActionState,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(provider.book!.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            popUpAnimationStyle: AppMotion.animationStyle(context),
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuAction,
            itemBuilder: (context) => [
              if (!provider.book!.isPhysical) const PopupMenuItem(value: 'download', child: Text('Download')),
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
              readingActionState: readingActionState,
              readingError: _readingError,
              onRetryReading: _onContinueReading,
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
                  BookNotes(notes: provider.notes, onAddNote: _onAddNote, onNoteActions: _onNoteActions),
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
        return BookNotes(notes: provider.notes, onAddNote: _onAddNote, onNoteActions: _onNoteActions);
    }
  }

  Widget? _buildFab(BookDetailsProvider provider) {
    final isPhysical = provider.book?.isPhysical ?? false;

    switch (provider.selectedTab) {
      case BookDetailsTab.notes:
        return FloatingActionButton(onPressed: _onAddNote, child: const Icon(Icons.add));
      case BookDetailsTab.bookmarks:
        if (isPhysical) {
          return FloatingActionButton(onPressed: _onAddBookmark, child: const Icon(Icons.add));
        }
        return null;
      case BookDetailsTab.annotations:
        if (isPhysical) {
          return FloatingActionButton(onPressed: _onAddAnnotation, child: const Icon(Icons.add));
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
          ScaffoldMessenger.of(context).showSnackBar(
            snackBarAnimationStyle: AppMotion.animationStyle(context),
            const SnackBar(content: Text('Progress updated')),
          );
        }
      },
    );
  }

  Future<void> _onContinueReading() async {
    final book = _provider.book;
    if (book == null || _isPreparingReader) return;

    final messenger = ScaffoldMessenger.of(context);
    if (ReaderBookAdapter.formatFor(book.fileFormat) == null) {
      messenger.showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('This book format is not supported yet.')),
      );
      return;
    }

    final storageStatusController = context.read<BookStorageStatusController?>();
    final needsDownload = storageStatusController == null
        ? book.fileMediaId != null
        : storageStatusController.deviceStatus(book) != BookDeviceStatus.available;
    if (needsDownload) {
      if (book.fileMediaId == null) {
        setState(() => _readingError = 'This book file is not available yet.');
        return;
      }
      setState(() {
        _isPreparingReader = true;
        _readingError = null;
      });
      try {
        final importService = context.read<BookImportService>();
        await context.read<MediaCacheService>().ensureBookFileCached(
          book,
          readLocalBookFile: importService.getBookFile,
          writeLocalBookFile: importService.storeBookFile,
          downloadMedia: context.read<AuthProvider>().downloadMedia,
        );
        storageStatusController?.markAvailable(book.id);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isPreparingReader = false;
          _readingError = 'Could not download this book file.';
        });
        return;
      }
      if (!mounted) return;
      setState(() => _isPreparingReader = false);
    }

    if (!mounted) return;
    await context.pushNamed('BOOK_READER', pathParameters: {'bookId': book.id});
  }

  BookReadingActionState _readingActionState(BookStorageStatusController? controller, Book book) {
    if (_isPreparingReader) return BookReadingActionState.downloading;
    if (book.isPhysical || controller == null) return BookReadingActionState.ready;

    final accountStatus = controller.accountStatus(book);

    return switch (controller.deviceStatus(book)) {
      BookDeviceStatus.available => BookReadingActionState.ready,
      BookDeviceStatus.checking => BookReadingActionState.checking,
      BookDeviceStatus.missing when accountStatus != null && book.fileMediaId != null =>
        BookReadingActionState.download,
      BookDeviceStatus.missing => switch (accountStatus) {
        BookAccountStatus.syncing => BookReadingActionState.syncing,
        BookAccountStatus.failed => BookReadingActionState.failed,
        _ => BookReadingActionState.unavailable,
      },
      null => BookReadingActionState.ready,
    };
  }

  void _onEdit() {
    if (_provider.book != null) {
      context.goNamed('BOOK_EDIT', pathParameters: {'bookId': _provider.book!.id});
    }
  }

  Future<void> _onDownloadBookFile() async {
    final book = _provider.book;
    if (book == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final importService = context.read<BookImportService>();
    final mediaCacheService = context.read<MediaCacheService>();
    final downloadService = context.read<BookDownloadService>();

    messenger.showSnackBar(
      snackBarAnimationStyle: AppMotion.animationStyle(context),
      const SnackBar(content: Text('Preparing download...')),
    );

    try {
      final cached = await mediaCacheService.getValidCachedBookFile(book, readLocalBookFile: importService.getBookFile);
      if (!mounted) return;

      final bytes = cached ?? await _downloadAndCacheBookFile(book, importService, mediaCacheService);
      final result = await downloadService.saveBookFile(book: book, bytes: bytes);

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      if (result.saved) {
        messenger.showSnackBar(
          snackBarAnimationStyle: AppMotion.animationStyle(context),
          SnackBar(content: Text('Downloaded "${book.title}"')),
        );
      } else {
        messenger.showSnackBar(
          snackBarAnimationStyle: AppMotion.animationStyle(context),
          const SnackBar(content: Text('Download canceled')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Could not download this book file.')),
      );
    }
  }

  Future<Uint8List> _downloadAndCacheBookFile(
    Book book,
    BookImportService importService,
    MediaCacheService mediaCacheService,
  ) {
    final authProvider = context.read<AuthProvider>();
    return mediaCacheService.ensureBookFileCached(
      book,
      readLocalBookFile: importService.getBookFile,
      writeLocalBookFile: importService.storeBookFile,
      downloadMedia: authProvider.downloadMedia,
    );
  }

  void _onAddNote() async {
    if (_provider.book == null) return;

    final repository = context.read<DataStore>().libraryRepository?.notes;
    final note = await NoteDialog.show(
      context,
      bookId: _provider.book!.id,
      onSave: (note) => _provider.addNote(note, repository: repository),
    );

    if (note != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Note added')),
      );
    }
  }

  void _onAddBookmark() async {
    if (_provider.book == null) return;

    final repository = context.read<DataStore>().libraryRepository?.bookmarks;
    final bookmark = await BookmarkDialog.show(
      context,
      bookId: _provider.book!.id,
      pageCount: _provider.book!.pageCount,
      onSave: (bookmark) => _provider.addBookmark(bookmark, repository: repository),
    );

    if (bookmark != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Bookmark added')),
      );
    }
  }

  void _onAddAnnotation() async {
    if (_provider.book == null) return;

    final repository = context.read<DataStore>().libraryRepository?.annotations;
    final annotation = await AnnotationDialog.show(
      context,
      bookId: _provider.book!.id,
      onSave: (annotation) => _provider.addAnnotation(annotation, repository: repository),
    );

    if (annotation != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Annotation added')),
      );
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

    final repository = context.read<DataStore>().libraryRepository?.notes;
    final updatedNote = await NoteDialog.show(
      context,
      bookId: _provider.book!.id,
      existingNote: note,
      onSave: (updated) => _provider.updateNote(note.id, updated, previous: note, repository: repository),
    );

    if (updatedNote != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Note updated')),
      );
    }
  }

  void _onDeleteNote(Note note) async {
    final repository = context.read<DataStore>().libraryRepository?.notes;
    final confirmed = await DeleteNoteDialog.show(context, note: note);

    if (confirmed && mounted) {
      try {
        await _provider.deleteNote(note.id, repository: repository);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            snackBarAnimationStyle: AppMotion.animationStyle(context),
            const SnackBar(content: Text('Could not delete. Please try again.')),
          );
        }
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        const SnackBar(content: Text('Note deleted')),
      );
    }
  }

  void _onAnnotationActions(Annotation annotation) async {
    final repository = context.read<DataStore>().libraryRepository?.annotations;
    final action = await AnnotationActionSheet.show(context, annotation: annotation);

    if (action == null || !mounted) return;

    switch (action) {
      case AnnotationAction.edit:
        _onEditAnnotation(annotation, repository);
      case AnnotationAction.delete:
        _onDeleteAnnotation(annotation, repository);
    }
  }

  void _onEditAnnotation(Annotation annotation, EntityRepository<Annotation>? repository) async {
    await AnnotationDialog.show(
      context,
      bookId: annotation.bookId,
      existingAnnotation: annotation,
      onSave: (updated) =>
          _provider.updateAnnotation(annotation.id, updated, previous: annotation, repository: repository),
    );
    if (!mounted) return;
  }

  void _onDeleteAnnotation(Annotation annotation, EntityRepository<Annotation>? repository) async {
    final confirmed = await annotation_sheets.DeleteAnnotationDialog.show(
      context,
      annotation: annotation,
      bookTitle: _provider.book?.title ?? '',
    );
    if (confirmed && mounted) {
      try {
        await _provider.deleteAnnotation(annotation.id, repository: repository);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            snackBarAnimationStyle: AppMotion.animationStyle(context),
            const SnackBar(content: Text('Could not delete. Please try again.')),
          );
        }
        return;
      }
    }
  }

  void _onBookmarkActions(Bookmark bookmark) async {
    final repository = context.read<DataStore>().libraryRepository?.bookmarks;
    final action = await BookmarkActionSheet.show(context, bookmark: bookmark);

    if (action == null || !mounted) return;

    switch (action) {
      case BookmarkAction.editNote:
        _onEditBookmarkNote(bookmark, repository);
      case BookmarkAction.changeColor:
        _onChangeBookmarkColor(bookmark, repository);
      case BookmarkAction.delete:
        _onDeleteBookmark(bookmark, repository);
    }
  }

  void _onEditBookmarkNote(Bookmark bookmark, EntityRepository<Bookmark>? repository) async {
    await BookmarkNoteSheet.show(
      context,
      bookmark: bookmark,
      onSave: (note) => _provider.updateBookmarkNote(
        bookmark.id,
        note.isEmpty ? null : note,
        previous: bookmark,
        repository: repository,
      ),
    );
  }

  void _onChangeBookmarkColor(Bookmark bookmark, EntityRepository<Bookmark>? repository) async {
    await BookmarkColorSheet.show(
      context,
      bookmark: bookmark,
      onSave: (color) => _provider.updateBookmarkColor(bookmark.id, color, previous: bookmark, repository: repository),
    );
  }

  void _onDeleteBookmark(Bookmark bookmark, EntityRepository<Bookmark>? repository) async {
    await DeleteBookmarkDialog.show(
      context,
      bookmark: bookmark,
      bookTitle: _provider.book?.title ?? '',
      onDelete: () => _provider.deleteBookmark(bookmark.id, repository: repository),
    );
  }

  Future<void> _confirmDeleteBook() async {
    final book = _provider.book;
    if (book == null) return;

    final confirmed = await showDialog<bool>(
      animationStyle: AppMotion.animationStyle(context),
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete "${book.title}" from your library? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final dataStore = context.read<DataStore>();
    final mediaUploadQueue = context.read<MediaUploadQueue>();
    final importService = context.read<BookImportService>();
    final mediaScope = mediaUploadQueue.activeScope;
    final messenger = ScaffoldMessenger.of(context);

    await deleteBookWithMediaCleanup(
      dataStore: dataStore,
      mediaUploadQueue: mediaUploadQueue,
      bookId: book.id,
      coverMediaId: book.coverMediaId,
      deleteBookFile: importService.deleteBookFile,
      deletePendingCover: mediaScope == null
          ? null
          : (bookId) => importService.deletePendingCoverFile(mediaScope, bookId),
      deleteGuestCover: mediaScope == null ? importService.deleteGuestCoverFile : null,
      deleteCoverFile: mediaScope == null ? null : (mediaId) => importService.deleteCoverFile(mediaScope, mediaId),
    );

    if (!mounted) return;
    context.go('/library/books');
    messenger.showSnackBar(
      snackBarAnimationStyle: AppMotion.animationStyle(context),
      SnackBar(content: Text('Deleted "${book.title}"')),
    );
  }

  void _onMenuAction(String action) async {
    switch (action) {
      case 'download':
        await _onDownloadBookFile();
      case 'delete':
        await _confirmDeleteBook();
    }
  }
}
