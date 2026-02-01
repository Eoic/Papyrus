import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Card widget for displaying a note.
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool isEinkMode;
  final bool showFullContent;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.isEinkMode = false,
    this.showFullContent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) {
      return _buildEinkCard(context);
    }
    return _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: AppElevation.level1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Action button
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: IconSizes.small,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: onLongPress,
                    tooltip: 'More options',
                  ),
                ],
              ),
              const Divider(height: Spacing.md),

              // Content preview or full content
              Text(
                showFullContent ? note.content : note.preview,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: showFullContent ? null : 3,
                overflow: showFullContent ? null : TextOverflow.ellipsis,
              ),

              // Tags
              if (note.hasTags) ...[
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: note.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: Spacing.sm),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                    );
                  }).toList(),
                ),
              ],

              // Location and date
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  if (note.hasLocation) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: IconSizes.small,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.location!.shortLocation,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: Spacing.md),
                  ],
                  Icon(
                    Icons.access_time,
                    size: IconSizes.small,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note.dateLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEinkCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              note.title.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
            const Divider(
              height: Spacing.md,
              thickness: 1,
              color: Colors.black,
            ),

            // Content
            Text(
              showFullContent ? note.content : note.preview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),

            // Tags (as text list for e-ink)
            if (note.hasTags) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'Tags: ${note.tags.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],

            // Date
            const SizedBox(height: Spacing.sm),
            Text(
              note.dateLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
