import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';
import 'package:papyrus/widgets/book_details/empty_annotations_state.dart';
import 'package:papyrus/widgets/input/search_field.dart';
import 'package:provider/provider.dart';

/// Annotations tab content for the book details page.
///
/// Displays a searchable list of annotations (highlights) associated with a book.
/// Supports three display modes: desktop, mobile, and e-ink, each with
/// optimized layouts and interactions.
///
/// ## Features
///
/// - **Search**: Filter annotations by highlight text, notes, or location
/// - **Color indicators**: Each annotation shows its highlight color
/// - **Responsive**: Adapts layout to screen size and display mode
/// - **Empty states**: Shows helpful message when no annotations exist
///
/// ## Layout Variants
///
/// - **Desktop** (>=840px): Full-width search field at top
/// - **Mobile** (<840px): Full-width search field at top
/// - **E-ink**: High-contrast styling with larger touch targets
///
/// ## Example
///
/// ```dart
/// BookAnnotations(
///   annotations: bookProvider.annotations,
///   onAnnotationTap: (annotation) => _showAnnotationDetail(annotation),
///   onAnnotationEdit: (annotation) => _editAnnotation(annotation),
///   onAnnotationDelete: (annotation) => _deleteAnnotation(annotation),
/// )
/// ```
class BookAnnotations extends StatefulWidget {
  /// List of annotations to display.
  final List<Annotation> annotations;

  /// Called when an annotation is tapped.
  final Function(Annotation)? onAnnotationTap;

  /// Called when an annotation should be edited.
  final Function(Annotation)? onAnnotationEdit;

  /// Called when an annotation should be deleted.
  final Function(Annotation)? onAnnotationDelete;

  /// Creates an annotations tab widget.
  const BookAnnotations({
    super.key,
    required this.annotations,
    this.onAnnotationTap,
    this.onAnnotationEdit,
    this.onAnnotationDelete,
  });

  @override
  State<BookAnnotations> createState() => _BookAnnotationsState();
}

class _BookAnnotationsState extends State<BookAnnotations> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns annotations filtered by the current search query.
  ///
  /// Matches against highlight text, note content, and location (case-insensitive).
  List<Annotation> get _filteredAnnotations {
    if (_searchQuery.isEmpty) return widget.annotations;

    final query = _searchQuery.toLowerCase();
    return widget.annotations.where((annotation) {
      return annotation.highlightText.toLowerCase().contains(query) ||
          (annotation.note?.toLowerCase().contains(query) ?? false) ||
          annotation.location.displayLocation.toLowerCase().contains(query);
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

    if (widget.annotations.isEmpty) {
      return SingleChildScrollView(
        child: EmptyAnnotationsState(isEinkMode: displayMode.isEinkMode),
      );
    }

    if (displayMode.isEinkMode) return _buildEinkLayout(context);
    if (isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  /// Desktop layout with search field at top.
  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      children: [
        _buildSearchBar(
          // +4 accounts for Card's default margin to align with card borders
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg + 4,
            Spacing.lg,
            Spacing.lg + 4,
            Spacing.md,
          ),
        ),
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildAnnotationsList(
                  filteredAnnotations,
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

  /// Mobile layout with search field at top.
  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      children: [
        _buildSearchBar(
          // +4 accounts for Card's default margin to align with card borders
          padding: const EdgeInsets.fromLTRB(
            Spacing.md + 4,
            Spacing.md,
            Spacing.md + 4,
            Spacing.sm,
          ),
        ),
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildAnnotationsList(
                  filteredAnnotations,
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

  /// E-ink optimized layout with high-contrast styling.
  Widget _buildEinkLayout(BuildContext context) {
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      children: [
        _buildSearchBar(
          padding: const EdgeInsets.all(Spacing.pageMarginsEink),
          isEinkMode: true,
        ),
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildEinkNoResultsState(context)
              : _buildAnnotationsList(
                  filteredAnnotations,
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

  /// Builds the search bar with configurable padding and mode.
  Widget _buildSearchBar({
    required EdgeInsets padding,
    bool isEinkMode = false,
  }) {
    return Padding(
      padding: padding,
      child: SearchField(
        controller: _searchController,
        hintText: 'Search annotations...',
        isEinkMode: isEinkMode,
        onChanged: _onSearchChanged,
        onClear: _clearSearch,
      ),
    );
  }

  /// Builds the scrollable annotations list.
  Widget _buildAnnotationsList(
    List<Annotation> annotations, {
    required EdgeInsets padding,
    required double separatorHeight,
    bool isEinkMode = false,
  }) {
    return ListView.separated(
      padding: padding,
      itemCount: annotations.length,
      separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) {
        final annotation = annotations[index];
        return AnnotationCard(
          annotation: annotation,
          isEinkMode: isEinkMode,
          onTap: () => widget.onAnnotationTap?.call(annotation),
          onEdit: () => widget.onAnnotationEdit?.call(annotation),
          onDelete: () => widget.onAnnotationDelete?.call(annotation),
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
            'No annotations found',
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
            'NO ANNOTATIONS FOUND',
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
