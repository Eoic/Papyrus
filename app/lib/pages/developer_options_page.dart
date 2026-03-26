import 'package:flutter/material.dart';
import 'package:papyrus/providers/preferences_provider.dart';
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
    final prefs = context.watch<PreferencesProvider>();

    if (prefs.isEinkMode) return _buildEinkLayout(context);
    return _buildStandardLayout(context);
  }

  Widget _buildStandardLayout(BuildContext context) {
    context.watch<PreferencesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer options')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [],
        ),
      ),
    );
  }

  Widget _buildEinkLayout(BuildContext context) {
    context.watch<PreferencesProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildEinkHeader(context),
          const Divider(color: Colors.black, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageMarginsEink),
              children: [],
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
