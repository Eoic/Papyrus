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
class AnnotationCard extends StatefulWidget {
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
  State<AnnotationCard> createState() => _AnnotationCardState();
}

class _AnnotationCardState extends State<AnnotationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = widget.annotation.color.accentColor;

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
                  if (widget.annotation.hasNote)
                    _buildNote(colorScheme, textTheme),
                  const SizedBox(height: Spacing.sm),
                  _buildDate(colorScheme, textTheme),
                ],
              ),
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
          widget.annotation.location.shortLocation,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (widget.showActionMenu) _buildActionMenu(colorScheme),
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
  /// Shown only on mouse hover with animated opacity.
  Widget _buildActionMenu(ColorScheme colorScheme) {
    return AnimatedOpacity(
      opacity: _isHovered ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: IconButton(
        icon: const Icon(Icons.more_vert),
        iconSize: IconSizes.action,
        onPressed: widget.onLongPress,
        tooltip: 'More options',
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// Quoted highlight text with italic styling.
  Widget _buildHighlightText(TextTheme textTheme) {
    return Text(
      '"${widget.annotation.highlightText}"',
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
        child: Text(widget.annotation.note!, style: textTheme.bodyMedium),
      ),
    );
  }

  /// Date metadata.
  Widget _buildDate(ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      _formatDate(widget.annotation.createdAt),
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
