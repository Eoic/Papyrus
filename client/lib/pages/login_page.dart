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
import 'package:papyrus/widgets/buttons/google_sign_in.dart';
import 'package:papyrus/widgets/input/email_input.dart';
import 'package:papyrus/widgets/input/password_input.dart';
import 'package:papyrus/widgets/titled_divider.dart';

/// Login page for the Papyrus book management application.
/// Provides responsive layouts for mobile, desktop, and e-ink displays.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      context.goNamed('LIBRARY');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Incorrect email or password.';
      }

      _showErrorSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  void _navigateToRegister() {
    context.go('/register');
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
        headerTitle: 'SIGN IN',
        onBack: _navigateBack,
        form: _LoginForm(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          isLoading: _isLoading,
          onLogin: _handleLogin,
          isEink: true,
          isDesktop: false,
        ),
        footer: [
          const SizedBox(height: Spacing.xl),
          const TitledDivider(title: 'Or', isEink: true),
          const SizedBox(height: Spacing.md),
          const GoogleSignInButton(title: 'Sign in with Google', isEink: true),
          const SizedBox(height: Spacing.xl),
          AuthSwitchLink(
            promptText: "Don't have an account?",
            actionText: 'Sign up',
            einkPromptText: "DON'T HAVE AN ACCOUNT?",
            einkActionText: 'SIGN UP',
            onPressed: _navigateToRegister,
            isEink: true,
          ),
        ],
      );
    }

    return ResponsiveBuilder(
      mobile: (context) => MobileAuthLayout(
        heading: 'Welcome back',
        subtitle: 'Sign in to your account to continue',
        form: _LoginForm(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          isLoading: _isLoading,
          onLogin: _handleLogin,
          isEink: false,
          isDesktop: false,
        ),
        footer: [
          const TitledDivider(title: 'Or continue with'),
          const GoogleSignInButton(title: 'Sign in with Google'),
          const SizedBox(height: Spacing.md),
          AuthSwitchLink(
            promptText: "Don't have an account?",
            actionText: 'Sign up',
            einkPromptText: "DON'T HAVE AN ACCOUNT?",
            einkActionText: 'SIGN UP',
            onPressed: _navigateToRegister,
            isEink: false,
          ),
        ],
      ),
      desktop: (context) => DesktopAuthLayout(
        heading: 'Welcome back',
        subtitle: 'Sign in to your account to continue',
        form: _LoginForm(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          isLoading: _isLoading,
          onLogin: _handleLogin,
          isEink: false,
          isDesktop: true,
        ),
        footer: [
          const TitledDivider(title: 'Or continue with'),
          const GoogleSignInButton(title: 'Sign in with Google'),
          const SizedBox(height: Spacing.md),
          AuthSwitchLink(
            promptText: "Don't have an account?",
            actionText: 'Sign up',
            einkPromptText: "DON'T HAVE AN ACCOUNT?",
            einkActionText: 'SIGN UP',
            onPressed: _navigateToRegister,
            isEink: false,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LOGIN FORM
// =============================================================================

/// Login-specific form with email and password fields.
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isLoading;
  final VoidCallback onLogin;
  final bool isEink;
  final bool isDesktop;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isLoading,
    required this.onLogin,
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
            textInputAction: TextInputAction.next,
            onEditingComplete: () => passwordFocusNode.requestFocus(),
          ),
          SizedBox(height: isEink ? Spacing.lg : Spacing.md),
          // Password field
          PasswordInput(
            labelText: 'Password',
            controller: passwordController,
            focusNode: passwordFocusNode,
            isEink: isEink,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onLogin(),
          ),
          // Forgot password link (not for e-ink)
          if (!isEink) ...[
            const SizedBox(height: Spacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.go('/forgot-password');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ] else
            const SizedBox(height: Spacing.lg),
          // Continue button
          AuthContinueButton(
            isLoading: isLoading,
            onPressed: onLogin,
            isEink: isEink,
            isDesktop: isDesktop,
            einkLoadingText: 'SIGNING IN...',
          ),
        ],
      ),
    );
  }
}
