import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Header section for the profile page displaying user avatar, name, and email.
///
/// Supports two display modes:
/// - **Mobile**: Centered vertical layout with rounded avatar
/// - **Desktop**: Horizontal layout with avatar alongside user info
///
/// ## Features
///
/// - Circular avatar with network image or initials fallback
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

  /// Whether to use desktop horizontal layout.
  final bool isDesktopLayout;

  /// Creates a profile header widget.
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.onEditProfile,
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
            // Override the theme's infinite-width minimumSize for Row usage.
            style: OutlinedButton.styleFrom(minimumSize: Size.zero),
            onPressed: onEditProfile,
            child: const Text('Edit profile'),
          ),
        ],
      ),
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
