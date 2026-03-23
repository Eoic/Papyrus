import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Continue/submit button with loading state for auth pages.
class AuthContinueButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isDesktop;

  const AuthContinueButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonHeight = isDesktop
        ? ComponentSizes.buttonHeightDesktop
        : ComponentSizes.buttonHeightMobile;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(buttonHeight),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(
                  Icons.arrow_forward,
                  size: IconSizes.medium,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
    );
  }
}
