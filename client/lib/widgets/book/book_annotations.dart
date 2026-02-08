import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';
import 'package:papyrus/widgets/book_details/empty_annotations_state.dart';
import 'package:papyrus/widgets/input/search_field.dart';

/// Sort options for annotations within a single book.
enum _AnnotationSort { dateNewest, dateOldest, position, color }

/// Annotations tab content for the book details page.
///
/// Displays a searchable list of annotations (highlights) associated with a book.
/// Supports desktop and mobile layouts with optimized interactions.
///
/// ## Features
///
/// - **Search**: Filter annotations by highlight text, notes, or location
/// - **Color indicators**: Each annotation shows its highlight color
/// - **Responsive**: Adapts layout to screen size
/// - **Empty states**: Shows helpful message when no annotations exist
///
/// ## Layout Variants
///
/// - **Desktop** (>=840px): Full-width search field at top
/// - **Mobile** (<840px): Full-width search field at top
///
/// ## Example
///
/// ```dart
/// BookAnnotations(
///   annotations: bookProvider.annotations,
///   onAnnotationTap: (annotation) => _showAnnotationDetail(annotation),
///   onAnnotationActions: (annotation) => _showAnnotationActions(annotation),
/// )
/// ```
class BookAnnotations extends StatefulWidget {
  /// List of annotations to display.
  final List<Annotation> annotations;

  /// Called when an annotation is tapped.
  final Function(Annotation)? onAnnotationTap;

  /// Called when the user requests actions menu for an annotation (long press).
  final Function(Annotation)? onAnnotationActions;

  /// Creates an annotations tab widget.
  const BookAnnotations({
    super.key,
    required this.annotations,
    this.onAnnotationTap,
    this.onAnnotationActions,
  });

  @override
  State<BookAnnotations> createState() => _BookAnnotationsState();
}

class _BookAnnotationsState extends State<BookAnnotations> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _AnnotationSort _sortOption = _AnnotationSort.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Annotation> get _filteredAndSortedAnnotations {
    var result = widget.annotations.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((annotation) {
        return annotation.highlightText.toLowerCase().contains(query) ||
            (annotation.note?.toLowerCase().contains(query) ?? false) ||
            annotation.location.displayLocation.toLowerCase().contains(query);
      }).toList();
    }

    result.sort((a, b) {
      switch (_sortOption) {
        case _AnnotationSort.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case _AnnotationSort.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case _AnnotationSort.position:
          return a.location.pageNumber.compareTo(b.location.pageNumber);
        case _AnnotationSort.color:
          return a.color.index.compareTo(b.color.index);
      }
    });

    return result;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (widget.annotations.isEmpty) {
      return const SingleChildScrollView(child: EmptyAnnotationsState());
    }

    if (isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAndSortedAnnotations;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildAnnotationsList(
                  filtered,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    Spacing.md,
                  ),
                  separatorHeight: Spacing.md,
                  showActionMenu: true,
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAndSortedAnnotations;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : _buildAnnotationsList(
                  filtered,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.md,
                  ),
                  separatorHeight: Spacing.sm,
                  showActionMenu: false,
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Search annotations...',
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_AnnotationSort>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort annotations',
      onSelected: (option) => setState(() => _sortOption = option),
      itemBuilder: (context) => [
        _buildSortMenuItem(_AnnotationSort.dateNewest, 'Newest first'),
        _buildSortMenuItem(_AnnotationSort.dateOldest, 'Oldest first'),
        _buildSortMenuItem(_AnnotationSort.position, 'By position'),
        _buildSortMenuItem(_AnnotationSort.color, 'By color'),
      ],
    );
  }

  PopupMenuItem<_AnnotationSort> _buildSortMenuItem(
    _AnnotationSort option,
    String label,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == _sortOption
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable annotations list.
  Widget _buildAnnotationsList(
    List<Annotation> annotations, {
    required EdgeInsets padding,
    required double separatorHeight,
    required bool showActionMenu,
  }) {
    return ListView.separated(
      padding: padding,
      itemCount: annotations.length,
      separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
      itemBuilder: (context, index) {
        final annotation = annotations[index];
        return AnnotationCard(
          annotation: annotation,
          showActionMenu: showActionMenu,
          onTap: () => widget.onAnnotationTap?.call(annotation),
          onLongPress: () => widget.onAnnotationActions?.call(annotation),
        );
      },
    );
  }

  /// Empty state shown when search yields no results.
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
}
