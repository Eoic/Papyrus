import 'package:flutter/material.dart';

/// A link row at the bottom of auth forms to switch between login and register.
/// Displays prompt text and an action button (e.g. "Don't have an account? Sign up").
class AuthSwitchLink extends StatelessWidget {
  /// Prompt text (e.g. "Don't have an account?").
  final String promptText;

  /// Action button label (e.g. "Sign up").
  final String actionText;

  final VoidCallback onPressed;

  const AuthSwitchLink({
    super.key,
    required this.promptText,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          promptText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}
