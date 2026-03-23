import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/topics/add_topic_sheet.dart';
import 'package:provider/provider.dart';

/// Bottom sheet showing topic details with edit and delete actions.
///
/// Used from book details (tap on topic chip) and manage topics sheet
/// (overflow menu on topic tile).
class TopicDetailSheet extends StatelessWidget {
  final Tag tag;

  const TopicDetailSheet({super.key, required this.tag});

  /// Shows the topic detail sheet.
  static Future<void> show(BuildContext context, {required Tag tag}) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => TopicDetailSheet(tag: tag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dataStore = context.watch<DataStore>();
    final bookCount = dataStore.getBookCountForTag(tag.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const Padding(
              padding: EdgeInsets.only(bottom: Spacing.md),
              child: BottomSheetHandle(),
            ),
            // Topic header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: tag.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tag.description != null &&
                            tag.description!.isNotEmpty)
                          Text(
                            tag.description!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Book count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit topic'),
              onTap: () {
                Navigator.pop(context);
                _editTag(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Delete topic',
                style: TextStyle(color: colorScheme.error),
              ),
              subtitle: bookCount > 0
                  ? Text(
                      'Will be removed from $bookCount ${bookCount == 1 ? 'book' : 'books'}',
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteTag(context, bookCount);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editTag(BuildContext context) {
    final dataStore = context.read<DataStore>();

    AddTopicSheet.show(
      context,
      topic: tag,
      onSave: (name, description, colorHex) {
        dataStore.updateTag(
          tag.copyWith(
            name: name,
            description: description,
            colorHex: colorHex,
          ),
        );
      },
    );
  }

  void _confirmDeleteTag(BuildContext context, int bookCount) {
    final dataStore = context.read<DataStore>();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete topic?'),
        content: Text(
          bookCount > 0
              ? 'The topic "${tag.name}" is assigned to $bookCount ${bookCount == 1 ? 'book' : 'books'}. '
                    'It will be removed from all of them.'
              : 'The topic "${tag.name}" will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              dataStore.deleteTag(tag.id);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
