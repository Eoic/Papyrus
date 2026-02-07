import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/topics/add_topic_sheet.dart';
import 'package:provider/provider.dart';

/// Bottom sheet for managing topic assignments for a book.
class ManageTopicsSheet extends StatefulWidget {
  /// The book to manage topics for.
  final BookData book;

  /// Called when topic assignments change.
  final void Function(List<String> tagIds)? onSave;

  const ManageTopicsSheet({super.key, required this.book, this.onSave});

  /// Shows the manage topics sheet.
  static Future<void> show(
    BuildContext context, {
    required BookData book,
    void Function(List<String> tagIds)? onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => ManageTopicsSheet(book: book, onSave: onSave),
    );
  }

  @override
  State<ManageTopicsSheet> createState() => _ManageTopicsSheetState();
}

class _ManageTopicsSheetState extends State<ManageTopicsSheet> {
  late Set<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    final dataStore = context.read<DataStore>();
    _selectedTagIds = dataStore.getTagIdsForBook(widget.book.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dataStore = context.watch<DataStore>();
    final tags = dataStore.tags;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.lg),

            // Header with book info
            Row(
              children: [
                // Book cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 40,
                    height: 60,
                    child: _buildCover(context),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manage topics', style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        widget.book.title,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Topic list
            Expanded(
              child: tags.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      controller: scrollController,
                      children: [
                        ...tags.map((tag) => _buildTagTile(context, tag)),
                        const SizedBox(height: Spacing.md),
                        _buildCreateTopicButton(context),
                        const SizedBox(height: Spacing.lg),
                      ],
                    ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
              ),
              child: Row(
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
                      onPressed: _onSave,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.book.coverURL != null && widget.book.coverURL!.isNotEmpty) {
      return Image.network(
        widget.book.coverURL!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.menu_book,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      );
    }

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.label_outline,
          size: IconSizes.display,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'No topics yet',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Create a topic to get started',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        _buildCreateTopicButton(context),
      ],
    );
  }

  Widget _buildTagTile(BuildContext context, Tag tag) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedTagIds.contains(tag.id);
    final tagColor = tag.color;
    final dataStore = context.read<DataStore>();
    final bookCount = dataStore.getBookCountForTag(tag.id);

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      elevation: 0,
      color: isSelected
          ? tagColor.withValues(alpha: 0.1)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? tagColor : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleTag(tag.id),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              // Color dot
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: tagColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Tag info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleTag(tag.id),
                activeColor: tagColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTopicButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: _showCreateTopicSheet,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.add,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                'Create new topic',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _showCreateTopicSheet() {
    final dataStore = context.read<DataStore>();

    AddTopicSheet.show(
      context,
      onSave: (name, description, colorHex) {
        final now = DateTime.now();
        final newTag = Tag(
          id: 'tag-${now.millisecondsSinceEpoch}',
          name: name,
          colorHex: colorHex,
          description: description,
          createdAt: now,
        );
        dataStore.addTag(newTag);

        // Auto-select the newly created topic
        setState(() {
          _selectedTagIds.add(newTag.id);
        });
      },
    );
  }

  void _onSave() {
    widget.onSave?.call(_selectedTagIds.toList());
    Navigator.pop(context);
  }
}
