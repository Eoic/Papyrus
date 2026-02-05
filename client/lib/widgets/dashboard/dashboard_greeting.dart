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
    final displayName = user?.displayName ?? 'reader';
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
      child: Row(
        children: [
          Expanded(
            child: Text('$greeting, $_userName!', style: textTheme.titleLarge),
          ),
          const SizedBox(width: Spacing.sm),
          _buildTodayPill(context, textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDesktopGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$greeting, $_userName!',
            style: textTheme.headlineMedium,
          ),
        ),
        const SizedBox(width: Spacing.md),
        _buildTodayPill(context, textTheme, colorScheme),
      ],
    );
  }

  Widget _buildEinkGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$greeting, $_userName!',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _buildTodayPill(context, textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTodayPill(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Read $todayReadingLabel today',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
