import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Greeting section for the dashboard displaying time-based greeting.
class DashboardGreeting extends StatelessWidget {
  /// Time-based greeting (e.g., "Good morning").
  final String greeting;

  /// Called when the notifications icon is tapped.
  final VoidCallback? onNotificationsTap;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const DashboardGreeting({
    super.key,
    required this.greeting,
    this.onNotificationsTap,
    this.isDesktop = false,
  });

  /// Returns the current user's first name, or "reader" as fallback.
  String get _userName {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        (user?.userMetadata?['full_name'] as String?) ?? 'reader';
    return displayName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final greetingStyle = isDesktop
        ? textTheme.headlineMedium
        : textTheme.titleLarge;

    return Padding(
      padding: isDesktop
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        children: [
          Expanded(child: Text('$greeting, $_userName!', style: greetingStyle)),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}
