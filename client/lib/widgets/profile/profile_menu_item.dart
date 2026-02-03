import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A menu item widget for the profile page navigation.
///
/// Supports three display modes:
/// - **Standard**: Material Design 3 styling with icon container
/// - **Desktop**: Hover-aware styling for mouse interaction
/// - **E-ink**: High-contrast styling with uppercase text
///
/// ## Features
///
/// - Leading icon in a circular container
/// - Main label text
/// - Optional subtitle/value text
/// - Trailing chevron (optional)
/// - Special styling for destructive actions (logout, delete)
///
/// ## Example
///
/// ```dart
/// ProfileMenuItem(
///   icon: Icons.settings,
///   label: 'Settings',
///   onTap: () => context.push('/settings'),
/// )
///
/// // Destructive action
/// ProfileMenuItem(
///   icon: Icons.logout,
///   label: 'Log out',
///   isDestructive: true,
///   showChevron: false,
///   onTap: () => _handleLogout(),
/// )
/// ```
class ProfileMenuItem extends StatelessWidget {
  /// Icon displayed in the leading container.
  final IconData icon;

  /// Primary label text.
  final String label;

  /// Optional secondary text displayed below label or to the right.
  final String? subtitle;

  /// Called when the item is tapped.
  final VoidCallback? onTap;

  /// Whether to show the trailing chevron.
  final bool showChevron;

  /// Whether this is a destructive action (uses error color).
  final bool isDestructive;

  /// Whether to use e-ink optimized styling.
  final bool isEinkMode;

  /// Creates a profile menu item widget.
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.isDestructive = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return isEinkMode
        ? _buildEinkMenuItem(context)
        : _buildStandardMenuItem(context);
  }

  /// Standard Material Design 3 menu item.
  Widget _buildStandardMenuItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final contentColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;
    final iconContainerColor = isDestructive
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHighest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              _buildIconContainer(iconContainerColor, contentColor),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: subtitle != null
                    ? _buildTwoLineContent(textTheme, contentColor, colorScheme)
                    : Text(
                        label,
                        style: textTheme.bodyLarge?.copyWith(
                          color: contentColor,
                        ),
                      ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: IconSizes.medium,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon container with circular background.
  Widget _buildIconContainer(Color backgroundColor, Color iconColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: IconSizes.medium),
    );
  }

  /// Two-line content with label and subtitle.
  Widget _buildTwoLineContent(
    TextTheme textTheme,
    Color labelColor,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.bodyLarge?.copyWith(color: labelColor)),
        Text(
          subtitle!,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// E-ink optimized menu item.
  Widget _buildEinkMenuItem(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Row(
          children: [
            Expanded(
              child: subtitle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          subtitle!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      label.toUpperCase(),
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            if (showChevron)
              const Text(
                '>',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

/// A card container for grouping profile menu items.
///
/// Provides consistent styling for menu sections on desktop.
class ProfileMenuCard extends StatelessWidget {
  /// Title displayed at the top of the card.
  final String? title;

  /// Child widgets (typically ProfileMenuItem widgets).
  final List<Widget> children;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  /// Creates a profile menu card widget.
  const ProfileMenuCard({
    super.key,
    this.title,
    required this.children,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkCard(context);
    return _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.md,
                Spacing.sm,
              ),
              child: Text(
                title!,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEinkCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
