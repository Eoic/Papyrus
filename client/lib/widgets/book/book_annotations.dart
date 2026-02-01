import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/annotation_card.dart';
import 'package:papyrus/widgets/book_details/empty_annotations_state.dart';
import 'package:provider/provider.dart';

/// Annotations tab content for book details page.
/// Shows a list of annotation cards with search functionality.
class BookAnnotations extends StatefulWidget {
  final List<Annotation> annotations;
  final Function(Annotation)? onAnnotationTap;
  final Function(Annotation)? onAnnotationEdit;
  final Function(Annotation)? onAnnotationDelete;

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

  List<Annotation> get _filteredAnnotations {
    if (_searchQuery.isEmpty) {
      return widget.annotations;
    }
    final query = _searchQuery.toLowerCase();
    return widget.annotations.where((annotation) {
      return annotation.highlightText.toLowerCase().contains(query) ||
          (annotation.note?.toLowerCase().contains(query) ?? false) ||
          annotation.location.displayLocation.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
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

    if (displayMode.isEinkMode) {
      return _buildEinkLayout(context);
    }
    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      children: [
        // Search bar
        // +4 accounts for Card's default margin to align with card borders
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg + 4,
            Spacing.lg,
            Spacing.lg + 4,
            Spacing.md,
          ),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search annotations...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
        // Annotations list
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  itemCount: filteredAnnotations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.md),
                  itemBuilder: (context, index) {
                    final annotation = filteredAnnotations[index];
                    return AnnotationCard(
                      annotation: annotation,
                      onTap: () => widget.onAnnotationTap?.call(annotation),
                      onEdit: () => widget.onAnnotationEdit?.call(annotation),
                      onDelete: () =>
                          widget.onAnnotationDelete?.call(annotation),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      children: [
        // Search bar
        // +4 accounts for Card's default margin to align with card borders
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md + 4,
            Spacing.md,
            Spacing.md + 4,
            Spacing.sm,
          ),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search annotations...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
        // Annotations list
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildNoResultsState(context, colorScheme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.md,
                  ),
                  itemCount: filteredAnnotations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) {
                    final annotation = filteredAnnotations[index];
                    return AnnotationCard(
                      annotation: annotation,
                      onTap: () => widget.onAnnotationTap?.call(annotation),
                      onEdit: () => widget.onAnnotationEdit?.call(annotation),
                      onDelete: () =>
                          widget.onAnnotationDelete?.call(annotation),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEinkLayout(BuildContext context) {
    final filteredAnnotations = _filteredAnnotations;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(Spacing.pageMarginsEink),
          child: SizedBox(
            height: TouchTargets.einkMin,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search annotations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                ),
              ),
            ),
          ),
        ),
        // Annotations list
        Expanded(
          child: filteredAnnotations.isEmpty
              ? _buildEinkNoResultsState(context)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    Spacing.pageMarginsEink,
                    0,
                    Spacing.pageMarginsEink,
                    Spacing.pageMarginsEink,
                  ),
                  itemCount: filteredAnnotations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.md),
                  itemBuilder: (context, index) {
                    final annotation = filteredAnnotations[index];
                    return AnnotationCard(
                      annotation: annotation,
                      isEinkMode: true,
                      onTap: () => widget.onAnnotationTap?.call(annotation),
                      onEdit: () => widget.onAnnotationEdit?.call(annotation),
                      onDelete: () =>
                          widget.onAnnotationDelete?.call(annotation),
                    );
                  },
                ),
        ),
      ],
    );
  }

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

  Widget _buildEinkNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NO ANNOTATIONS FOUND',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
