import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A section header for settings pages.
///
/// Provides consistent styling for section titles across all display modes.
class SettingsSectionHeader extends StatelessWidget {
  /// Section title text.
  final String title;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  /// Creates a settings section header.
  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isEinkMode) {
      return Padding(
        padding: const EdgeInsets.only(
          top: Spacing.lg,
          bottom: Spacing.sm,
        ),
        child: Text(
          title.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: Spacing.lg,
        bottom: Spacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A card container for settings sections on desktop.
class SettingsCard extends StatelessWidget {
  /// Card title.
  final String? title;

  /// Child widgets.
  final List<Widget> children;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  /// Creates a settings card widget.
  const SettingsCard({
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
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildEinkCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.black, height: Spacing.md),
          ],
          ...children,
        ],
      ),
    );
  }
}
