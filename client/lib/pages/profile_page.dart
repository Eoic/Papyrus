import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/settings/settings_row.dart';
import 'package:papyrus/widgets/settings/settings_section.dart';
import 'package:provider/provider.dart';

enum _ProfileSection {
  account,
  appearance,
  reading,
  library,
  notifications,
  storageSync,
  privacyData,
  accessibility,
  about,
  developerOptions,
}

/// User profile page with account settings, preferences, and app configuration.
///
/// Mobile: AppBar with title, inline settings sections.
/// Desktop: Sidebar nav + content panel (similar to GitHub Settings).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _ProfileSection _selectedSection = _ProfileSection.account;

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
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _buildMobileHeader(context),
            _buildMobileAccountSection(context),
            _buildMobileAppearanceSection(context),
            _buildMobileReadingSection(context),
            _buildMobileLibrarySection(context),
            _buildMobileNotificationsSection(context),
            _buildMobileStorageSyncSection(context),
            _buildMobilePrivacyDataSection(context),
            _buildMobileAccessibilitySection(context),
            _buildMobileAboutSection(context),
            if (kDebugMode) _buildMobileDeveloperSection(context),
            const Divider(height: 1),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              label: 'Log out',
              isDestructive: true,
              showChevron: false,
              onTap: () => _showLogoutConfirmation(context),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Account'),
        SettingsRow(label: 'Change password', onTap: () {}),
        SettingsRow(label: 'Linked accounts', onTap: () {}),
        SettingsRow(label: 'Two-factor authentication', onTap: () {}),
        SettingsRow(label: 'Active sessions', onTap: () {}),
        SettingsRow(label: 'Delete account', onTap: () {}),
      ],
    );
  }

  Widget _buildMobileAppearanceSection(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Appearance'),
        SettingsRow(
          label: 'Theme',
          value: _getThemeLabel(prefs.themeModePref),
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

  Widget _buildMobileReadingSection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Reading'),
        SettingsRow(
          label: 'Default font',
          value: prefs.defaultFont,
          onTap: () => _showFontPicker(context),
        ),
        SettingsRow(
          label: 'Line spacing',
          value: _capitalize(prefs.lineSpacing),
          onTap: () => _showLineSpacingPicker(context),
        ),
        SettingsRow(
          label: 'Reading mode',
          value: _capitalize(prefs.readingMode),
          onTap: () => _showReadingModePicker(context),
        ),
        SettingsToggleRow(
          label: 'Page turn animation',
          value: prefs.pageTurnAnimation,
          onChanged: (value) => prefs.pageTurnAnimation = value,
        ),
        SettingsRow(label: 'Reading profiles', onTap: () {}),
      ],
    );
  }

  Widget _buildMobileLibrarySection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Library'),
        SettingsRow(
          label: 'Default view',
          value: _capitalize(prefs.defaultViewMode),
          onTap: () => _showViewModePicker(context),
        ),
        SettingsRow(
          label: 'Default sort',
          value: _getSortOrderLabel(prefs.defaultSortOrder),
          onTap: () => _showSortOrderPicker(context),
        ),
        SettingsRow(
          label: 'Metadata source',
          value: prefs.metadataSource,
          onTap: () => _showMetadataSourcePicker(context),
        ),
        SettingsRow(
          label: 'Export format',
          value: prefs.annotationExportFormat,
          onTap: () => _showExportFormatPicker(context),
        ),
      ],
    );
  }

  Widget _buildMobileNotificationsSection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Notifications'),
        SettingsToggleRow(
          label: 'Goal reminders',
          value: prefs.goalReminders,
          onChanged: (value) => prefs.goalReminders = value,
        ),
        SettingsToggleRow(
          label: 'Streak alerts',
          value: prefs.streakAlerts,
          onChanged: (value) => prefs.streakAlerts = value,
        ),
        SettingsToggleRow(
          label: 'Sync status',
          value: prefs.syncStatusNotifications,
          onChanged: (value) => prefs.syncStatusNotifications = value,
        ),
      ],
    );
  }

  Widget _buildMobileStorageSyncSection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Storage & sync'),
        SettingsRow(
          label: 'Storage backend',
          value: prefs.storageBackend,
          onTap: () => _showStoragePicker(context),
        ),
        SettingsRow(
          label: 'Sync server',
          value: prefs.serverUrl.isEmpty ? 'Not connected' : prefs.serverUrl,
          onTap: () {},
        ),
        SettingsToggleRow(
          label: 'Sync enabled',
          value: prefs.syncEnabled,
          onChanged: (value) => prefs.syncEnabled = value,
        ),
      ],
    );
  }

  Widget _buildMobilePrivacyDataSection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Privacy & data'),
        SettingsToggleRow(
          label: 'Analytics',
          value: prefs.analyticsOptIn,
          onChanged: (value) => prefs.analyticsOptIn = value,
        ),
        SettingsRow(label: 'Privacy policy', onTap: () {}),
        SettingsRow(label: 'Export all data', onTap: () {}),
        SettingsRow(label: 'Import data', onTap: () {}),
        SettingsRow(label: 'Clear local data', onTap: () {}),
      ],
    );
  }

  Widget _buildMobileAccessibilitySection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Accessibility'),
        SettingsToggleRow(
          label: 'Reduce animations',
          value: prefs.reduceAnimations,
          onChanged: (value) => prefs.reduceAnimations = value,
        ),
        SettingsToggleRow(
          label: 'Dyslexia-friendly font',
          value: prefs.dyslexiaFont,
          onChanged: (value) => prefs.dyslexiaFont = value,
        ),
      ],
    );
  }

  Widget _buildMobileAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'About'),
        SettingsRow(label: 'Version', value: '1.0.0', showChevron: false),
        SettingsRow(label: 'Licenses', onTap: () => _showLicenses(context)),
        SettingsRow(label: 'Support', onTap: () {}),
        SettingsRow(label: "What's new", onTap: () {}),
        SettingsRow(label: 'GitHub repository', onTap: () {}),
      ],
    );
  }

  Widget _buildMobileDeveloperSection(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Developer options'),
        SettingsToggleRow(
          label: 'E-ink display mode',
          value: displayMode.isEinkMode,
          onChanged: (_) => displayMode.toggleEinkMode(),
        ),
        SettingsRow(label: 'Reload sample data', onTap: () {}),
        SettingsRow(label: 'Reset onboarding', onTap: () {}),
        SettingsRow(label: 'Performance overlay', onTap: () {}),
      ],
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _buildDesktopNav(context),
            const VerticalDivider(width: 1),
            Expanded(child: _buildDesktopContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNav(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 240,
      child: Column(
        children: [
          _buildNavHeader(context),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Column(
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'Account',
                    section: _ProfileSection.account,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    section: _ProfileSection.appearance,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.auto_stories_outlined,
                    label: 'Reading',
                    section: _ProfileSection.reading,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.library_books_outlined,
                    label: 'Library',
                    section: _ProfileSection.library,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    section: _ProfileSection.notifications,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.cloud_outlined,
                    label: 'Storage & sync',
                    section: _ProfileSection.storageSync,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.shield_outlined,
                    label: 'Privacy & data',
                    section: _ProfileSection.privacyData,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.accessibility_outlined,
                    label: 'Accessibility',
                    section: _ProfileSection.accessibility,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.info_outline,
                    label: 'About',
                    section: _ProfileSection.about,
                  ),
                  if (kDebugMode)
                    _buildNavItem(
                      context,
                      icon: Icons.code,
                      label: 'Developer options',
                      section: _ProfileSection.developerOptions,
                    ),
                  const SizedBox(height: Spacing.md),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _buildNavItem(
                    context,
                    icon: Icons.logout,
                    label: 'Log out',
                    isDestructive: true,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          _buildAvatar(context, size: 48),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getEmail(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    _ProfileSection? section,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = section != null && _selectedSection == section;

    final iconColor = isDestructive
        ? colorScheme.error
        : isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final textColor = isDestructive
        ? colorScheme.error
        : isSelected
        ? colorScheme.onPrimaryContainer
        : null;
    final bgColor = isSelected
        ? colorScheme.primaryContainer
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap:
              onTap ??
              () {
                if (section != null) {
                  setState(() => _selectedSection = section);
                }
              },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: IconSizes.medium),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP CONTENT PANEL
  // ============================================================================

  Widget _buildDesktopContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_sectionTitle, style: textTheme.headlineMedium),
              const SizedBox(height: Spacing.lg),
              _buildSectionContent(context),
            ],
          ),
        ),
      ),
    );
  }

  String get _sectionTitle {
    switch (_selectedSection) {
      case _ProfileSection.account:
        return 'Account';
      case _ProfileSection.appearance:
        return 'Appearance';
      case _ProfileSection.reading:
        return 'Reading';
      case _ProfileSection.library:
        return 'Library';
      case _ProfileSection.notifications:
        return 'Notifications';
      case _ProfileSection.storageSync:
        return 'Storage & sync';
      case _ProfileSection.privacyData:
        return 'Privacy & data';
      case _ProfileSection.accessibility:
        return 'Accessibility';
      case _ProfileSection.about:
        return 'About';
      case _ProfileSection.developerOptions:
        return 'Developer options';
    }
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (_selectedSection) {
      case _ProfileSection.account:
        return _buildAccountContent(context);
      case _ProfileSection.appearance:
        return _buildAppearanceContent(context);
      case _ProfileSection.reading:
        return _buildReadingContent(context);
      case _ProfileSection.library:
        return _buildLibraryContent(context);
      case _ProfileSection.notifications:
        return _buildNotificationsContent(context);
      case _ProfileSection.storageSync:
        return _buildStorageSyncContent(context);
      case _ProfileSection.privacyData:
        return _buildPrivacyDataContent(context);
      case _ProfileSection.accessibility:
        return _buildAccessibilityContent(context);
      case _ProfileSection.about:
        return _buildAboutContent(context);
      case _ProfileSection.developerOptions:
        return _buildDeveloperOptionsContent(context);
    }
  }

  // -- Account ----------------------------------------------------------------

  Widget _buildAccountContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          children: [
            Row(
              children: [
                _buildAvatar(context, size: 96),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getDisplayName(), style: textTheme.headlineSmall),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        _getEmail(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () => _navigateToEditProfile(context),
                          child: const Text('Edit profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Security',
          children: [
            SettingsRow(label: 'Change password', onTap: () {}),
            SettingsRow(label: 'Two-factor authentication', onTap: () {}),
            SettingsRow(label: 'Active sessions', onTap: () {}),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Connected accounts',
          children: [
            SettingsRow(
              label: 'Google',
              value: _isGoogleLinked() ? 'Connected' : 'Not connected',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Danger zone',
          children: [SettingsRow(label: 'Delete account', onTap: () {})],
        ),
      ],
    );
  }

  // -- Appearance -------------------------------------------------------------

  Widget _buildAppearanceContent(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return SettingsCard(
      children: [
        _buildThemeRadioGroup(context),
        const SizedBox(height: Spacing.lg),
        SettingsToggleRow(
          label: 'E-ink mode',
          value: displayMode.isEinkMode,
          onChanged: (_) => displayMode.toggleEinkMode(),
        ),
      ],
    );
  }

  Widget _buildThemeRadioGroup(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
    final prefs = context.watch<PreferencesProvider>();
    final isSelected = prefs.themeModePref == value;

    return InkWell(
      onTap: () => prefs.themeModePref = value,
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

  // -- Reading ----------------------------------------------------------------

  Widget _buildReadingContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          title: 'Typography',
          children: [
            _buildDropdownField(
              context,
              label: 'Default font',
              value: prefs.defaultFont,
              options: [
                'Georgia',
                'Literata',
                'Bookerly',
                'Merriweather',
                'Noto Serif',
                'Atkinson Hyperlegible',
                'Open Dyslexic',
              ],
              onChanged: (value) => prefs.defaultFont = value,
            ),
            const SizedBox(height: Spacing.lg),
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
                    value: prefs.defaultFontSize,
                    min: 10,
                    max: 32,
                    divisions: 22,
                    onChanged: (value) => prefs.defaultFontSize = value,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${prefs.defaultFontSize.toInt()}px',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _buildSegmentedField<String>(
              context,
              label: 'Line spacing',
              value: prefs.lineSpacing,
              options: const {
                'compact': 'Compact',
                'normal': 'Normal',
                'relaxed': 'Relaxed',
              },
              onChanged: (value) => prefs.lineSpacing = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildSegmentedField<String>(
              context,
              label: 'Text alignment',
              value: prefs.textAlignment,
              options: const {'left': 'Left', 'justify': 'Justify'},
              onChanged: (value) => prefs.textAlignment = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildSegmentedField<String>(
              context,
              label: 'Margins',
              value: prefs.margins,
              options: const {
                'small': 'Small',
                'medium': 'Medium',
                'large': 'Large',
              },
              onChanged: (value) => prefs.margins = value,
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Behavior',
          children: [
            _buildSegmentedField<String>(
              context,
              label: 'Reading mode',
              value: prefs.readingMode,
              options: const {
                'paginated': 'Paginated',
                'scroll': 'Continuous scroll',
              },
              onChanged: (value) => prefs.readingMode = value,
            ),
            const SizedBox(height: Spacing.md),
            SettingsToggleRow(
              label: 'Page turn animation',
              value: prefs.pageTurnAnimation,
              onChanged: (value) => prefs.pageTurnAnimation = value,
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Annotations',
          children: [_buildHighlightColorField(context)],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          children: [SettingsRow(label: 'Reading profiles', onTap: () {})],
        ),
      ],
    );
  }

  Widget _buildHighlightColorField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefs = context.watch<PreferencesProvider>();

    const highlightColors = {
      'yellow': Color(0xFFFFF176),
      'green': Color(0xFFA5D6A7),
      'blue': Color(0xFF90CAF9),
      'pink': Color(0xFFF48FB1),
      'orange': Color(0xFFFFCC80),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default highlight color',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: highlightColors.entries.map((entry) {
            final isSelected = prefs.defaultHighlightColor == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: GestureDetector(
                onTap: () => prefs.defaultHighlightColor = entry.key,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: colorScheme.primary, width: 3)
                        : Border.all(color: colorScheme.outline, width: 1),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 18, color: colorScheme.primary)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -- Library ----------------------------------------------------------------

  Widget _buildLibraryContent(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          title: 'Display',
          children: [
            _buildSegmentedField<String>(
              context,
              label: 'Default view mode',
              value: prefs.defaultViewMode,
              options: const {
                'grid': 'Grid',
                'list': 'List',
                'compact': 'Compact',
              },
              onChanged: (value) => prefs.defaultViewMode = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildDropdownField(
              context,
              label: 'Default sort order',
              value: prefs.defaultSortOrder,
              options: const [
                'title',
                'author',
                'date_added',
                'last_read',
                'rating',
              ],
              labels: const {
                'title': 'Title',
                'author': 'Author',
                'date_added': 'Date added',
                'last_read': 'Last read',
                'rating': 'Rating',
              },
              onChanged: (value) => prefs.defaultSortOrder = value,
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Data',
          children: [
            _buildSegmentedField<String>(
              context,
              label: 'Metadata source',
              value: prefs.metadataSource,
              options: const {
                'Open Library': 'Open Library',
                'Google Books': 'Google Books',
              },
              onChanged: (value) => prefs.metadataSource = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildDropdownField(
              context,
              label: 'Annotation export format',
              value: prefs.annotationExportFormat,
              options: const ['Markdown', 'PDF', 'TXT', 'HTML'],
              onChanged: (value) => prefs.annotationExportFormat = value,
            ),
          ],
        ),
      ],
    );
  }

  // -- Notifications ----------------------------------------------------------

  Widget _buildNotificationsContent(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return SettingsCard(
      children: [
        SettingsToggleRow(
          label: 'Goal reminders',
          value: prefs.goalReminders,
          onChanged: (value) => prefs.goalReminders = value,
        ),
        SettingsToggleRow(
          label: 'Streak alerts',
          value: prefs.streakAlerts,
          onChanged: (value) => prefs.streakAlerts = value,
        ),
        SettingsToggleRow(
          label: 'Sync status',
          value: prefs.syncStatusNotifications,
          onChanged: (value) => prefs.syncStatusNotifications = value,
        ),
      ],
    );
  }

  // -- Storage & sync ---------------------------------------------------------

  Widget _buildStorageSyncContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          title: 'Storage backends',
          children: [
            _buildDropdownField(
              context,
              label: 'Primary backend',
              value: prefs.storageBackend,
              options: const ['Local', 'Cloud', 'Self-hosted'],
              onChanged: (value) => prefs.storageBackend = value,
            ),
            const SizedBox(height: Spacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: IconSizes.small),
                label: const Text('Add storage backend'),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Metadata sync',
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        prefs.serverUrl.isEmpty
                            ? 'Not connected'
                            : prefs.serverUrl,
                        style: textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: prefs.serverUrl.isEmpty
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    prefs.serverUrl.isEmpty ? 'Offline' : 'Connected',
                    style: textTheme.labelSmall?.copyWith(
                      color: prefs.serverUrl.isEmpty
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _buildSegmentedField<String>(
              context,
              label: 'Server type',
              value: prefs.serverType,
              options: const {
                'official': 'Official',
                'self-hosted': 'Self-hosted',
              },
              onChanged: (value) => prefs.serverType = value,
            ),
            const SizedBox(height: Spacing.md),
            SettingsToggleRow(
              label: 'Sync enabled',
              value: prefs.syncEnabled,
              onChanged: (value) => prefs.syncEnabled = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildDropdownField(
              context,
              label: 'Sync interval',
              value: prefs.syncInterval,
              options: const ['realtime', '1min', '5min', 'manual'],
              labels: const {
                'realtime': 'Real-time',
                '1min': 'Every minute',
                '5min': 'Every 5 minutes',
                'manual': 'Manual only',
              },
              onChanged: (value) => prefs.syncInterval = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildSegmentedField<String>(
              context,
              label: 'Conflict resolution',
              value: prefs.conflictResolution,
              options: const {
                'server': 'Server wins',
                'client': 'Client wins',
                'ask': 'Ask me',
              },
              onChanged: (value) => prefs.conflictResolution = value,
            ),
            const SizedBox(height: Spacing.md),
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
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Sync now'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -- Privacy & data ---------------------------------------------------------

  Widget _buildPrivacyDataContent(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          title: 'Analytics',
          children: [
            SettingsToggleRow(
              label: 'Send anonymous usage data',
              value: prefs.analyticsOptIn,
              onChanged: (value) => prefs.analyticsOptIn = value,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text(
                'Help improve Papyrus by sharing anonymous usage statistics. '
                'No personal data or reading content is collected.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Data management',
          children: [
            SettingsRow(label: 'Export all data', onTap: () {}),
            SettingsRow(label: 'Import data', onTap: () {}),
            SettingsRow(label: 'Clear local data', onTap: () {}),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Legal',
          children: [SettingsRow(label: 'Privacy policy', onTap: () {})],
        ),
      ],
    );
  }

  // -- Accessibility ----------------------------------------------------------

  Widget _buildAccessibilityContent(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return SettingsCard(
      children: [
        SettingsToggleRow(
          label: 'Reduce animations',
          value: prefs.reduceAnimations,
          onChanged: (value) => prefs.reduceAnimations = value,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: Spacing.sm,
            right: Spacing.sm,
            bottom: Spacing.md,
          ),
          child: Text(
            'Minimizes motion effects throughout the app. '
            'Separate from e-ink mode.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SettingsToggleRow(
          label: 'Dyslexia-friendly font',
          value: prefs.dyslexiaFont,
          onChanged: (value) => prefs.dyslexiaFont = value,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: Spacing.sm,
            right: Spacing.sm,
            bottom: Spacing.md,
          ),
          child: Text(
            'Use OpenDyslexic font across the app interface.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // -- About ------------------------------------------------------------------

  Widget _buildAboutContent(BuildContext context) {
    return SettingsCard(
      children: [
        SettingsRow(label: 'Version', value: '1.0.0', showChevron: false),
        SettingsRow(label: "What's new", onTap: () {}),
        SettingsRow(label: 'Licenses', onTap: () => _showLicenses(context)),
        SettingsRow(label: 'Support', onTap: () {}),
        SettingsRow(label: 'GitHub repository', onTap: () {}),
      ],
    );
  }

  // -- Developer options ------------------------------------------------------

  Widget _buildDeveloperOptionsContent(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          title: 'Display',
          children: [
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
        const SizedBox(height: Spacing.lg),
        SettingsCard(
          title: 'Debug',
          children: [
            SettingsRow(label: 'Reload sample data', onTap: () {}),
            SettingsRow(label: 'Reset onboarding', onTap: () {}),
            SettingsRow(label: 'Performance overlay', onTap: () {}),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // USER DATA
  // ============================================================================

  String _getDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? 'Anonymous User';
  }

  String _getEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null || user!.email!.trim().isEmpty) {
      return 'No email provided';
    }
    return user.email!;
  }

  String? _getAvatarUrl() {
    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  String get _initials {
    final name = _getDisplayName();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool _isGoogleLinked() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _handleLogout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final googleProvider = Provider.of<GoogleSignInProvider>(
      context,
      listen: false,
    );

    for (var providerData in user.providerData) {
      if (providerData.providerId == 'google.com') {
        await googleProvider.signOut();
        if (context.mounted) context.go('/login');
        return;
      }
    }

    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/login');
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit profile coming soon')));
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Papyrus',
      applicationVersion: '1.0.0',
    );
  }

  // ============================================================================
  // REUSABLE FIELD BUILDERS
  // ============================================================================

  Widget _buildDropdownField(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    Map<String, String>? labels,
    required ValueChanged<String> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        DropdownMenu<String>(
          initialSelection: value,
          expandedInsets: EdgeInsets.zero,
          dropdownMenuEntries: options.map((option) {
            final displayLabel = labels?[option] ?? option;
            return DropdownMenuEntry(value: option, label: displayLabel);
          }).toList(),
          onSelected: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }

  Widget _buildSegmentedField<T>(
    BuildContext context, {
    required String label,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            segments: options.entries.map((entry) {
              return ButtonSegment<T>(
                value: entry.key,
                label: Text(entry.value),
              );
            }).toList(),
            selected: {value},
            onSelectionChanged: (selected) {
              onChanged(selected.first);
            },
            showSelectedIcon: false,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // BOTTOM SHEET PICKERS (mobile)
  // ============================================================================

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

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

  String _getSortOrderLabel(String value) {
    const labels = {
      'title': 'Title',
      'author': 'Author',
      'date_added': 'Date added',
      'last_read': 'Last read',
      'rating': 'Rating',
    };
    return labels[value] ?? value;
  }

  void _showThemePicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Light', 'light'),
        ('System default', 'system'),
        ('Dark', 'dark'),
      ],
      selected: prefs.themeModePref,
      onSelected: (value) => prefs.themeModePref = value,
    );
  }

  void _showFontPicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Georgia', 'Georgia'),
        ('Literata', 'Literata'),
        ('Bookerly', 'Bookerly'),
        ('Merriweather', 'Merriweather'),
        ('Noto Serif', 'Noto Serif'),
        ('Atkinson Hyperlegible', 'Atkinson Hyperlegible'),
        ('Open Dyslexic', 'Open Dyslexic'),
      ],
      selected: prefs.defaultFont,
      onSelected: (value) => prefs.defaultFont = value,
    );
  }

  void _showLineSpacingPicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Compact', 'compact'),
        ('Normal', 'normal'),
        ('Relaxed', 'relaxed'),
      ],
      selected: prefs.lineSpacing,
      onSelected: (value) => prefs.lineSpacing = value,
    );
  }

  void _showReadingModePicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [('Paginated', 'paginated'), ('Continuous scroll', 'scroll')],
      selected: prefs.readingMode,
      onSelected: (value) => prefs.readingMode = value,
    );
  }

  void _showViewModePicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [('Grid', 'grid'), ('List', 'list'), ('Compact', 'compact')],
      selected: prefs.defaultViewMode,
      onSelected: (value) => prefs.defaultViewMode = value,
    );
  }

  void _showSortOrderPicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Title', 'title'),
        ('Author', 'author'),
        ('Date added', 'date_added'),
        ('Last read', 'last_read'),
        ('Rating', 'rating'),
      ],
      selected: prefs.defaultSortOrder,
      onSelected: (value) => prefs.defaultSortOrder = value,
    );
  }

  void _showMetadataSourcePicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Open Library', 'Open Library'),
        ('Google Books', 'Google Books'),
      ],
      selected: prefs.metadataSource,
      onSelected: (value) => prefs.metadataSource = value,
    );
  }

  void _showExportFormatPicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Markdown', 'Markdown'),
        ('PDF', 'PDF'),
        ('TXT', 'TXT'),
        ('HTML', 'HTML'),
      ],
      selected: prefs.annotationExportFormat,
      onSelected: (value) => prefs.annotationExportFormat = value,
    );
  }

  void _showStoragePicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [
        ('Local', 'Local'),
        ('Cloud', 'Cloud'),
        ('Self-hosted', 'Self-hosted'),
      ],
      selected: prefs.storageBackend,
      onSelected: (value) => prefs.storageBackend = value,
    );
  }

  void _showPickerSheet(
    BuildContext context, {
    required List<(String label, String value)> items,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            return _buildPickerTile(
              context: sheetContext,
              title: item.$1,
              isSelected: selected == item.$2,
              onTap: () {
                onSelected(item.$2);
                Navigator.pop(sheetContext);
              },
            );
          }).toList(),
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

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildMobileHeader(BuildContext context, {double avatarSize = 128}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _buildAvatar(context, size: avatarSize),
        const SizedBox(height: Spacing.md),
        Text(
          _getDisplayName(),
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          _getEmail(),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: 200,
          child: OutlinedButton(
            onPressed: () => _navigateToEditProfile(context),
            child: const Text('Edit profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, {required double size}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarUrl = _getAvatarUrl();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  _initials,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: size * 0.35,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: size * 0.35,
                ),
              ),
            ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showChevron = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
    final textColor = isDestructive ? colorScheme.error : null;

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? colorScheme.errorContainer.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: IconSizes.medium),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(color: textColor),
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
}
