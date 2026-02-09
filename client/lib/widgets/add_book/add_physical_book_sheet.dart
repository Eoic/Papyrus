import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/services/metadata_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/isbn_scanner_dialog.dart';
import 'package:papyrus/widgets/book_edit/cover_image_picker.dart';
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
            constraints: const BoxConstraints(maxWidth: 800),
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
  int? _rating;
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
      coverUrl = _bytesToDataUri(_coverImageBytes!);
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
      rating: _rating,
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

  String _bytesToDataUri(Uint8List bytes) {
    String mimeType = 'image/jpeg';
    if (bytes.length >= 8) {
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        mimeType = 'image/png';
      } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        mimeType = 'image/gif';
      } else if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        mimeType = 'image/webp';
      }
    }
    final base64Data = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Data';
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Add physical book',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.lg),

            // Cover + form sections
            if (widget.isDesktop) _buildDesktopBody() else _buildMobileBody(),

            const SizedBox(height: Spacing.lg),

            // Action buttons
            _buildActionButtons(),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MOBILE / DESKTOP BODY
  // ============================================================================

  Widget _buildMobileBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover image
        CoverImagePicker(
          initialUrl: _coverUrl,
          initialBytes: _coverImageBytes,
          isDesktop: false,
          onUrlChanged: (url) => setState(() => _coverUrl = url),
          onFileChanged: (bytes) => setState(() {
            _coverImageBytes = bytes;
            if (bytes != null) _coverUrl = null;
          }),
        ),
        const SizedBox(height: Spacing.lg),
        // ISBN lookup — below cover on mobile
        _buildIsbnSection(),
        const SizedBox(height: Spacing.lg),
        ..._buildFormSections(),
      ],
    );
  }

  Widget _buildDesktopBody() {
    const double coverWidth = 280;

    // Sections to lay out in two columns below the top row
    final twoColumnSections = [
      _buildPublicationSection(),
      _buildIdentifiersSection(),
      _buildSectionCard(
        title: 'Description',
        children: [
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 5,
          ),
        ],
      ),
      _buildSeriesSection(),
      _buildPhysicalBookSection(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: Cover (left) + Basic info & ISBN lookup (right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: coverWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: CoverImagePicker(
                    initialUrl: _coverUrl,
                    initialBytes: _coverImageBytes,
                    isDesktop: true,
                    onUrlChanged: (url) => setState(() => _coverUrl = url),
                    onFileChanged: (bytes) => setState(() {
                      _coverImageBytes = bytes;
                      if (bytes != null) _coverUrl = null;
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildBasicInfoSection(), _buildIsbnSection()],
              ),
            ),
          ],
        ),

        // Remaining sections in two columns
        for (int i = 0; i < twoColumnSections.length; i += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: twoColumnSections[i]),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: i + 1 < twoColumnSections.length
                    ? twoColumnSections[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }

  List<Widget> _buildFormSections() {
    return [
      _buildBasicInfoSection(),
      _buildPublicationSection(),
      _buildIdentifiersSection(),
      _buildSectionCard(
        title: 'Description',
        children: [
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 5,
          ),
        ],
      ),
      _buildSeriesSection(),
      _buildPhysicalBookSection(),
    ];
  }

  // ============================================================================
  // SECTION CARD
  // ============================================================================

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Spacing.md),
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
        _buildTextField(
          controller: _titleController,
          label: 'Title',
          required: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.md),
        _buildTextField(controller: _subtitleController, label: 'Subtitle'),
        const SizedBox(height: Spacing.md),
        _buildTextField(
          controller: _authorController,
          label: 'Author',
          required: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.md),
        _buildCoAuthorsSection(),
        const SizedBox(height: Spacing.md),
        _buildRatingRow(),
      ],
    );
  }

  Widget _buildPublicationSection() {
    return _buildSectionCard(
      title: 'Publication details',
      children: [
        _buildResponsiveRow([
          _buildTextField(controller: _publisherController, label: 'Publisher'),
          _buildTextField(controller: _languageController, label: 'Language'),
        ]),
        const SizedBox(height: Spacing.md),
        _buildResponsiveRow([
          _buildDateField(
            controller: _publicationDateController,
            label: 'Publication date',
            value: _publicationDate,
            onChanged: (date) => setState(() => _publicationDate = date),
          ),
          _buildTextField(
            controller: _pageCountController,
            label: 'Page count',
            keyboardType: TextInputType.number,
          ),
        ]),
      ],
    );
  }

  Widget _buildIdentifiersSection() {
    return _buildSectionCard(
      title: 'Identifiers',
      children: [
        _buildResponsiveRow([
          _buildTextField(controller: _isbnController, label: 'ISBN'),
          _buildTextField(controller: _isbn13Controller, label: 'ISBN-13'),
        ]),
      ],
    );
  }

  Widget _buildSeriesSection() {
    return _buildSectionCard(
      title: 'Series',
      children: [
        _buildResponsiveRow([
          _buildTextField(
            controller: _seriesNameController,
            label: 'Series name',
          ),
          _buildTextField(
            controller: _seriesNumberController,
            label: 'Number in series',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ]),
      ],
    );
  }

  Widget _buildPhysicalBookSection() {
    return _buildSectionCard(
      title: 'Physical book',
      children: [
        _buildTextField(controller: _locationController, label: 'Location'),
        const SizedBox(height: Spacing.md),
        _buildResponsiveRow([
          _buildTextField(controller: _lentToController, label: 'Lent to'),
          _buildDateField(
            controller: _lentAtController,
            label: 'Lent at',
            value: _lentAt,
            onChanged: (date) => setState(() => _lentAt = date),
          ),
        ]),
      ],
    );
  }

  // ============================================================================
  // FORM FIELDS
  // ============================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      validator: required
          ? (value) =>
                value?.trim().isEmpty == true ? '$label is required' : null
          : null,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged(null);
                },
              ),
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 20),
              onPressed: () => _pickDate(controller, value, onChanged),
            ),
          ],
        ),
      ),
      onTap: () => _pickDate(controller, value, onChanged),
    );
  }

  Future<void> _pickDate(
    TextEditingController controller,
    DateTime? currentValue,
    void Function(DateTime?) onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = DateFormat.yMMMMd().format(picked);
      onChanged(picked);
    }
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    if (!widget.isDesktop || children.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.expand((w) sync* {
          yield w;
          yield const SizedBox(height: Spacing.md);
        }).toList()..removeLast(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.expand((w) sync* {
        yield Expanded(child: w);
        yield const SizedBox(width: Spacing.md);
      }).toList()..removeLast(),
    );
  }

  // ============================================================================
  // CO-AUTHORS
  // ============================================================================

  Widget _buildCoAuthorsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Co-authors',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.xs),
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: [
            ..._coAuthors.map(
              (author) => Chip(
                label: Text(author),
                onDeleted: () {
                  setState(() => _coAuthors.remove(author));
                },
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: _showAddCoAuthorDialog,
            ),
          ],
        ),
      ],
    );
  }

  void _showAddCoAuthorDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add co-author'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter co-author name',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(ctx, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name is String && name.isNotEmpty) {
        setState(() => _coAuthors.add(name));
      }
    });
  }

  // ============================================================================
  // RATING
  // ============================================================================

  Widget _buildRatingRow() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'Rating',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: Spacing.sm),
        ...List.generate(5, (index) {
          final starValue = index + 1;
          final isSelected = _rating != null && starValue <= _rating!;
          return GestureDetector(
            onTap: () {
              setState(() {
                _rating = starValue == _rating ? null : starValue;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 28,
              ),
            ),
          );
        }),
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
            FilledButton(
              onPressed: isFetching
                  ? null
                  : () => _lookupIsbn(_isbnController.text),
              child: isFetching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Look up'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // Scan barcode button — full width, consistent with form
        OutlinedButton.icon(
          onPressed: isFetching ? null : _onScanBarcode,
          icon: const Icon(Icons.qr_code_scanner),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: FilledButton(
            onPressed: _canSave ? _onSave : null,
            child: const Text('Add to library'),
          ),
        ),
      ],
    );
  }
}
