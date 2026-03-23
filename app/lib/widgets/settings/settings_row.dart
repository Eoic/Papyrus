import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A row widget for displaying a setting with optional value and navigation.
///
/// Supports three variants:
/// - **Navigation**: Label + optional value + chevron
/// - **Toggle**: Label + switch
/// - **Value only**: Label + value (no interaction)
///
/// ## Example
///
/// ```dart
/// // Navigation row
/// SettingsRow(
///   label: 'Theme',
///   value: 'System default',
///   onTap: () => _showThemePicker(),
/// )
///
/// // Toggle row
/// SettingsToggleRow(
///   label: 'E-ink mode',
///   value: isEinkMode,
///   onChanged: (value) => _toggleEinkMode(value),
/// )
///
/// // Value only row
/// SettingsRow(
///   label: 'Version',
///   value: '1.0.0',
///   showChevron: false,
/// )
/// ```
class SettingsRow extends StatelessWidget {
  /// Primary label text.
  final String label;

  /// Optional value text displayed below or to the right of label.
  final String? value;

  /// Called when the row is tapped (for navigation rows).
  final VoidCallback? onTap;

  /// Whether to show the trailing chevron.
  final bool showChevron;

  /// Creates a settings row widget.
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: value != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: textTheme.bodyLarge),
                          const SizedBox(height: 2),
                          Text(
                            value!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Text(label, style: textTheme.bodyLarge),
              ),
              if (showChevron && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: IconSizes.medium,
                )
              else if (value != null && !showChevron)
                Text(
                  value!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A toggle setting row with a switch.
class SettingsToggleRow extends StatelessWidget {
  /// Primary label text.
  final String label;

  /// Current toggle value.
  final bool value;

  /// Called when the toggle value changes.
  final ValueChanged<bool>? onChanged;

  /// Creates a settings toggle row widget.
  const SettingsToggleRow({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
