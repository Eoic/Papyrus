import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/settings/settings_row.dart';
import 'package:papyrus/widgets/settings/settings_section.dart';
import 'package:provider/provider.dart';

/// Settings page with app configuration options.
///
/// Provides two responsive layouts:
/// - **Mobile**: Scrollable list with section headers
/// - **Desktop**: Two-column grid of settings cards
///
/// ## Sections
///
/// - **Appearance**: Theme selection, E-ink mode toggle
/// - **Reading**: Default font, font size, reading profiles
/// - **Storage & Sync**: Storage backend, sync settings
/// - **Notifications**: Goal reminders, streak alerts
/// - **About**: Version info, licenses, support
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  String _selectedTheme = 'system';
  String _selectedFont = 'Georgia';
  double _fontSize = 16;
  bool _goalReminders = true;
  bool _streakAlerts = true;
  bool _syncStatus = false;
  bool _newBooks = true;
  String _storageBackend = 'Local';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          children: [
            _buildAppearanceSection(context),
            _buildReadingSection(context),
            _buildStorageSyncSection(context),
            _buildNotificationsSection(context),
            _buildAboutSection(context),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Appearance'),
        SettingsRow(
          label: 'Theme',
          value: _getThemeLabel(_selectedTheme),
          onTap: () => _showThemePicker(context),
        ),
        SettingsToggleRow(
          label: 'E-ink mode',
          value: displayMode.isEinkMode,
          onChanged: (_) => displayMode.toggleEinkMode(),
        ),
      ],
    );
  }

  Widget _buildReadingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Reading'),
        SettingsRow(
          label: 'Default font',
          value: _selectedFont,
          onTap: () => _showFontPicker(context),
        ),
        SettingsRow(label: 'Reading profiles', onTap: () {}),
      ],
    );
  }

  Widget _buildStorageSyncSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Storage & Sync'),
        SettingsRow(
          label: 'Storage backend',
          value: _storageBackend,
          onTap: () => _showStoragePicker(context),
        ),
        SettingsRow(label: 'Sync settings', onTap: () {}),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Notifications'),
        SettingsToggleRow(
          label: 'Goal reminders',
          value: _goalReminders,
          onChanged: (value) => setState(() => _goalReminders = value),
        ),
        SettingsToggleRow(
          label: 'Reading streak',
          value: _streakAlerts,
          onChanged: (value) => setState(() => _streakAlerts = value),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'About'),
        SettingsRow(label: 'Version', value: '1.0.0', showChevron: false),
        SettingsRow(label: 'Licenses', onTap: () => _showLicenses(context)),
      ],
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              _buildDesktopGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGrid(BuildContext context) {
    return Column(
      children: [
        // First row: Appearance + Reading
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDesktopAppearanceCard(context)),
            const SizedBox(width: Spacing.lg),
            Expanded(child: _buildDesktopReadingCard(context)),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        // Second row: Storage + Notifications
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDesktopStorageCard(context)),
            const SizedBox(width: Spacing.lg),
            Expanded(child: _buildDesktopNotificationsCard(context)),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        // Third row: About (full width)
        _buildDesktopAboutCard(context),
      ],
    );
  }

  Widget _buildDesktopAppearanceCard(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return SettingsCard(
      title: 'Appearance',
      children: [
        _buildThemeRadioGroup(context),
        const SizedBox(height: Spacing.md),
        SettingsToggleRow(
          label: 'E-ink mode',
          value: displayMode.isEinkMode,
          onChanged: (_) => displayMode.toggleEinkMode(),
        ),
      ],
    );
  }

  Widget _buildThemeRadioGroup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _buildRadioTile('Light', 'light'),
        _buildRadioTile('System', 'system'),
        _buildRadioTile('Dark', 'dark'),
      ],
    );
  }

  Widget _buildRadioTile(String label, String value) {
    final isSelected = _selectedTheme == value;

    return InkWell(
      onTap: () => setState(() => _selectedTheme = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.md),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopReadingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsCard(
      title: 'Reading preferences',
      children: [
        // Font dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default font',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            DropdownMenu<String>(
              initialSelection: _selectedFont,
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries:
                  ['Georgia', 'Literata', 'Bookerly', 'Open Dyslexic']
                      .map(
                        (font) => DropdownMenuEntry(value: font, label: font),
                      )
                      .toList(),
              onSelected: (value) {
                if (value != null) {
                  setState(() => _selectedFont = value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // Font size slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default font size',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${_fontSize.toInt()}px',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        SettingsRow(label: 'Reading profiles', onTap: () {}),
      ],
    );
  }

  Widget _buildDesktopStorageCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsCard(
      title: 'Storage & Sync',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage backend',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            DropdownMenu<String>(
              initialSelection: _storageBackend,
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: ['Local', 'Cloud', 'Self-hosted']
                  .map(
                    (backend) =>
                        DropdownMenuEntry(value: backend, label: backend),
                  )
                  .toList(),
              onSelected: (value) {
                if (value != null) {
                  setState(() => _storageBackend = value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SettingsRow(label: 'Sync server', onTap: () {}),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          child: Text(
            'Last sync: 2 min ago',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Sync now'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNotificationsCard(BuildContext context) {
    return SettingsCard(
      title: 'Notifications',
      children: [
        SettingsToggleRow(
          label: 'Goal reminders',
          value: _goalReminders,
          onChanged: (value) => setState(() => _goalReminders = value),
        ),
        SettingsToggleRow(
          label: 'Streak alerts',
          value: _streakAlerts,
          onChanged: (value) => setState(() => _streakAlerts = value),
        ),
        SettingsToggleRow(
          label: 'Sync status',
          value: _syncStatus,
          onChanged: (value) => setState(() => _syncStatus = value),
        ),
        SettingsToggleRow(
          label: 'New books',
          value: _newBooks,
          onChanged: (value) => setState(() => _newBooks = value),
        ),
      ],
    );
  }

  Widget _buildDesktopAboutCard(BuildContext context) {
    return SettingsCard(
      title: 'About',
      children: [
        Row(
          children: [
            Expanded(
              child: SettingsRow(
                label: 'Version',
                value: '1.0.0',
                showChevron: false,
              ),
            ),
            Expanded(
              child: SettingsRow(
                label: 'Licenses',
                onTap: () => _showLicenses(context),
              ),
            ),
            Expanded(
              child: SettingsRow(label: 'Support', onTap: () {}),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // DIALOGS & PICKERS
  // ============================================================================

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System default';
    }
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPickerTile(
              context: sheetContext,
              title: 'Light',
              isSelected: _selectedTheme == 'light',
              onTap: () {
                setState(() => _selectedTheme = 'light');
                Navigator.pop(sheetContext);
              },
            ),
            _buildPickerTile(
              context: sheetContext,
              title: 'System default',
              isSelected: _selectedTheme == 'system',
              onTap: () {
                setState(() => _selectedTheme = 'system');
                Navigator.pop(sheetContext);
              },
            ),
            _buildPickerTile(
              context: sheetContext,
              title: 'Dark',
              isSelected: _selectedTheme == 'dark',
              onTap: () {
                setState(() => _selectedTheme = 'dark');
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(title),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
      onTap: onTap,
    );
  }

  void _showFontPicker(BuildContext context) {
    final fonts = ['Georgia', 'Literata', 'Bookerly', 'Open Dyslexic'];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts
              .map(
                (font) => _buildPickerTile(
                  context: sheetContext,
                  title: font,
                  isSelected: _selectedFont == font,
                  onTap: () {
                    setState(() => _selectedFont = font);
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showStoragePicker(BuildContext context) {
    final backends = ['Local', 'Cloud', 'Self-hosted'];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: backends
              .map(
                (backend) => _buildPickerTile(
                  context: sheetContext,
                  title: backend,
                  isSelected: _storageBackend == backend,
                  onTap: () {
                    setState(() => _storageBackend = backend);
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Papyrus',
      applicationVersion: '1.0.0',
    );
  }
}
