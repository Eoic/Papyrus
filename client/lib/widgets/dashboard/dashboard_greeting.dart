import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Greeting section for the dashboard displaying time-based greeting and reading stats.
class DashboardGreeting extends StatelessWidget {
  /// Time-based greeting (e.g., "Good morning").
  final String greeting;

  /// Today's reading time label (e.g., "32 minutes").
  final String todayReadingLabel;

  /// Whether to use desktop styling.
  final bool isDesktop;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const DashboardGreeting({
    super.key,
    required this.greeting,
    required this.todayReadingLabel,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Reader';
    // Get first name only
    final firstName = displayName.split(' ').first;
    return firstName;
  }

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) return _buildEinkGreeting(context);
    if (isDesktop) return _buildDesktopGreeting(context);
    return _buildMobileGreeting(context);
  }

  Widget _buildMobileGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $_userName!',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            "You've read $todayReadingLabel today",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $_userName!',
          style: textTheme.displaySmall,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          "You've read $todayReadingLabel today",
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEinkGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, ${_userName.toUpperCase()}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            "You've read $todayReadingLabel today",
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

}
