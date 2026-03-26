import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/image_utils.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:provider/provider.dart';

enum _ImportState { idle, processing, success, error }

/// Sheet for importing a digital book file (EPUB).
///
/// Opens a file picker, processes the file in a Web Worker,
/// previews the extracted metadata, and adds the book to the library.
class ImportBookSheet extends StatelessWidget {
  const ImportBookSheet({super.key});

  /// Show the import sheet (bottom sheet on mobile, dialog on desktop).
  static Future<void> show(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: _ImportContent(),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: const Padding(
            padding: EdgeInsets.only(
              left: Spacing.lg,
              right: Spacing.lg,
              top: Spacing.md,
              bottom: Spacing.lg,
            ),
            child: _ImportContent(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ImportContent extends StatefulWidget {
  const _ImportContent();

  @override
  State<_ImportContent> createState() => _ImportContentState();
}

class _ImportContentState extends State<_ImportContent> {
  final _importService = BookImportService();
  _ImportState _state = _ImportState.idle;
  String? _filename;
  String? _errorMessage;
  BookImportResult? _result;

  @override
  void dispose() {
    _importService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess() async {
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: true,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) return;

    final file = pickerResult.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _state = _ImportState.error;
        _errorMessage = 'Could not read the selected file.';
      });
      return;
    }

    setState(() {
      _state = _ImportState.processing;
      _filename = file.name;
      _errorMessage = null;
    });

    try {
      final result = await _importService.importBook(bytes, file.name);
      setState(() {
        _state = _ImportState.success;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _state = _ImportState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _addToLibrary() {
    final result = _result;
    if (result == null) return;

    final dataStore = context.read<DataStore>();
    final now = DateTime.now();

    String? coverUrl;
    if (result.coverImage != null) {
      coverUrl = bytesToDataUri(result.coverImage!);
    }

    final book = Book(
      id: result.bookId,
      title: result.title,
      subtitle: result.subtitle,
      author: result.author,
      coAuthors: result.coAuthors,
      publisher: result.publisher,
      description: result.description,
      language: result.language,
      isbn: result.isbn,
      pageCount: result.pageCount,
      coverUrl: coverUrl,
      filePath: 'opfs://books/${result.bookId}.epub',
      fileFormat: BookFormat.epub,
      fileSize: result.fileSize,
      fileHash: result.fileHash,
      addedAt: now,
    );

    dataStore.addBook(book);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Added "${book.title}" to library')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDesktop =
        MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop) const BottomSheetHandle(),
        if (!isDesktop) const SizedBox(height: Spacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Import book', style: textTheme.headlineSmall),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        switch (_state) {
          _ImportState.idle => _buildIdleState(context),
          _ImportState.processing => _buildProcessingState(context),
          _ImportState.success => _buildSuccessState(context),
          _ImportState.error => _buildErrorState(context),
        },
      ],
    );
  }

  Widget _buildIdleState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file, size: 48, color: colorScheme.primary),
              const SizedBox(height: Spacing.md),
              Text('Select an EPUB file', style: textTheme.titleMedium),
              const SizedBox(height: Spacing.xs),
              Text(
                'The file will be stored offline on this device',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: _pickAndProcess,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse files'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Processing...', style: textTheme.titleMedium),
          if (_filename != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              _filename!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final result = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover preview
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              clipBehavior: Clip.antiAlias,
              child: result.coverImage != null
                  ? Image.memory(result.coverImage!, fit: BoxFit.cover)
                  : Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title, style: textTheme.titleMedium),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    result.author,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (result.pageCount != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '~${result.pageCount} pages',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _state = _ImportState.idle;
                    _result = null;
                    _filename = null;
                  });
                },
                child: const Text('Pick different file'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: _addToLibrary,
                child: const Text('Add to library'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _pickAndProcess,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
