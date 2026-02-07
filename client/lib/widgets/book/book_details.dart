import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/book_info_grid.dart';
import 'package:papyrus/widgets/shelves/move_to_shelf_sheet.dart';
import 'package:papyrus/widgets/topics/manage_topics_sheet.dart';
import 'package:papyrus/widgets/topics/topic_detail_sheet.dart';
import 'package:provider/provider.dart';

/// Details tab content for book details page.
/// Shows description, information grid, shelves, and topics.
class BookDetails extends StatefulWidget {
  final BookData book;
  final bool isDescriptionExpanded;
  final VoidCallback? onToggleDescription;

  const BookDetails({
    super.key,
    required this.book,
    this.isDescriptionExpanded = false,
    this.onToggleDescription,
  });

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description column (60%)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Description'),
                const SizedBox(height: Spacing.sm),
                _buildDescription(context, showFull: true),
                const SizedBox(height: Spacing.xl),
                _buildSectionTitle(context, 'Shelves'),
                const SizedBox(height: Spacing.sm),
                _buildShelvesChips(context),
                const SizedBox(height: Spacing.lg),
                _buildSectionTitle(context, 'Topics'),
                const SizedBox(height: Spacing.sm),
                _buildTopicsChips(context),
              ],
            ),
          ),
          const SizedBox(width: Spacing.xxl),
          // Information column (40%)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Information'),
                const SizedBox(height: Spacing.sm),
                BookInfoGrid(book: widget.book),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Description'),
          const SizedBox(height: Spacing.sm),
          _buildDescription(context),
          const SizedBox(height: Spacing.lg),
          _buildSectionTitle(context, 'Information'),
          const SizedBox(height: Spacing.sm),
          BookInfoGrid(book: widget.book),
          const SizedBox(height: Spacing.lg),
          _buildSectionTitle(context, 'Shelves'),
          const SizedBox(height: Spacing.sm),
          _buildShelvesChips(context),
          const SizedBox(height: Spacing.lg),
          _buildSectionTitle(context, 'Topics'),
          const SizedBox(height: Spacing.sm),
          _buildTopicsChips(context),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, {bool showFull = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = widget.book.description ?? '';

    if (description.isEmpty) {
      return Text(
        'No description available.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final shouldTruncate = !showFull && !widget.isDescriptionExpanded;
    final maxLines = shouldTruncate ? 4 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          maxLines: maxLines,
          overflow: shouldTruncate ? TextOverflow.ellipsis : null,
        ),
        if (!showFull && description.length > 200) ...[
          const SizedBox(height: Spacing.xs),
          GestureDetector(
            onTap: widget.onToggleDescription,
            child: Text(
              widget.isDescriptionExpanded ? 'Show less' : 'Read more',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShelvesChips(BuildContext context) {
    final dataStore = context.watch<DataStore>();
    final shelves = dataStore.getShelvesForBook(widget.book.id);

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        ...shelves.map((shelf) {
          return ActionChip(
            avatar: Icon(shelf.displayIcon, size: 16, color: shelf.color),
            label: Text(shelf.name),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () {},
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: Text(shelves.isEmpty ? 'Add to shelf' : 'Edit'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: () => _showMoveToShelfSheet(context),
        ),
      ],
    );
  }

  Widget _buildTopicsChips(BuildContext context) {
    final dataStore = context.watch<DataStore>();
    final tags = dataStore.getTagsForBook(widget.book.id);

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        ...tags.map((tag) {
          return ActionChip(
            avatar: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            label: Text(tag.name),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () => TopicDetailSheet.show(context, tag: tag),
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: Text(tags.isEmpty ? 'Add topics' : 'Edit'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: () => _showManageTopicsSheet(context),
        ),
      ],
    );
  }

  void _showMoveToShelfSheet(BuildContext context) {
    final dataStore = context.read<DataStore>();
    final currentShelfIds = dataStore
        .getShelfIdsForBook(widget.book.id)
        .toSet();

    MoveToShelfSheet.show(
      context,
      book: widget.book,
      onSave: (newShelfIds) {
        final newShelfSet = newShelfIds.toSet();

        for (final shelfId in currentShelfIds) {
          if (!newShelfSet.contains(shelfId)) {
            dataStore.removeBookFromShelf(widget.book.id, shelfId);
          }
        }

        for (final shelfId in newShelfIds) {
          if (!currentShelfIds.contains(shelfId)) {
            dataStore.addBookToShelf(widget.book.id, shelfId);
          }
        }
      },
    );
  }

  void _showManageTopicsSheet(BuildContext context) {
    final dataStore = context.read<DataStore>();
    final currentTagIds = dataStore.getTagIdsForBook(widget.book.id).toSet();

    ManageTopicsSheet.show(
      context,
      book: widget.book,
      onSave: (newTagIds) {
        final newTagSet = newTagIds.toSet();

        for (final tagId in currentTagIds) {
          if (!newTagSet.contains(tagId)) {
            dataStore.removeTagFromBook(widget.book.id, tagId);
          }
        }

        for (final tagId in newTagIds) {
          if (!currentTagIds.contains(tagId)) {
            dataStore.addTagToBook(widget.book.id, tagId);
          }
        }
      },
    );
  }
}
