import 'package:flutter/material.dart';

/// A link row at the bottom of auth forms to switch between login and register.
/// Displays prompt text and an action button (e.g. "Don't have an account? Sign up").
class AuthSwitchLink extends StatelessWidget {
  /// Prompt text (e.g. "Don't have an account?").
  final String promptText;

  /// Action button label (e.g. "Sign up").
  final String actionText;

  /// E-ink prompt text (e.g. "DON'T HAVE AN ACCOUNT?").
  final String einkPromptText;

  /// E-ink action button label (e.g. "SIGN UP").
  final String einkActionText;

  final VoidCallback onPressed;
  final bool isEink;

  const AuthSwitchLink({
    super.key,
    required this.promptText,
    required this.actionText,
    required this.einkPromptText,
    required this.einkActionText,
    required this.onPressed,
    required this.isEink,
  });

  @override
  Widget build(BuildContext context) {
    if (isEink) {
      return _buildEink();
    }

    return _buildStandard(context);
  }

  Widget _buildEink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          einkPromptText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: Color(0xFF404040),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
          child: Text(einkActionText),
        ),
      ],
    );
  }

  Widget _buildStandard(BuildContext context) {
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
