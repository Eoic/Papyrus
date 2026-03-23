import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';
import 'package:papyrus/widgets/auth/auth_continue_button.dart';
import 'package:papyrus/widgets/auth/auth_page_layouts.dart';
import 'package:papyrus/widgets/auth/auth_switch_link.dart';
import 'package:papyrus/widgets/input/email_input.dart';

/// Forgot password page for the Papyrus book management application.
/// Provides responsive layouts for mobile and desktop displays.
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
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;

      String message;
      final msg = e.message.toLowerCase();
      if (msg.contains('too many requests')) {
        message = 'Too many attempts. Please try again later.';
      } else {
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

  Widget _buildForm({required bool isDesktop}) {
    if (_emailSent) {
      return _EmailSentConfirmation(email: _emailController.text.trim());
    }
    return _ForgotPasswordForm(
      formKey: _formKey,
      emailController: _emailController,
      emailFocusNode: _emailFocusNode,
      isLoading: _isLoading,
      onSubmit: _handleResetPassword,
      isDesktop: isDesktop,
    );
  }

  List<Widget> _buildFooter() {
    return [
      const SizedBox(height: Spacing.md),
      AuthSwitchLink(
        promptText: 'Remember your password?',
        actionText: 'Sign in',
        onPressed: _navigateToLogin,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => MobileAuthLayout(
        heading: 'Reset password',
        subtitle: 'Enter your email to receive a password reset link',
        showHeader: !_emailSent,
        form: _buildForm(isDesktop: false),
        footer: _buildFooter(),
      ),
      desktop: (context) => DesktopAuthLayout(
        heading: 'Reset password',
        subtitle: 'Enter your email to receive a password reset link',
        showHeader: !_emailSent,
        form: _buildForm(isDesktop: true),
        footer: _buildFooter(),
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
  final bool isDesktop;

  const _ForgotPasswordForm({
    required this.formKey,
    required this.emailController,
    required this.emailFocusNode,
    required this.isLoading,
    required this.onSubmit,
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
          EmailInput(
            labelText: 'Email address',
            controller: emailController,
            focusNode: emailFocusNode,
            textInputAction: TextInputAction.done,
            onEditingComplete: onSubmit,
          ),
          const SizedBox(height: Spacing.lg),
          AuthContinueButton(
            isLoading: isLoading,
            onPressed: onSubmit,
            isDesktop: isDesktop,
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

  const _EmailSentConfirmation({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
