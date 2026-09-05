import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';
import 'package:papyrus/widgets/auth/auth_continue_button.dart';
import 'package:papyrus/widgets/auth/auth_page_layouts.dart';
import 'package:papyrus/widgets/auth/auth_switch_link.dart';
import 'package:papyrus/widgets/input/email_input.dart';
import 'package:papyrus/widgets/input/password_input.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/themes/app_motion.dart';

/// Forgot password page for the Papyrus book management application.
/// Provides responsive layouts for mobile and desktop displays.
class ForgotPasswordPage extends StatefulWidget {
  final String? resetToken;
  final bool isResetLink;

  const ForgotPasswordPage({super.key, this.resetToken, this.isResetLink = false});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  bool _passwordReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
      final message = await context.read<AuthProvider>().forgotPassword(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      if (message != null) {
        _showSuccessSnackBar(message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  Future<void> _handleSetNewPassword() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final resetToken = widget.resetToken;

    if (resetToken == null || resetToken.isEmpty) {
      _showErrorSnackBar('Password reset link is invalid.');
      return;
    }

    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      final message = await context.read<AuthProvider>().resetPassword(
        token: resetToken,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (message == null) {
        _showErrorSnackBar(context.read<AuthProvider>().error ?? 'Failed to reset password.');
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _isLoading = false;
        _passwordReset = true;
      });
      _showSuccessSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  String? _validatePasswordStrength(String? value) {
    if (value == null || value.length < 8) {
      return 'Minimum 8 characters';
    }

    return null;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      snackBarAnimationStyle: AppMotion.animationStyle(context),
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      snackBarAnimationStyle: AppMotion.animationStyle(context),
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
    if (_passwordReset) {
      return const _PasswordResetConfirmation();
    }

    if (widget.isResetLink) {
      if (widget.resetToken == null || widget.resetToken!.isEmpty) {
        return const _InvalidResetLink();
      }

      return _SetNewPasswordForm(
        formKey: _resetFormKey,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        passwordFocusNode: _passwordFocusNode,
        confirmPasswordFocusNode: _confirmPasswordFocusNode,
        isLoading: _isLoading,
        isDesktop: isDesktop,
        onSubmit: _handleSetNewPassword,
        validatePasswordStrength: _validatePasswordStrength,
        validateConfirmPassword: _validateConfirmPassword,
      );
    }

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
      AuthSwitchLink(promptText: 'Remember your password?', actionText: 'Sign in', onPressed: _navigateToLogin),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.isResetLink ? 'Create new password' : 'Reset password';
    final subtitle = widget.isResetLink
        ? 'Enter a new password for your account'
        : 'Enter your email to receive a password reset link';
    final showHeader = !_emailSent && !_passwordReset;

    return ResponsiveBuilder(
      mobile: (context) => MobileAuthLayout(
        heading: heading,
        subtitle: subtitle,
        showHeader: showHeader,
        form: _buildForm(isDesktop: false),
        footer: _buildFooter(),
      ),
      desktop: (context) => DesktopAuthLayout(
        heading: heading,
        subtitle: subtitle,
        showHeader: showHeader,
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
          AuthContinueButton(isLoading: isLoading, onPressed: onSubmit, isDesktop: isDesktop),
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
        Icon(Icons.mark_email_read_outlined, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: Spacing.sm),
        Text(
          'Check your email',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'We sent a password reset link to $email',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          "If you don't see the email, check your spam folder.",
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SetNewPasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final bool isLoading;
  final bool isDesktop;
  final VoidCallback onSubmit;
  final String? Function(String?) validatePasswordStrength;
  final String? Function(String?) validateConfirmPassword;

  const _SetNewPasswordForm({
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.isLoading,
    required this.isDesktop,
    required this.onSubmit,
    required this.validatePasswordStrength,
    required this.validateConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PasswordInput(
            labelText: 'New password',
            controller: passwordController,
            focusNode: passwordFocusNode,
            textInputAction: TextInputAction.next,
            extraValidator: validatePasswordStrength,
            onEditingComplete: () => confirmPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: Spacing.md),
          PasswordInput(
            labelText: 'Confirm new password',
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocusNode,
            textInputAction: TextInputAction.done,
            extraValidator: validateConfirmPassword,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: Spacing.lg),
          AuthContinueButton(isLoading: isLoading, onPressed: onSubmit, isDesktop: isDesktop),
        ],
      ),
    );
  }
}

class _InvalidResetLink extends StatelessWidget {
  const _InvalidResetLink();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.link_off_outlined, size: 72, color: theme.colorScheme.error),
        const SizedBox(height: Spacing.sm),
        Text(
          'Invalid reset link',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Request a new password reset email and use the latest link.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.lg),
        FilledButton(onPressed: () => context.go('/forgot-password'), child: const Text('Request new link')),
      ],
    );
  }
}

class _PasswordResetConfirmation extends StatelessWidget {
  const _PasswordResetConfirmation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: Spacing.sm),
        Text(
          'Password reset',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'You can now sign in with your new password.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
