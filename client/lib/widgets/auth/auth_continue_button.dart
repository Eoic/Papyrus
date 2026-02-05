import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Continue/submit button with loading state for auth pages.
/// Supports standard and e-ink display modes.
class AuthContinueButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isEink;
  final bool isDesktop;

  /// Text shown on the e-ink button during loading (e.g. "SIGNING IN...").
  final String einkLoadingText;

  const AuthContinueButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.isEink,
    required this.isDesktop,
    this.einkLoadingText = 'LOADING...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEink) {
      return _buildEinkButton();
    }

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

  Widget _buildEinkButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightEink),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF404040),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      child: Text(
        isLoading ? einkLoadingText : 'CONTINUE',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
