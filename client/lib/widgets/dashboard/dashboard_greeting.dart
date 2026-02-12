import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'reader';
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
