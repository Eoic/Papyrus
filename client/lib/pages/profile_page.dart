import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// User profile page with account settings and reading statistics.
///
/// Provides two responsive layouts:
/// - **Standard**: Vertical layout with centered header, menu items below
/// - **E-ink**: High-contrast vertical layout with larger touch targets
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();

    if (displayMode.isEinkMode) return _buildEinkLayout(context);
    return _buildStandardLayout(context);
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

  // ============================================================================
  // STANDARD LAYOUT (Mobile + Desktop)
  // ============================================================================

  Widget _buildStandardLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _buildHeader(context),
            const SizedBox(height: Spacing.lg),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.payment_outlined,
              label: 'Billing details',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.storage_outlined,
              label: 'Storage management',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              label: 'Information',
              onTap: () {},
            ),
            if (kDebugMode) ...[
              const Divider(height: Spacing.lg),
              _buildMenuItem(
                context,
                icon: Icons.code,
                label: 'Developer options',
                onTap: () => context.push('/developer-options'),
              ),
            ],
            const Divider(height: Spacing.lg),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              label: 'Log out',
              isDestructive: true,
              showChevron: false,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _buildAvatar(context, size: 128),
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

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildEinkHeader(context),
          const Divider(color: Colors.black, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageMarginsEink),
              children: [
                _buildEinkProfileHeader(context),
                const SizedBox(height: Spacing.lg),
                const Divider(color: Colors.black87, height: 1),
                _buildEinkMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.push('/settings'),
                ),
                const Divider(color: Colors.black26, height: 1),
                _buildEinkMenuItem(
                  context,
                  icon: Icons.storage_outlined,
                  label: 'Storage management',
                  onTap: () {},
                ),
                const Divider(color: Colors.black26, height: 1),
                _buildEinkMenuItem(
                  context,
                  icon: Icons.info_outline,
                  label: 'Information',
                  onTap: () {},
                ),
                if (kDebugMode) ...[
                  const Divider(color: Colors.black26, height: 1),
                  _buildEinkMenuItem(
                    context,
                    icon: Icons.code,
                    label: 'Developer options',
                    onTap: () => context.push('/developer-options'),
                  ),
                ],
                const Divider(color: Colors.black87, height: 1),
                const SizedBox(height: Spacing.md),
                _buildEinkMenuItem(
                  context,
                  icon: Icons.logout,
                  label: 'Log out',
                  showChevron: false,
                  onTap: () => _showLogoutConfirmation(context),
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
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'PROFILE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEinkProfileHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _buildEinkAvatar(context),
        const SizedBox(height: Spacing.md),
        Text(
          _getDisplayName().toUpperCase(),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          _getEmail(),
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: 200,
          height: TouchTargets.einkMin,
          child: OutlinedButton(
            onPressed: () => _navigateToEditProfile(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(
                color: Colors.black,
                width: BorderWidths.einkDefault,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('EDIT PROFILE'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

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

  Widget _buildEinkAvatar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarUrl = _getAvatarUrl();
    const size = 120.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  _initials,
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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

  Widget _buildEinkMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: TouchTargets.einkMin),
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(icon, size: IconSizes.medium),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
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
