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

  const DashboardGreeting({
    super.key,
    required this.greeting,
    required this.todayReadingLabel,
    this.isDesktop = false,
  });

  /// Returns the current user's first name, or "reader" as fallback.
  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'reader';
    return displayName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final greetingStyle = isDesktop
        ? textTheme.headlineMedium
        : textTheme.titleLarge;

    return Padding(
      padding: isDesktop
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
      child: Row(
        children: [
          Expanded(child: Text('$greeting, $_userName!', style: greetingStyle)),
          const SizedBox(width: Spacing.sm),
          _buildTodayPill(textTheme, colorScheme),
        ],
      ),
    );
  }

  /// Builds the "Read X today" pill badge.
  Widget _buildTodayPill(TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'Read $todayReadingLabel today',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
