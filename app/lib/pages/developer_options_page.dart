import 'package:flutter/material.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/settings/settings_row.dart';
import 'package:papyrus/widgets/settings/settings_section.dart';
import 'package:provider/provider.dart';

/// Developer options page with debug-only settings.
///
/// This page is only accessible in debug mode and contains settings
/// useful for development and testing.
class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    if (displayMode.isEinkMode) return _buildEinkLayout(context);
    return _buildStandardLayout(context);
  }

  Widget _buildStandardLayout(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer options')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            const SettingsSectionHeader(title: 'Display'),
            SettingsToggleRow(
              label: 'E-ink display mode',
              value: displayMode.isEinkMode,
              onChanged: (_) => displayMode.toggleEinkMode(),
            ),
            const SizedBox(height: Spacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text(
                'Enable high-contrast mode optimized for e-ink displays. '
                'Removes animations and increases touch targets.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEinkLayout(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildEinkHeader(context),
          const Divider(color: Colors.black, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageMarginsEink),
              children: [
                const Text(
                  'DISPLAY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                const Divider(color: Colors.black87, height: 1),
                GestureDetector(
                  onTap: () => displayMode.toggleEinkMode(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: TouchTargets.einkMin,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tablet_android,
                          size: IconSizes.medium,
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'E-INK DISPLAY MODE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                displayMode.isEinkMode
                                    ? 'High contrast mode active'
                                    : 'Standard display mode',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildEinkToggle(displayMode.isEinkMode),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.black87, height: 1),
                const SizedBox(height: Spacing.md),
                const Text(
                  'Enable high-contrast mode optimized for e-ink displays. '
                  'Removes animations and increases touch targets.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkHeader(BuildContext context) {
    return Container(
      height: ComponentSizes.einkHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageMarginsEink),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: TouchTargets.einkMin,
              height: TouchTargets.einkMin,
              child: Center(
                child: Text(
                  '<',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          const Text(
            'DEVELOPER OPTIONS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkToggle(bool isOn) {
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
              color: isOn ? Colors.black : Colors.white,
              child: Center(
                child: isOn
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: isOn ? Colors.white : Colors.black,
              child: Center(
                child: !isOn
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
