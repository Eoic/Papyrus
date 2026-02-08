import 'package:flutter/material.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A card widget for displaying a single bookmark.
///
/// Uses Material Design 3 card with colored left border accent,
/// following the same pattern as [AnnotationCard].
///
/// ## Interactions
///
/// - **Tap**: Opens bookmark details
/// - **Long press**: Shows action menu (edit note, change color, delete)
/// - **Menu icon**: Same as long press (desktop-friendly)
class BookmarkListItem extends StatelessWidget {
  final Bookmark bookmark;
  final String bookTitle;
  final VoidCallback? onTap;

  /// Called when the card is long-pressed or menu icon is tapped.
  final VoidCallback? onLongPress;

  /// Whether to show the inline action menu (ellipsis button).
  final bool showActionMenu;

  const BookmarkListItem({
    super.key,
    required this.bookmark,
    required this.bookTitle,
    this.onTap,
    this.onLongPress,
    this.showActionMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: AppElevation.level1,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: bookmark.color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme, textTheme),
                if (bookmark.hasNote) ...[
                  const SizedBox(height: Spacing.sm),
                  _buildNote(colorScheme, textTheme),
                  const SizedBox(height: Spacing.sm),
                ],
                _buildDate(colorScheme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: bookmark.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            bookmark.displayLocation,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showActionMenu) _buildActionMenu(colorScheme),
      ],
    );
  }

  /// Icon button that triggers the action menu via onLongPress.
  Widget _buildActionMenu(ColorScheme colorScheme) {
    return IconButton(
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
    );
  }

  Widget _buildNote(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note_outlined,
            size: IconSizes.small,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              bookmark.note!,
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDate(ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      formatRelativeDate(bookmark.createdAt),
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Formats a date as a relative string like "2 hours ago".
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    if (diff.inDays < 365) {
      final m = diff.inDays ~/ 30;
      return '$m ${m == 1 ? 'month' : 'months'} ago';
    }
    final y = diff.inDays ~/ 365;
    return '$y ${y == 1 ? 'year' : 'years'} ago';
  }
}
