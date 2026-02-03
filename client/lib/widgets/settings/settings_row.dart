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
/// SettingsRow.toggle(
///   label: 'E-ink Mode',
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

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  /// Creates a settings row widget.
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.showChevron = true,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return isEinkMode ? _buildEinkRow(context) : _buildStandardRow(context);
  }

  Widget _buildStandardRow(BuildContext context) {
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

  Widget _buildEinkRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: TouchTargets.einkMin),
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (value != null)
                    Text(
                      value!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron && onTap != null)
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

/// A toggle setting row with a switch.
class SettingsToggleRow extends StatelessWidget {
  /// Primary label text.
  final String label;

  /// Current toggle value.
  final bool value;

  /// Called when the toggle value changes.
  final ValueChanged<bool>? onChanged;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  /// Creates a settings toggle row widget.
  const SettingsToggleRow({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return isEinkMode
        ? _buildEinkToggle(context)
        : _buildStandardToggle(context);
  }

  Widget _buildStandardToggle(BuildContext context) {
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

  Widget _buildEinkToggle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: TouchTargets.einkMin),
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildEinkSwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildEinkSwitch() {
    return Container(
      width: 56,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: value ? Colors.black : Colors.white,
              child: Center(
                child: value
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: value ? Colors.white : Colors.black,
              child: Center(
                child: !value
                    ? const Icon(Icons.close, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
