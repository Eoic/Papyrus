import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A card widget for displaying a note with title, content preview, and metadata.
///
/// Uses Material Design 3 card with elevation and rounded corners.
///
/// ## Features
///
/// - Title with truncation for long text
/// - Content preview (first 3 lines) or full content
/// - Tag chips for categorization
/// - Location and date metadata
/// - Action menu (via long press or icon button)
///
/// ## Interactions
///
/// - **Tap**: Opens note details
/// - **Long press**: Shows action menu (edit, delete)
/// - **Menu icon**: Same as long press (desktop-friendly)
///
/// ## Example
///
/// ```dart
/// NoteCard(
///   note: note,
///   onTap: () => _showNoteDetail(note),
///   onLongPress: () => _showNoteActions(note),
/// )
/// ```
class NoteCard extends StatefulWidget {
  /// The note data to display.
  final Note note;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the edit action is triggered.
  final VoidCallback? onEdit;

  /// Called when the delete action is triggered.
  final VoidCallback? onDelete;

  /// Called when the card is long-pressed or menu icon is tapped.
  final VoidCallback? onLongPress;

  /// Whether to show full content instead of preview.
  final bool showFullContent;

  /// Whether to show the inline action menu (ellipsis button).
  final bool showActionMenu;

  /// Creates a note card widget.
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.showFullContent = false,
    this.showActionMenu = true,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: AppElevation.level1,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context, colorScheme, textTheme),
                const Divider(height: Spacing.md),
                _buildContent(context, textTheme),
                if (widget.note.hasTags) _buildTags(context, textTheme),
                const SizedBox(height: Spacing.sm),
                _buildMetadata(context, colorScheme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Title row with action menu button.
  Widget _buildTitleRow(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.note.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.showActionMenu)
          AnimatedOpacity(
            opacity: _isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              iconSize: IconSizes.action,
              onPressed: widget.onLongPress,
              tooltip: 'More options',
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }

  /// Content preview or full content.
  Widget _buildContent(BuildContext context, TextTheme textTheme) {
    return Text(
      widget.showFullContent ? widget.note.content : widget.note.preview,
      style: textTheme.bodyMedium,
      maxLines: widget.showFullContent ? null : 3,
      overflow: widget.showFullContent ? null : TextOverflow.ellipsis,
    );
  }

  /// Tag chips section.
  Widget _buildTags(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: widget.note.tags.map((tag) {
          return Chip(
            label: Text(tag),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            labelStyle: textTheme.labelSmall,
          );
        }).toList(),
      ),
    );
  }

  /// Location and date metadata row.
  Widget _buildMetadata(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final metaStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        if (widget.note.hasLocation) ...[
          Icon(
            Icons.location_on_outlined,
            size: IconSizes.small,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(widget.note.location!.shortLocation, style: metaStyle),
          const SizedBox(width: Spacing.md),
        ],
        Icon(
          Icons.access_time,
          size: IconSizes.small,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(widget.note.dateLabel, style: metaStyle),
      ],
    );
  }
}
