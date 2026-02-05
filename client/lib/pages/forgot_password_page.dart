import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';
import 'package:papyrus/widgets/auth/auth_continue_button.dart';
import 'package:papyrus/widgets/auth/auth_page_layouts.dart';
import 'package:papyrus/widgets/auth/auth_switch_link.dart';
import 'package:papyrus/widgets/input/email_input.dart';

/// Forgot password page for the Papyrus book management application.
/// Provides responsive layouts for mobile, desktop, and e-ink displays.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Failed to send reset email. Please try again.';
      }

      setState(() => _isLoading = false);
      _showErrorSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  void _navigateBack() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();
    final isEink = displayMode.isEinkMode;

    if (isEink) {
      return EinkAuthLayout(
        headerTitle: 'RESET PASSWORD',
        onBack: _navigateBack,
        form: _emailSent
            ? _EmailSentConfirmation(
                email: _emailController.text.trim(),
                isEink: true,
                isDesktop: false,
              )
            : _ForgotPasswordForm(
                formKey: _formKey,
                emailController: _emailController,
                emailFocusNode: _emailFocusNode,
                isLoading: _isLoading,
                onSubmit: _handleResetPassword,
                isEink: true,
                isDesktop: false,
              ),
        footer: [
          const SizedBox(height: Spacing.xl),
          AuthSwitchLink(
            promptText: 'Remember your password?',
            actionText: 'Sign in',
            einkPromptText: 'REMEMBER YOUR PASSWORD?',
            einkActionText: 'SIGN IN',
            onPressed: _navigateToLogin,
            isEink: true,
          ),
        ],
      );
    }

    return ResponsiveBuilder(
      mobile: (context) => MobileAuthLayout(
        heading: 'Reset password',
        subtitle: 'Enter your email to receive a password reset link',
        showHeader: !_emailSent,
        form: _emailSent
            ? _EmailSentConfirmation(
                email: _emailController.text.trim(),
                isEink: false,
                isDesktop: false,
              )
            : _ForgotPasswordForm(
                formKey: _formKey,
                emailController: _emailController,
                emailFocusNode: _emailFocusNode,
                isLoading: _isLoading,
                onSubmit: _handleResetPassword,
                isEink: false,
                isDesktop: false,
              ),
        footer: [
          const SizedBox(height: Spacing.md),
          AuthSwitchLink(
            promptText: 'Remember your password?',
            actionText: 'Sign in',
            einkPromptText: 'REMEMBER YOUR PASSWORD?',
            einkActionText: 'SIGN IN',
            onPressed: _navigateToLogin,
            isEink: false,
          ),
        ],
      ),
      desktop: (context) => DesktopAuthLayout(
        heading: 'Reset password',
        subtitle: 'Enter your email to receive a password reset link',
        showHeader: !_emailSent,
        form: _emailSent
            ? _EmailSentConfirmation(
                email: _emailController.text.trim(),
                isEink: false,
                isDesktop: true,
              )
            : _ForgotPasswordForm(
                formKey: _formKey,
                emailController: _emailController,
                emailFocusNode: _emailFocusNode,
                isLoading: _isLoading,
                onSubmit: _handleResetPassword,
                isEink: false,
                isDesktop: true,
              ),
        footer: [
          const SizedBox(height: Spacing.md),
          AuthSwitchLink(
            promptText: 'Remember your password?',
            actionText: 'Sign in',
            einkPromptText: 'REMEMBER YOUR PASSWORD?',
            einkActionText: 'SIGN IN',
            onPressed: _navigateToLogin,
            isEink: false,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FORGOT PASSWORD FORM
// =============================================================================

/// Forgot password form with a single email field.
class _ForgotPasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool isEink;
  final bool isDesktop;

  const _ForgotPasswordForm({
    required this.formKey,
    required this.emailController,
    required this.emailFocusNode,
    required this.isLoading,
    required this.onSubmit,
    required this.isEink,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email field
          EmailInput(
            labelText: 'Email address',
            controller: emailController,
            focusNode: emailFocusNode,
            isEink: isEink,
            textInputAction: TextInputAction.done,
            onEditingComplete: onSubmit,
          ),
          SizedBox(height: isEink ? Spacing.lg : Spacing.lg),
          // Continue button
          AuthContinueButton(
            isLoading: isLoading,
            onPressed: onSubmit,
            isEink: isEink,
            isDesktop: isDesktop,
            einkLoadingText: 'SENDING...',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMAIL SENT CONFIRMATION
// =============================================================================

/// Confirmation view shown after the reset email has been sent.
class _EmailSentConfirmation extends StatelessWidget {
  final String email;
  final bool isEink;
  final bool isDesktop;

  const _EmailSentConfirmation({
    required this.email,
    required this.isEink,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEink) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHECK YOUR EMAIL',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'We sent a password reset link to $email',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            "If you don't see the email, check your spam folder.",
            style: TextStyle(fontSize: 14, color: Color(0xFF606060)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Check your email',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'We sent a password reset link to $email',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          "If you don't see the email, check your spam folder.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
