import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A card widget for displaying a note with title, content preview, and metadata.
///
/// Supports two display modes:
/// - **Standard**: Material Design 3 card with elevation and rounded corners
/// - **E-ink**: High-contrast styling with sharp corners and thick borders
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
///
/// For e-ink displays:
///
/// ```dart
/// NoteCard(
///   note: note,
///   isEinkMode: true,
///   onTap: () => _showNoteDetail(note),
/// )
/// ```
class NoteCard extends StatelessWidget {
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

  /// Whether to use e-ink optimized styling.
  final bool isEinkMode;

  /// Whether to show full content instead of preview.
  final bool showFullContent;

  /// Creates a note card widget.
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
    return isEinkMode
        ? _buildEinkCard(context)
        : _buildStandardCard(context);
  }

  /// Builds the standard Material Design 3 card.
  Widget _buildStandardCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: AppElevation.level1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context, colorScheme, textTheme),
              const Divider(height: Spacing.md),
              _buildContent(context, textTheme),
              if (note.hasTags) _buildTags(context, textTheme),
              const SizedBox(height: Spacing.sm),
              _buildMetadata(context, colorScheme, textTheme),
            ],
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
            note.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
    );
  }

  /// Content preview or full content.
  Widget _buildContent(BuildContext context, TextTheme textTheme) {
    return Text(
      showFullContent ? note.content : note.preview,
      style: textTheme.bodyMedium,
      maxLines: showFullContent ? null : 3,
      overflow: showFullContent ? null : TextOverflow.ellipsis,
    );
  }

  /// Tag chips section.
  Widget _buildTags(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: note.tags.map((tag) {
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
        if (note.hasLocation) ...[
          Icon(
            Icons.location_on_outlined,
            size: IconSizes.small,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(note.location!.shortLocation, style: metaStyle),
          const SizedBox(width: Spacing.md),
        ],
        Icon(
          Icons.access_time,
          size: IconSizes.small,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(note.dateLabel, style: metaStyle),
      ],
    );
  }

  /// Builds the e-ink optimized card with high-contrast styling.
  Widget _buildEinkCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            _buildEinkTitle(textTheme),
            const Divider(height: Spacing.md, thickness: 1, color: Colors.black),
            _buildEinkContent(textTheme),
            if (note.hasTags) _buildEinkTags(textTheme),
            const SizedBox(height: Spacing.sm),
            _buildEinkDate(textTheme),
          ],
        ),
      ),
    );
  }

  /// E-ink title with uppercase styling.
  Widget _buildEinkTitle(TextTheme textTheme) {
    return Text(
      note.title.toUpperCase(),
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  /// E-ink content with increased line height.
  Widget _buildEinkContent(TextTheme textTheme) {
    return Text(
      showFullContent ? note.content : note.preview,
      style: textTheme.bodyMedium?.copyWith(height: 1.5),
    );
  }

  /// E-ink tags displayed as plain text.
  Widget _buildEinkTags(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Text(
        'Tags: ${note.tags.join(", ")}',
        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
      ),
    );
  }

  /// E-ink date display.
  Widget _buildEinkDate(TextTheme textTheme) {
    return Text(
      note.dateLabel,
      style: textTheme.bodySmall?.copyWith(color: Colors.black54),
    );
  }
}
