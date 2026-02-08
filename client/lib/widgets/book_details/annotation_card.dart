import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A card widget for displaying a book annotation (highlight).
///
/// Uses Material Design 3 card with colored accent border.
///
/// ## Features
///
/// - Colored accent indicator matching highlight color
/// - Quoted highlight text with italic styling
/// - Optional note attached to highlight
/// - Location and date metadata
/// - Action menu (via long press or icon button)
///
/// ## Visual Design
///
/// The card includes a colored left border that matches the annotation's
/// highlight color, providing visual categorization. A small color dot in
/// the header reinforces the color association.
///
/// ## Interactions
///
/// - **Tap**: Opens annotation details
/// - **Long press**: Shows action menu (edit note, delete)
/// - **Menu icon**: Same as long press (desktop-friendly)
///
/// ## Example
///
/// ```dart
/// AnnotationCard(
///   annotation: annotation,
///   onTap: () => _showAnnotationDetail(annotation),
///   onLongPress: () => _showAnnotationActions(annotation),
/// )
/// ```
class AnnotationCard extends StatelessWidget {
  /// The annotation data to display.
  final Annotation annotation;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the card is long-pressed or menu icon is tapped.
  final VoidCallback? onLongPress;

  /// Whether to show the inline action menu (ellipsis button).
  final bool showActionMenu;

  /// Creates an annotation card widget.
  const AnnotationCard({
    super.key,
    required this.annotation,
    this.onTap,
    this.onLongPress,
    this.showActionMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = annotation.color.accentColor;

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
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colorScheme, textTheme, accentColor),
                const SizedBox(height: Spacing.sm),
                _buildHighlightText(textTheme),
                if (annotation.hasNote) _buildNote(colorScheme, textTheme),
                const SizedBox(height: Spacing.sm),
                _buildDate(colorScheme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header row with color indicator, location, and action menu.
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color accentColor,
  ) {
    return Row(
      children: [
        _buildColorDot(accentColor),
        const SizedBox(width: Spacing.sm),
        Text(
          annotation.location.shortLocation,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (showActionMenu) _buildActionMenu(colorScheme),
      ],
    );
  }

  /// Small colored dot indicating highlight color.
  Widget _buildColorDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  /// Quoted highlight text with italic styling.
  Widget _buildHighlightText(TextTheme textTheme) {
    return Text(
      '"${annotation.highlightText}"',
      style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
    );
  }

  /// Optional note container with background.
  Widget _buildNote(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(annotation.note!, style: textTheme.bodyMedium),
      ),
    );
  }

  /// Date metadata.
  Widget _buildDate(ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      _formatDate(annotation.createdAt),
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Formats a date as "Mon DD, YYYY".
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
