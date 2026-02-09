import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/book_edit_provider.dart';
import 'package:papyrus/services/metadata_service.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_edit/cover_image_picker.dart';
import 'package:papyrus/widgets/book_form/book_date_field.dart';
import 'package:papyrus/widgets/book_form/book_text_field.dart';
import 'package:papyrus/widgets/book_form/co_author_editor.dart';
import 'package:papyrus/widgets/book_form/responsive_form_row.dart';
import 'package:provider/provider.dart';

/// Page for editing book metadata.
class BookEditPage extends StatefulWidget {
  final String? id;

  const BookEditPage({super.key, required this.id});

  @override
  State<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  late BookEditProvider _provider;
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _languageController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _isbnController = TextEditingController();
  final _isbn13Controller = TextEditingController();
  final _descriptionController = TextEditingController();
  final _publicationDateController = TextEditingController();
  final _seriesNameController = TextEditingController();
  final _seriesNumberController = TextEditingController();
  final _physicalLocationController = TextEditingController();
  final _lentToController = TextEditingController();
  final _lentAtController = TextEditingController();
  final _metadataSearchController = TextEditingController();

  List<String> _coAuthors = [];

  @override
  void initState() {
    super.initState();
    _provider = BookEditProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataStore = context.read<DataStore>();
    _provider.setDataStore(dataStore);

    if (widget.id != null && !_provider.hasBook && !_provider.isLoading) {
      _provider.loadBook(widget.id!).then((_) => _populateControllers());
    }
  }

  void _populateControllers() {
    final book = _provider.editedBook;
    if (book == null) return;

    _titleController.text = book.title;
    _subtitleController.text = book.subtitle ?? '';
    _authorController.text = book.author;
    _publisherController.text = book.publisher ?? '';
    _languageController.text = book.language ?? '';
    _pageCountController.text = book.pageCount?.toString() ?? '';
    _isbnController.text = book.isbn ?? '';
    _isbn13Controller.text = book.isbn13 ?? '';
    _descriptionController.text = book.description ?? '';
    _publicationDateController.text = book.publicationDate != null
        ? DateFormat.yMMMMd().format(book.publicationDate!)
        : '';
    _seriesNameController.text = book.seriesName ?? '';
    _seriesNumberController.text = book.seriesNumber != null
        ? _formatSeriesNumber(book.seriesNumber!)
        : '';
    _physicalLocationController.text = book.physicalLocation ?? '';
    _lentToController.text = book.lentTo ?? '';
    _lentAtController.text = book.lentAt != null
        ? DateFormat.yMMMMd().format(book.lentAt!)
        : '';
    setState(() {
      _coAuthors = List.from(book.coAuthors);
    });
  }

  String _formatSeriesNumber(double number) {
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _languageController.dispose();
    _pageCountController.dispose();
    _isbnController.dispose();
    _isbn13Controller.dispose();
    _descriptionController.dispose();
    _publicationDateController.dispose();
    _seriesNameController.dispose();
    _seriesNumberController.dispose();
    _physicalLocationController.dispose();
    _lentToController.dispose();
    _lentAtController.dispose();
    _metadataSearchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<BookEditProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit book')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.error != null || !provider.hasBook) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit book')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(provider.error ?? 'Book not found'),
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

          return PopScope(
            canPop: !provider.hasUnsavedChanges,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final discard = await _showDiscardDialog();
              if (discard && mounted && context.mounted) {
                _navigateToBookDetails(context);
              }
            },
            child: _isDesktop
                ? _buildDesktopScaffold(context, provider)
                : Scaffold(
                    appBar: AppBar(
                      title: const Text('Edit book'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => _handleCancel(context),
                      ),
                      actions: [
                        TextButton(
                          onPressed: provider.canSave
                              ? () => _handleSave(context)
                              : null,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    body: Form(
                      key: _formKey,
                      child: _buildMobileLayout(context, provider),
                    ),
                  ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // LAYOUTS
  // ============================================================================

  Widget _buildDesktopScaffold(
    BuildContext context,
    BookEditProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Top bar matching book details page style
        Container(
          height: ComponentSizes.appBarHeight + 1,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => _handleCancel(context),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                ),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: Text(
                  'Book details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: provider.canSave ? () => _handleSave(context) : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Form(
            key: _formKey,
            child: _buildDesktopLayout(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, BookEditProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: Spacing.xs),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: _buildCoverSection(context, provider, isDesktop: false),
          ),
        ),
        ..._buildFormSections(context, provider),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BookEditProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left pane - Cover + Metadata
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: Spacing.xs),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: _buildCoverSection(
                          context,
                          provider,
                          isDesktop: true,
                        ),
                      ),
                    ),
                    _buildSectionCard(
                      title: 'Fetch metadata',
                      children: [_buildMetadataSection(context, provider)],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.xl),
              // Right pane - Form fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildFormSections(
                    context,
                    provider,
                    skipMetadata: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormSections(
    BuildContext context,
    BookEditProvider provider, {
    bool skipMetadata = false,
  }) {
    return [
      _buildBasicInfoSection(context, provider),
      _buildPublicationSection(),
      _buildIdentifiersSection(),
      _buildSeriesSection(),
      Card(
        margin: const EdgeInsets.only(bottom: Spacing.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          child: _buildPhysicalBookSection(context, provider),
        ),
      ),
      if (!skipMetadata)
        _buildSectionCard(
          title: 'Fetch metadata',
          children: [_buildMetadataSection(context, provider)],
        ),
      const SizedBox(height: Spacing.xl),
    ];
  }

  Widget _buildBasicInfoSection(
    BuildContext context,
    BookEditProvider provider,
  ) {
    return _buildSectionCard(
      title: 'Basic information',
      children: [
        BookTextField(
          controller: _titleController,
          label: 'Title',
          required: true,
          onChanged: _provider.updateTitle,
        ),
        const SizedBox(height: Spacing.md),
        BookTextField(
          controller: _subtitleController,
          label: 'Subtitle',
          onChanged: _provider.updateSubtitle,
        ),
        const SizedBox(height: Spacing.md),
        BookTextField(
          controller: _descriptionController,
          label: 'Description',
          maxLines: 5,
          onChanged: _provider.updateDescription,
        ),
        const SizedBox(height: Spacing.md),
        ResponsiveFormRow(
          isDesktop: _isDesktop,
          children: [
            BookTextField(
              controller: _authorController,
              label: 'Author',
              required: true,
              onChanged: _provider.updateAuthor,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        CoAuthorEditor(
          coAuthors: _coAuthors,
          onChanged: (updated) {
            setState(() => _coAuthors = updated);
            _provider.updateCoAuthors(updated);
          },
        ),
        const SizedBox(height: Spacing.md),
        _buildRatingRow(context, provider),
      ],
    );
  }

  Widget _buildPublicationSection() {
    return _buildSectionCard(
      title: 'Publication details',
      children: [
        ResponsiveFormRow(
          isDesktop: _isDesktop,
          children: [
            BookTextField(
              controller: _publisherController,
              label: 'Publisher',
              onChanged: _provider.updatePublisher,
            ),
            BookTextField(
              controller: _languageController,
              label: 'Language',
              onChanged: _provider.updateLanguage,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        ResponsiveFormRow(
          isDesktop: _isDesktop,
          children: [
            BookDateField(
              controller: _publicationDateController,
              label: 'Publication date',
              value: _provider.editedBook?.publicationDate,
              onChanged: _provider.updatePublicationDate,
            ),
            BookTextField(
              controller: _pageCountController,
              label: 'Page count',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final pages = int.tryParse(value);
                _provider.updatePageCount(pages);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentifiersSection() {
    return _buildSectionCard(
      title: 'Identifiers',
      children: [
        ResponsiveFormRow(
          isDesktop: _isDesktop,
          children: [
            BookTextField(
              controller: _isbnController,
              label: 'ISBN',
              onChanged: _provider.updateIsbn,
            ),
            BookTextField(
              controller: _isbn13Controller,
              label: 'ISBN-13',
              onChanged: _provider.updateIsbn13,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeriesSection() {
    return _buildSectionCard(
      title: 'Series',
      children: [
        ResponsiveFormRow(
          isDesktop: _isDesktop,
          children: [
            BookTextField(
              controller: _seriesNameController,
              label: 'Series name',
              onChanged: _provider.updateSeriesName,
            ),
            BookTextField(
              controller: _seriesNumberController,
              label: 'Number in series',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                final number = double.tryParse(value);
                _provider.updateSeriesNumber(number);
              },
            ),
          ],
        ),
      ],
    );
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
  // RATING SECTION
  // ============================================================================

  Widget _buildRatingRow(BuildContext context, BookEditProvider provider) {
    final rating = provider.editedBook?.rating ?? 0;
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
          final isSelected = starValue <= rating;
          return GestureDetector(
            onTap: () {
              _provider.updateRating(starValue == rating ? null : starValue);
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
  // PHYSICAL BOOK SECTION
  // ============================================================================

  Widget _buildPhysicalBookSection(
    BuildContext context,
    BookEditProvider provider,
  ) {
    final isPhysical = provider.editedBook?.isPhysical ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Physical book'),
          value: isPhysical,
          onChanged: (value) => _provider.updateIsPhysical(value),
          contentPadding: EdgeInsets.zero,
        ),
        if (isPhysical) ...[
          const SizedBox(height: Spacing.sm),
          BookTextField(
            controller: _physicalLocationController,
            label: 'Location',
            onChanged: _provider.updatePhysicalLocation,
          ),
          const SizedBox(height: Spacing.md),
          ResponsiveFormRow(
            isDesktop: _isDesktop,
            children: [
              BookTextField(
                controller: _lentToController,
                label: 'Lent to',
                onChanged: _provider.updateLentTo,
              ),
              BookDateField(
                controller: _lentAtController,
                label: 'Lent at',
                value: provider.editedBook?.lentAt,
                onChanged: _provider.updateLentAt,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // COVER SECTION
  // ============================================================================

  Widget _buildCoverSection(
    BuildContext context,
    BookEditProvider provider, {
    required bool isDesktop,
  }) {
    return CoverImagePicker(
      initialUrl: provider.editedBook?.coverUrl,
      initialBytes: provider.coverImageBytes,
      isDesktop: isDesktop,
      onUrlChanged: (url) => _provider.updateCoverUrl(url),
      onFileChanged: (bytes) => _provider.updateCoverFromFile(bytes),
    );
  }

  // ============================================================================
  // METADATA SECTION
  // ============================================================================

  Widget _buildMetadataSection(
    BuildContext context,
    BookEditProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Source selector
        SegmentedButton<MetadataSource>(
          segments: const [
            ButtonSegment(
              value: MetadataSource.openLibrary,
              label: Text('Open Library'),
            ),
            ButtonSegment(
              value: MetadataSource.googleBooks,
              label: Text('Google Books'),
            ),
          ],
          selected: {provider.selectedSource},
          onSelectionChanged: (selection) {
            provider.setMetadataSource(selection.first);
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: Spacing.md),

        // Search field
        TextFormField(
          controller: _metadataSearchController,
          decoration: InputDecoration(
            labelText: 'Search',
            hintText: 'Title, author, or ISBN',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: provider.isFetching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              onPressed: provider.isFetching
                  ? null
                  : () => _searchMetadata(provider),
            ),
          ),
          onFieldSubmitted: (_) => _searchMetadata(provider),
        ),

        // Error message
        if (provider.fetchState == MetadataFetchState.error) ...[
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    provider.fetchError ?? 'Search failed',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Results
        if (provider.fetchedResults.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Text(
            '${provider.fetchedResults.length} result(s)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          ...provider.fetchedResults.map(
            (result) => _buildResultCard(context, result, provider),
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    BookMetadataResult result,
    BookEditProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: InkWell(
        onTap: () => _applyMetadata(provider, result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover thumbnail
              Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: result.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          result.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Icon(
                            Icons.menu_book,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.menu_book,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: Spacing.sm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title ?? 'Unknown',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.primaryAuthor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.primaryAuthor,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.sourceLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap to apply',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _searchMetadata(BookEditProvider provider) {
    final query = _metadataSearchController.text.trim();
    if (query.isEmpty) return;

    final cleanQuery = query.replaceAll(RegExp(r'[-\s]'), '');
    if (RegExp(r'^[0-9X]{10,13}$').hasMatch(cleanQuery)) {
      provider.searchMetadataByIsbn(query);
    } else {
      provider.searchMetadata(query);
    }
  }

  void _applyMetadata(BookEditProvider provider, BookMetadataResult result) {
    provider.applyMetadata(result);

    final book = provider.editedBook;
    if (book != null) {
      _titleController.text = book.title;
      _subtitleController.text = book.subtitle ?? '';
      _authorController.text = book.author;
      _publisherController.text = book.publisher ?? '';
      _languageController.text = book.language ?? '';
      _pageCountController.text = book.pageCount?.toString() ?? '';
      _isbnController.text = book.isbn ?? '';
      _isbn13Controller.text = book.isbn13 ?? '';
      _descriptionController.text = book.description ?? '';
      _publicationDateController.text = book.publicationDate != null
          ? DateFormat.yMMMMd().format(book.publicationDate!)
          : '';
      setState(() {
        _coAuthors = List.from(book.coAuthors);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied metadata from ${result.sourceLabel}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _navigateToBookDetails(BuildContext context) {
    if (widget.id != null) {
      context.goNamed('BOOK_DETAILS', pathParameters: {'bookId': widget.id!});
    } else {
      context.pop();
    }
  }

  void _handleCancel(BuildContext context) async {
    if (_provider.hasUnsavedChanges) {
      final discard = await _showDiscardDialog();
      if (!discard) return;
    }
    if (mounted && context.mounted) {
      _navigateToBookDetails(context);
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before saving'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await _provider.save();
    if (!mounted || !context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _navigateToBookDetails(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.error ?? 'Failed to save'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
