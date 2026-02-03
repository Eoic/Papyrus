import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Header section for the profile page displaying user avatar, name, and email.
///
/// Supports three display modes:
/// - **Standard**: Material Design 3 styling with rounded avatar
/// - **Desktop**: Horizontal layout with avatar alongside user info
/// - **E-ink**: High-contrast styling with square avatar
///
/// ## Features
///
/// - Circular/square avatar with network image or initials fallback
/// - User display name and email
/// - Optional "Edit Profile" button
/// - Responsive sizing based on display mode
///
/// ## Example
///
/// ```dart
/// ProfileHeader(
///   displayName: 'John Doe',
///   email: 'john@email.com',
///   avatarUrl: user.photoURL,
///   onEditProfile: () => context.push('/profile/edit'),
/// )
/// ```
class ProfileHeader extends StatelessWidget {
  /// User's display name.
  final String displayName;

  /// User's email address.
  final String email;

  /// URL for the user's avatar image.
  final String? avatarUrl;

  /// Called when "Edit Profile" button is tapped.
  final VoidCallback? onEditProfile;

  /// Whether to use e-ink optimized styling.
  final bool isEinkMode;

  /// Whether to use desktop horizontal layout.
  final bool isDesktopLayout;

  /// Creates a profile header widget.
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.onEditProfile,
    this.isEinkMode = false,
    this.isDesktopLayout = false,
  });

  /// Gets user initials from display name.
  String get _initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkHeader(context);
    if (isDesktopLayout) return _buildDesktopHeader(context);
    return _buildMobileHeader(context);
  }

  /// Mobile layout with centered vertical alignment.
  Widget _buildMobileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _buildAvatar(context, size: 128, borderRadius: 64),
        const SizedBox(height: Spacing.md),
        Text(
          displayName,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          email,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: 200,
          height: 40,
          child: OutlinedButton(
            onPressed: onEditProfile,
            child: const Text('Edit profile'),
          ),
        ),
      ],
    );
  }

  /// Desktop layout with horizontal avatar and info alignment.
  Widget _buildDesktopHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _buildAvatar(context, size: 96, borderRadius: 48),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayName, style: textTheme.headlineMedium),
                const SizedBox(height: Spacing.xs),
                Text(
                  email,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          OutlinedButton(
            onPressed: onEditProfile,
            child: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }

  /// E-ink layout with high-contrast styling.
  Widget _buildEinkHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _buildEinkAvatar(context),
        const SizedBox(height: Spacing.md),
        Text(
          displayName.toUpperCase(),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xs),
        Text(email, style: textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: Spacing.md),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
            child: SizedBox(
              height: TouchTargets.einkMin,
              child: OutlinedButton(
                onPressed: onEditProfile,
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
          ),
        ),
      ],
    );
  }

  /// Builds circular avatar for standard modes.
  Widget _buildAvatar(
    BuildContext context, {
    required double size,
    required double borderRadius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _buildInitialsAvatar(context, colorScheme, textTheme, size),
            )
          : _buildInitialsAvatar(context, colorScheme, textTheme, size),
    );
  }

  /// Builds square avatar for e-ink mode.
  Widget _buildEinkAvatar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
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

  /// Builds initials fallback for avatar.
  Widget _buildInitialsAvatar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double size,
  ) {
    return Center(
      child: Text(
        _initials,
        style: textTheme.headlineMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}
