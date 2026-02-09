import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/metadata_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/isbn_scanner_dialog.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:provider/provider.dart';

/// ISBN lookup states.
enum _IsbnLookupState { idle, fetching, found, notFound, error }

/// Sheet/dialog for adding a physical book with optional ISBN scan/lookup.
class AddPhysicalBookSheet extends StatefulWidget {
  const AddPhysicalBookSheet({super.key});

  /// Show the sheet (bottom sheet on mobile, dialog on desktop).
  static Future<void> show(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const AddPhysicalBookSheet(),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _PhysicalBookContent(
          scrollController: scrollController,
          isDesktop: false,
        ),
      ),
    );
  }

  @override
  State<AddPhysicalBookSheet> createState() => _AddPhysicalBookSheetState();
}

class _AddPhysicalBookSheetState extends State<AddPhysicalBookSheet> {
  @override
  Widget build(BuildContext context) {
    // Desktop dialog: rendered inside ConstrainedBox
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: const _PhysicalBookContent(
        scrollController: null,
        isDesktop: true,
      ),
    );
  }
}

class _PhysicalBookContent extends StatefulWidget {
  final ScrollController? scrollController;
  final bool isDesktop;

  const _PhysicalBookContent({
    required this.scrollController,
    required this.isDesktop,
  });

  @override
  State<_PhysicalBookContent> createState() => _PhysicalBookContentState();
}

class _PhysicalBookContentState extends State<_PhysicalBookContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _publisherController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _isbnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final _metadataService = MetadataService();
  _IsbnLookupState _lookupState = _IsbnLookupState.idle;
  String? _lookupMessage;
  String? _coverUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subtitleController.dispose();
    _publisherController.dispose();
    _pageCountController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _authorController.text.trim().isNotEmpty;

  Future<void> _onScanBarcode() async {
    final isbn = await IsbnScannerDialog.show(context);
    if (isbn != null && isbn.isNotEmpty && mounted) {
      _isbnController.text = isbn;
      _lookupIsbn(isbn);
    }
  }

  Future<void> _lookupIsbn(String isbn) async {
    if (isbn.trim().isEmpty) return;

    setState(() {
      _lookupState = _IsbnLookupState.fetching;
      _lookupMessage = null;
    });

    try {
      // Try Open Library first
      var results = await _metadataService.searchByIsbn(
        isbn.trim(),
        MetadataSource.openLibrary,
      );

      // Fall back to Google Books
      if (results.isEmpty) {
        results = await _metadataService.searchByIsbn(
          isbn.trim(),
          MetadataSource.googleBooks,
        );
      }

      if (!mounted) return;

      if (results.isNotEmpty) {
        final result = results.first;
        setState(() {
          if (result.title != null) _titleController.text = result.title!;
          if (result.primaryAuthor.isNotEmpty) {
            _authorController.text = result.primaryAuthor;
          }
          if (result.subtitle != null) {
            _subtitleController.text = result.subtitle!;
          }
          if (result.publisher != null) {
            _publisherController.text = result.publisher!;
          }
          if (result.pageCount != null) {
            _pageCountController.text = result.pageCount.toString();
          }
          if (result.description != null) {
            _descriptionController.text = result.description!;
          }
          if (result.isbn != null && _isbnController.text.isEmpty) {
            _isbnController.text = result.isbn!;
          }
          _coverUrl = result.coverUrl;
          _lookupState = _IsbnLookupState.found;
        });
      } else {
        setState(() {
          _lookupState = _IsbnLookupState.notFound;
          _lookupMessage = 'No results found for this ISBN';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupState = _IsbnLookupState.error;
        _lookupMessage = 'Could not look up. Check your internet connection.';
      });
    }
  }

  void _onSave() {
    final dataStore = context.read<DataStore>();
    final now = DateTime.now();

    final pageCount = int.tryParse(_pageCountController.text.trim());

    final book = Book(
      id: 'book-${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty
          ? null
          : _subtitleController.text.trim(),
      publisher: _publisherController.text.trim().isEmpty
          ? null
          : _publisherController.text.trim(),
      pageCount: pageCount,
      isbn: _isbnController.text.trim().isEmpty
          ? null
          : _isbnController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      coverUrl: _coverUrl,
      isPhysical: true,
      physicalLocation: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      addedAt: now,
    );

    dataStore.addBook(book);

    // Capture the scaffold messenger before popping (context becomes invalid after pop)
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(content: Text('Added "${book.title}" to library')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.md,
        bottom: widget.isDesktop
            ? Spacing.lg
            : MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          shrinkWrap: widget.isDesktop,
          children: [
            if (!widget.isDesktop) ...[
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.lg),
            ],
            Text('Add physical book', style: textTheme.headlineSmall),
            const SizedBox(height: Spacing.lg),

            // ISBN lookup section
            _buildIsbnSection(colorScheme, textTheme),
            const SizedBox(height: Spacing.lg),

            // Title
            _buildLabel('Title', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('Enter book title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.lg),

            // Author
            _buildLabel('Author', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _authorController,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('Enter author name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Author is required';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.lg),

            // Subtitle
            _buildLabel('Subtitle', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _subtitleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Enter subtitle'),
            ),
            const SizedBox(height: Spacing.lg),

            // Publisher
            _buildLabel('Publisher', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _publisherController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Enter publisher'),
            ),
            const SizedBox(height: Spacing.lg),

            // Page count
            _buildLabel('Page count', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _pageCountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Enter page count'),
            ),
            const SizedBox(height: Spacing.lg),

            // ISBN
            _buildLabel('ISBN', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _isbnController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Enter ISBN'),
            ),
            const SizedBox(height: Spacing.lg),

            // Description
            _buildLabel('Description', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: _inputDecoration('Enter description'),
            ),
            const SizedBox(height: Spacing.lg),

            // Physical location
            _buildLabel('Physical location', textTheme, colorScheme),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('e.g. Bookshelf 3, top row'),
            ),
            const SizedBox(height: Spacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _onSave : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Text('Add to library'),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildIsbnSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ISBN lookup',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _lookupState == _IsbnLookupState.fetching
                    ? null
                    : _onScanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan barcode'),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: TextFormField(
                  controller: _isbnController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'ISBN',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton(
                onPressed: _lookupState == _IsbnLookupState.fetching
                    ? null
                    : () => _lookupIsbn(_isbnController.text),
                child: const Text('Look up'),
              ),
            ],
          ),
          if (_lookupState == _IsbnLookupState.fetching) ...[
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Looking up book details...',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (_lookupState == _IsbnLookupState.found) ...[
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                const SizedBox(width: Spacing.xs),
                Text(
                  'Book details found',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
          if (_lookupState == _IsbnLookupState.notFound ||
              _lookupState == _IsbnLookupState.error) ...[
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(
                  _lookupState == _IsbnLookupState.notFound
                      ? Icons.info_outline
                      : Icons.error_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    _lookupMessage ?? '',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(
    String text,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
    );
  }
}
