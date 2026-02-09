import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/metadata_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/image_utils.dart';
import 'package:papyrus/widgets/add_book/isbn_scanner_dialog.dart';
import 'package:papyrus/widgets/book_edit/cover_image_picker.dart';
import 'package:papyrus/widgets/book_form/book_date_field.dart';
import 'package:papyrus/widgets/book_form/book_text_field.dart';
import 'package:papyrus/widgets/book_form/co_author_editor.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';
import 'package:provider/provider.dart';

/// ISBN lookup states.
enum _IsbnLookupState { idle, fetching, found, notFound, error }

/// Sheet for adding a physical book with optional ISBN scan/lookup.
class AddPhysicalBookSheet extends StatelessWidget {
  const AddPhysicalBookSheet({super.key});

  /// Show the sheet as a bottom sheet.
  static Future<void> show(BuildContext context) {
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
        builder: (context, scrollController) =>
            _PhysicalBookContent(scrollController: scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _PhysicalBookContent extends StatefulWidget {
  final ScrollController? scrollController;

  const _PhysicalBookContent({required this.scrollController});

  @override
  State<_PhysicalBookContent> createState() => _PhysicalBookContentState();
}

class _PhysicalBookContentState extends State<_PhysicalBookContent> {
  final _formKey = GlobalKey<FormState>();

  // Existing controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _publisherController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _isbnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // New controllers
  final _languageController = TextEditingController();
  final _isbn13Controller = TextEditingController();
  final _publicationDateController = TextEditingController();
  final _seriesNameController = TextEditingController();
  final _seriesNumberController = TextEditingController();
  final _lentToController = TextEditingController();
  final _lentAtController = TextEditingController();

  // New state fields
  List<String> _coAuthors = [];
  DateTime? _publicationDate;
  DateTime? _lentAt;
  Uint8List? _coverImageBytes;

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
    _languageController.dispose();
    _isbn13Controller.dispose();
    _publicationDateController.dispose();
    _seriesNameController.dispose();
    _seriesNumberController.dispose();
    _lentToController.dispose();
    _lentAtController.dispose();
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

          // New fields from metadata
          _coAuthors = result.coAuthors;
          if (result.language != null) {
            _languageController.text = result.language!;
          }
          if (result.isbn13 != null) {
            _isbn13Controller.text = result.isbn13!;
          }
          if (result.publishedDate != null) {
            _publicationDate = _parsePublishedDate(result.publishedDate!);
            if (_publicationDate != null) {
              _publicationDateController.text = DateFormat.yMMMMd().format(
                _publicationDate!,
              );
            }
          }

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

  DateTime? _parsePublishedDate(String dateStr) {
    // Try full date (yyyy-MM-dd)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    // Try year only
    final year = int.tryParse(dateStr);
    if (year != null) return DateTime(year);
    return null;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final dataStore = context.read<DataStore>();
    final now = DateTime.now();

    final pageCount = int.tryParse(_pageCountController.text.trim());
    final seriesNumber = double.tryParse(_seriesNumberController.text.trim());

    // Convert cover image bytes to data URI if present
    String? coverUrl = _coverUrl;
    if (_coverImageBytes != null) {
      coverUrl = bytesToDataUri(_coverImageBytes!);
    }

    final book = Book(
      id: 'book-${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      subtitle: _nullIfEmpty(_subtitleController.text),
      coAuthors: _coAuthors,
      publisher: _nullIfEmpty(_publisherController.text),
      language: _nullIfEmpty(_languageController.text),
      pageCount: pageCount,
      isbn: _nullIfEmpty(_isbnController.text),
      isbn13: _nullIfEmpty(_isbn13Controller.text),
      publicationDate: _publicationDate,
      description: _nullIfEmpty(_descriptionController.text),
      coverUrl: coverUrl,
      isPhysical: true,
      physicalLocation: _nullIfEmpty(_locationController.text),
      lentTo: _nullIfEmpty(_lentToController.text),
      lentAt: _lentAt,
      seriesName: _nullIfEmpty(_seriesNameController.text),
      seriesNumber: seriesNumber,
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

  // ============================================================================
  // HELPERS
  // ============================================================================

  String? _nullIfEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Fixed header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.md,
                0,
              ),
              child: Column(
                children: [
                  const BottomSheetHandle(),
                  const SizedBox(height: Spacing.md),
                  BottomSheetHeader(
                    title: 'Add physical book',
                    onCancel: () => Navigator.pop(context),
                    onSave: _onSave,
                    saveLabel: 'Add',
                    canSave: _canSave,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            const Divider(height: 1),

            // Scrollable form content
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CoverImagePicker(
                        initialUrl: _coverUrl,
                        initialBytes: _coverImageBytes,
                        onUrlChanged: (url) => setState(() => _coverUrl = url),
                        onFileChanged: (bytes) => setState(() {
                          _coverImageBytes = bytes;
                          if (bytes != null) _coverUrl = null;
                        }),
                        coverWidth: 205.0,
                        coverHeight: 315.0,
                      ),
                      _buildIsbnSection(),
                      _buildBasicInfoSection(),
                      _buildPublicationSection(),
                      _buildIdentifiersSection(),
                      _buildSeriesSection(),
                      _buildPhysicalBookSection(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SECTION CARD
  // ============================================================================

  Widget _buildSectionCard({
    required String? title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.md),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FORM SECTIONS
  // ============================================================================

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      title: 'Basic information',
      children: [
        BookTextField(
          controller: _titleController,
          label: 'Title',
          required: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.md),
        BookTextField(controller: _subtitleController, label: 'Subtitle'),
        const SizedBox(height: Spacing.md),
        BookTextField(
          controller: _authorController,
          label: 'Author',
          required: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.md),
        CoAuthorEditor(
          coAuthors: _coAuthors,
          onChanged: (updated) => setState(() => _coAuthors = updated),
        ),
        const SizedBox(height: Spacing.md),
        BookTextField(
          controller: _descriptionController,
          label: 'Description',
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildPublicationSection() {
    return _buildSectionCard(
      title: 'Publication details',
      children: [
        BookTextField(controller: _publisherController, label: 'Publisher'),
        const SizedBox(height: Spacing.md),
        BookTextField(controller: _languageController, label: 'Language'),
        const SizedBox(height: Spacing.md),
        BookDateField(
          controller: _publicationDateController,
          label: 'Publication date',
          value: _publicationDate,
          onChanged: (date) => setState(() => _publicationDate = date),
        ),
        const SizedBox(height: Spacing.md),
        BookTextField(
          controller: _pageCountController,
          label: 'Page count',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildIdentifiersSection() {
    return _buildSectionCard(
      title: 'Identifiers',
      children: [
        BookTextField(controller: _isbnController, label: 'ISBN'),
        const SizedBox(height: Spacing.md),
        BookTextField(controller: _isbn13Controller, label: 'ISBN-13'),
      ],
    );
  }

  Widget _buildSeriesSection() {
    return _buildSectionCard(
      title: 'Series',
      children: [
        BookTextField(controller: _seriesNameController, label: 'Series name'),
        const SizedBox(height: Spacing.md),
        BookTextField(
          controller: _seriesNumberController,
          label: 'Number in series',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildPhysicalBookSection() {
    return _buildSectionCard(
      title: 'Other details',
      children: [
        BookTextField(controller: _locationController, label: 'Location'),
        const SizedBox(height: Spacing.md),
        BookTextField(controller: _lentToController, label: 'Lent to'),
        const SizedBox(height: Spacing.md),
        BookDateField(
          controller: _lentAtController,
          label: 'Lent at',
          value: _lentAt,
          onChanged: (date) => setState(() => _lentAt = date),
        ),
      ],
    );
  }

  // ============================================================================
  // ISBN SECTION
  // ============================================================================

  Widget _buildIsbnSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFetching = _lookupState == _IsbnLookupState.fetching;

    return _buildSectionCard(
      title: 'ISBN lookup',
      children: [
        // ISBN field with inline look-up button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: _isbnController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ISBN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onFieldSubmitted: (_) => _lookupIsbn(_isbnController.text),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            IconButton(
              onPressed: isFetching
                  ? null
                  : () => _lookupIsbn(_isbnController.text),
              icon: isFetching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // Scan barcode button — full width, consistent with form
        OutlinedButton.icon(
          onPressed: isFetching ? null : _onScanBarcode,
          icon: const Icon(Icons.barcode_reader),
          label: const Text('Scan barcode'),
        ),

        // Status indicators
        if (_lookupState == _IsbnLookupState.found) ...[
          const SizedBox(height: Spacing.md),
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
          const SizedBox(height: Spacing.md),
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
    );
  }

  // ============================================================================
  // ACTION BUTTONS
  // ============================================================================
}
