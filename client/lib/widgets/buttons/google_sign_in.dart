import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// A Google Sign-in button with loading state and error handling.
/// Supports standard and e-ink display modes.
class GoogleSignInButton extends StatefulWidget {
  /// Button text
  final String title;

  /// Whether to display in e-ink optimized mode
  final bool isEink;

  /// Optional callback when sign-in is successful
  final VoidCallback? onSuccess;

  /// Optional callback when sign-in fails
  final VoidCallback? onError;

  const GoogleSignInButton({
    super.key,
    required this.title,
    this.isEink = false,
    this.onSuccess,
    this.onError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;

  Future<void> _handleSignIn() async {
    if (_isSigningIn) return;

    setState(() => _isSigningIn = true);

    try {
      final provider = Provider.of<GoogleSignInProvider>(
        context,
        listen: false,
      );

      final result = await provider.signInWithGoogle();

      if (!mounted) return;

      if (result != null) {
        widget.onSuccess?.call();
        context.goNamed('LIBRARY');
      }
    } catch (error) {
      if (!mounted) return;

      widget.onError?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text('Failed to sign in with Google account.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEink) {
      return _buildEinkButton(context);
    }

    return _buildStandardButton(context);
  }

  Widget _buildStandardButton(BuildContext context) {
    final theme = Theme.of(context);

    if (_isSigningIn) {
      return SizedBox(
        height: ComponentSizes.buttonHeightMobile,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightMobile),
        side: BorderSide(
          width: BorderWidths.thin,
          color: theme.colorScheme.outline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.googleButton),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      onPressed: _handleSignIn,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('assets/images/google_logo.png'),
            height: 24.0,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkButton(BuildContext context) {
    if (_isSigningIn) {
      return SizedBox(
        height: ComponentSizes.buttonHeightEink,
        child: const Center(
          child: Text(
            'SIGNING IN...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightEink),
        side: const BorderSide(
          width: BorderWidths.einkDefault,
          color: Colors.black,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      onPressed: _handleSignIn,
      child: Text(
        widget.title.toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
