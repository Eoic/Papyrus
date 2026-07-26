import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/media/media_upload_queue.dart';
import 'package:papyrus/powersync/powersync_service.dart';
import 'package:papyrus/powersync/storage_sync_controller.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/acquisition_availability_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:papyrus/powersync/sync_state.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
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
            if (kDebugMode) _buildMobileDeveloperSection(context),
            _buildMobileAboutSection(context),
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
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Appearance'),
        SettingsRow(label: 'Theme', value: _getThemeLabel(prefs.themeModePref), onTap: () => _showThemePicker(context)),
      ],
    );
  }

  Widget _buildMobileReadingSection(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Reading'),
        SettingsRow(label: 'Default font', value: prefs.defaultFont, onTap: () => _showFontPicker(context)),
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
    final controller = _storageSyncController(context);
    final prefs = context.watch<PreferencesProvider>();
    final acquisitionAvailable = _acquisitionAvailable(context);

    if (controller.isGuest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: 'Storage'),
          const SettingsRow(label: 'Library', value: 'Stored on this device'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
            child: Text(
              'Nothing is sent to Papyrus servers while offline mode is on.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SettingsRow(
            label: 'Backup',
            value: 'Export or import a backup',
            onTap: () => _showOfflineBackupActions(context),
          ),
          SettingsRow(label: 'Clear local library', onTap: () => _confirmClearLocalLibrary(context)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Storage'),
        SettingsRow(
          label: 'Data sync',
          value: controller.dataSyncLabel,
          onTap: () => _showManageSyncServersSheet(context),
        ),
        SettingsRow(label: 'Current status', value: controller.statusLabel),
        SettingsRow(label: 'File storage', value: controller.fileStorageLabel),
        if (controller.hasFailedMediaUploads)
          SettingsRow(
            label: 'Media uploads',
            value: controller.failedMediaUploadLabel,
            onTap: () => _retryFailedMediaUploads(context),
          ),
        SettingsRow(label: 'Manage servers', onTap: () => _showManageSyncServersSheet(context)),
        SettingsToggleRow(
          label: 'Torrent acquisition',
          value: prefs.acquisitionEnabled,
          onChanged: (value) => prefs.acquisitionEnabled = value,
        ),
        if (prefs.acquisitionEnabled && acquisitionAvailable)
          SettingsRow(label: 'Torrent & automation', onTap: () => context.push('/acquisition')),
        if (controller.canReconnect) SettingsRow(label: 'Reconnect', onTap: () => _handleReconnectSync(context)),
        if (controller.canClearGuestLibrary)
          SettingsRow(label: 'Clear local library', onTap: () => _confirmClearLocalLibrary(context)),
        if (controller.canClearAuthenticatedCache)
          SettingsRow(label: 'Clear local copy', onTap: () => _confirmClearAuthenticatedCache(context)),
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
    context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Developer options'),
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
                    label: 'Storage',
                    section: _ProfileSection.storageSync,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.shield_outlined,
                    label: 'Privacy',
                    section: _ProfileSection.privacyData,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.accessibility_outlined,
                    label: 'Accessibility',
                    section: _ProfileSection.accessibility,
                  ),
                  if (kDebugMode)
                    _buildNavItem(
                      context,
                      icon: Icons.code,
                      label: 'Developer options',
                      section: _ProfileSection.developerOptions,
                    ),
                  _buildNavItem(context, icon: Icons.info_outline, label: 'About', section: _ProfileSection.about),
                  const SizedBox(height: Spacing.sm),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: Spacing.sm),
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
    final bgColor = isSelected ? colorScheme.primaryContainer : Colors.transparent;

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
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm + 2),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: IconSizes.medium),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
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
        return 'Storage';
      case _ProfileSection.privacyData:
        return 'Privacy';
      case _ProfileSection.accessibility:
        return 'Accessibility';
      case _ProfileSection.developerOptions:
        return 'Developer options';
      case _ProfileSection.about:
        return 'About';
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
                      Text(_getEmail(), style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
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
            SettingsRow(label: 'Google', value: _isGoogleLinked() ? 'Connected' : 'Not connected', onTap: () {}),
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
    return SettingsCard(children: [_buildThemeRadioGroup(context)]);
  }

  Widget _buildThemeRadioGroup(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: Spacing.sm),
        _buildRadioTile('Light', 'light'),
        _buildRadioTile('Dark', 'dark'),
        _buildRadioTile('E-ink', 'eink'),
        _buildRadioTile('System', 'system'),
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
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary),
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
            Text('Default font size', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                SizedBox(width: 48, child: Text('${prefs.defaultFontSize.toInt()}px', style: textTheme.bodyMedium)),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _buildSegmentedField<String>(
              context,
              label: 'Line spacing',
              value: prefs.lineSpacing,
              options: const {'compact': 'Compact', 'normal': 'Normal', 'relaxed': 'Relaxed'},
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
              options: const {'small': 'Small', 'medium': 'Medium', 'large': 'Large'},
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
              options: const {'paginated': 'Paginated', 'scroll': 'Continuous scroll'},
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
        SettingsCard(title: 'Annotations', children: [_buildHighlightColorField(context)]),
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
        Text('Default highlight color', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                  child: isSelected ? Icon(Icons.check, size: 18, color: colorScheme.primary) : null,
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
              options: const {'grid': 'Grid', 'list': 'List', 'compact': 'Compact'},
              onChanged: (value) => prefs.defaultViewMode = value,
            ),
            const SizedBox(height: Spacing.md),
            _buildDropdownField(
              context,
              label: 'Default sort order',
              value: prefs.defaultSortOrder,
              options: const ['title', 'author', 'date_added', 'last_read', 'rating'],
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
              options: const {'Open Library': 'Open Library', 'Google Books': 'Google Books'},
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

  // -- Storage ---------------------------------------------------------

  Widget _buildStorageSyncContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = _storageSyncController(context);
    final prefs = context.watch<PreferencesProvider>();
    final acquisitionAvailable = _acquisitionAvailable(context);

    if (controller.isGuest) return _buildOfflineStorageSyncContent(context);

    return SettingsCard(
      title: 'Data sync',
      children: [
        _buildInfoRow(context, label: 'Active server', value: controller.dataSyncLabel),
        _buildInfoRow(context, label: 'Status', value: controller.statusLabel),
        _buildInfoRow(context, label: 'File storage', value: controller.fileStorageLabel),
        if (controller.hasFailedMediaUploads)
          _buildInfoRow(context, label: 'Media uploads', value: controller.failedMediaUploadLabel),
        const SizedBox(height: Spacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
          child: Text(controller.syncDetail, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: Spacing.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Torrent acquisition'),
          value: prefs.acquisitionEnabled,
          onChanged: (value) => prefs.acquisitionEnabled = value,
        ),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          alignment: WrapAlignment.start,
          children: [
            if (controller.canReconnect)
              OutlinedButton.icon(
                onPressed: () => _handleReconnectSync(context),
                icon: const Icon(Icons.sync, size: IconSizes.small),
                label: const Text('Reconnect'),
              ),
            OutlinedButton.icon(
              onPressed: () => _showManageSyncServersSheet(context),
              icon: const Icon(Icons.dns_outlined, size: IconSizes.small),
              label: const Text('Manage servers'),
            ),
            if (prefs.acquisitionEnabled && acquisitionAvailable)
              OutlinedButton.icon(
                onPressed: () => context.push('/acquisition'),
                icon: const Icon(Icons.downloading_outlined, size: IconSizes.small),
                label: const Text('Torrent & automation'),
              ),
            if (controller.hasFailedMediaUploads)
              OutlinedButton.icon(
                onPressed: () => _retryFailedMediaUploads(context),
                icon: const Icon(Icons.refresh, size: IconSizes.small),
                label: const Text('Retry uploads'),
              ),
            if (controller.canClearAuthenticatedCache)
              OutlinedButton.icon(
                onPressed: () => _confirmClearAuthenticatedCache(context),
                icon: const Icon(Icons.cleaning_services_outlined, size: IconSizes.small),
                label: const Text('Clear local copy'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfflineStorageSyncContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedStyle = textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return SettingsCard(
      title: 'Library storage',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your library is stored on this device.', style: textTheme.bodyLarge),
              const SizedBox(height: Spacing.sm),
              Text(
                'Nothing is sent to Papyrus servers while offline mode is on. Export a backup before changing devices or clearing app data.',
                style: mutedStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showBackupUnavailable(context, 'Backup export'),
              icon: const Icon(Icons.file_download_outlined, size: IconSizes.small),
              label: const Text('Export backup'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showBackupUnavailable(context, 'Backup import'),
              icon: const Icon(Icons.file_upload_outlined, size: IconSizes.small),
              label: const Text('Import backup'),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmClearLocalLibrary(context),
              icon: const Icon(Icons.delete_outline, size: IconSizes.small),
              label: const Text('Clear local library'),
            ),
          ],
        ),
      ],
    );
  }

  StorageSyncController _storageSyncController(BuildContext context) {
    return StorageSyncController(
      authProvider: context.watch<AuthProvider>(),
      powerSyncService: context.read<PapyrusPowerSyncService>(),
      syncSettings: context.watch<SyncSettingsProvider>(),
      syncState: context.watch<SyncState>(),
      fileStorageUsedBytes: _fileStorageUsedBytes(context.watch<DataStore>()),
      mediaStorageUsage: context.watch<MediaUploadQueue>().storageUsage,
      failedMediaUploadCount: _failedMediaUploadCount(context.watch<MediaUploadQueue>()),
    );
  }

  bool _acquisitionAvailable(BuildContext context) {
    final serverBaseUri = context.watch<SyncSettingsProvider>().activeApiConfig.serverBaseUri;
    return context.watch<AcquisitionAvailabilityProvider>().isAvailableFor(serverBaseUri);
  }

  int _fileStorageUsedBytes(DataStore dataStore) {
    return dataStore.books.fold<int>(0, (total, book) => total + (book.fileSize ?? 0));
  }

  int _failedMediaUploadCount(MediaUploadQueue queue) {
    return queue.pendingTasks.where((task) => task.status == MediaUploadTaskStatus.failed).length;
  }

  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: SelectableText(value, style: textTheme.bodyMedium)),
        ],
      ),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          padding: const EdgeInsets.only(left: Spacing.sm, right: Spacing.sm, bottom: Spacing.md),
          child: Text(
            'Minimizes motion effects throughout the app. '
            'Separate from e-ink mode.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        SettingsToggleRow(
          label: 'Dyslexia-friendly font',
          value: prefs.dyslexiaFont,
          onChanged: (value) => prefs.dyslexiaFont = value,
        ),
        Padding(
          padding: const EdgeInsets.only(left: Spacing.sm, right: Spacing.sm, bottom: Spacing.md),
          child: Text(
            'Use OpenDyslexic font across the app interface.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    context.watch<PreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    final user = context.watch<AuthProvider>().user;
    return user?.displayName ?? 'Anonymous User';
  }

  String _getEmail() {
    final email = context.watch<AuthProvider>().user?.email;
    if (email == null || email.trim().isEmpty) return 'No email provided';
    return email;
  }

  String? _getAvatarUrl() {
    return context.watch<AuthProvider>().user?.avatarUrl;
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
    return false;
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (context.mounted) context.go('/login');
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
    context.go('/profile/edit');
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(context: context, applicationName: 'Papyrus', applicationVersion: '1.0.0');
  }

  void _showManageSyncServersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Consumer<SyncSettingsProvider>(
          builder: (context, settings, _) {
            return ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
                  child: Text('Sync servers', style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  leading: Icon(
                    settings.activeServerId == SyncSettingsProvider.officialServerId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: const Text('Official server'),
                  subtitle: const Text('Papyrus-hosted data sync and file storage'),
                  onTap: () {
                    settings.selectServer(SyncSettingsProvider.officialServerId);
                    Navigator.pop(sheetContext);
                  },
                ),
                for (final server in settings.customServers)
                  ListTile(
                    leading: Icon(
                      settings.activeServerId == server.id ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    ),
                    title: Text(server.label),
                    subtitle: Text(server.url),
                    onTap: () {
                      settings.selectServer(server.id);
                      Navigator.pop(sheetContext);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.pop(sheetContext);
                          unawaited(_showCustomServerDialog(context, server: server));
                        } else if (value == 'remove') {
                          settings.removeCustomServer(server.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'remove', child: Text('Remove')),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add custom server'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(_showCustomServerDialog(context));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCustomServerDialog(BuildContext context, {CustomSyncServer? server}) async {
    final settings = context.read<SyncSettingsProvider>();
    final urlController = TextEditingController(text: server?.url ?? '');
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(server == null ? 'Add custom server' : 'Edit custom server'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(labelText: 'Server URL'),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  if (server == null) {
                    await settings.addCustomServer(urlController.text);
                  } else {
                    await settings.updateCustomServer(server.id, urlController.text);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (error) {
                  messenger.showSnackBar(SnackBar(content: Text('Could not save server: $error')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      urlController.dispose();
    }
  }

  Future<void> _handleReconnectSync(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PapyrusPowerSyncService>().reconnect();
      messenger.showSnackBar(const SnackBar(content: Text('Sync reconnect requested.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not reconnect sync: $error')));
    }
  }

  Future<void> _retryFailedMediaUploads(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<MediaUploadQueue>().retryFailed();
    messenger.showSnackBar(const SnackBar(content: Text('Media uploads will retry on the next sync.')));
  }

  void _showOfflineBackupActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export backup'),
              subtitle: const Text('Save a copy for another device'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBackupUnavailable(context, 'Backup export');
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import backup'),
              subtitle: const Text('Restore from a saved copy'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBackupUnavailable(context, 'Backup import');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupUnavailable(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action is not available yet.')));
  }

  Future<void> _confirmClearLocalLibrary(BuildContext context) async {
    final confirmed = await _confirmStorageAction(
      context,
      title: 'Clear local library',
      message:
          'This deletes the library stored on this device. This cannot be undone unless you have exported a backup.',
      actionLabel: 'Clear library',
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PapyrusPowerSyncService>().clearGuestLibrary();
      messenger.showSnackBar(const SnackBar(content: Text('Local library cleared.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not clear local library: $error')));
    }
  }

  Future<void> _confirmClearAuthenticatedCache(BuildContext context) async {
    final confirmed = await _confirmStorageAction(
      context,
      title: 'Clear local copy',
      message:
          'This removes synced library data stored on this device. Your library stays on the server and will download again when sync reconnects.',
      actionLabel: 'Clear local copy',
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final scope = context.read<MediaUploadQueue>().activeScope;
      final powerSyncService = context.read<PapyrusPowerSyncService>();
      final importService = context.read<BookImportService>();
      await powerSyncService.clearAuthenticatedCache();
      if (scope != null) {
        await importService.clearCoverFiles(scope);
      }
      messenger.showSnackBar(const SnackBar(content: Text('Local copy cleared.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not clear local copy: $error')));
    }
  }

  Future<bool> _confirmStorageAction(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(actionLabel)),
            ],
          ),
        ) ??
        false;
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
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
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
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            segments: options.entries.map((entry) {
              return ButtonSegment<T>(value: entry.key, label: Text(entry.value));
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
      case 'eink':
        return 'E-ink';
      case 'system':
      default:
        return 'System';
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
      items: [('Light', 'light'), ('Dark', 'dark'), ('E-ink', 'eink'), ('System', 'system')],
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
      items: [('Compact', 'compact'), ('Normal', 'normal'), ('Relaxed', 'relaxed')],
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
      items: [('Open Library', 'Open Library'), ('Google Books', 'Google Books')],
      selected: prefs.metadataSource,
      onSelected: (value) => prefs.metadataSource = value,
    );
  }

  void _showExportFormatPicker(BuildContext context) {
    final prefs = context.read<PreferencesProvider>();

    _showPickerSheet(
      context,
      items: [('Markdown', 'Markdown'), ('PDF', 'PDF'), ('TXT', 'TXT'), ('HTML', 'HTML')],
      selected: prefs.annotationExportFormat,
      onSelected: (value) => prefs.annotationExportFormat = value,
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
        Text(_getDisplayName(), style: textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: Spacing.xs),
        Text(
          _getEmail(),
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: 200,
          child: OutlinedButton(onPressed: () => _navigateToEditProfile(context), child: const Text('Edit profile')),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size / 2), color: colorScheme.primaryContainer),
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
                style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer, fontSize: size * 0.35),
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
    final iconColor = isDestructive ? colorScheme.error : colorScheme.onSurfaceVariant;
    final textColor = isDestructive ? colorScheme.error : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.md),
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
                child: Text(label, style: textTheme.bodyLarge?.copyWith(color: textColor)),
              ),
              if (showChevron) Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: IconSizes.medium),
            ],
          ),
        ),
      ),
    );
  }
}
