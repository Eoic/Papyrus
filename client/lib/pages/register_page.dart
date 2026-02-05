import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';
import 'package:papyrus/widgets/auth/auth_continue_button.dart';
import 'package:papyrus/widgets/auth/auth_page_layouts.dart';
import 'package:papyrus/widgets/auth/auth_switch_link.dart';
import 'package:papyrus/widgets/buttons/google_sign_in.dart';
import 'package:papyrus/widgets/input/email_input.dart';
import 'package:papyrus/widgets/input/name_input.dart';
import 'package:papyrus/widgets/input/password_input.dart';
import 'package:papyrus/widgets/titled_divider.dart';

/// Register page for the Papyrus book management application.
/// Provides responsive layouts for mobile and desktop displays.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      context.goNamed('LIBRARY');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password registration is not enabled.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use a stronger password.';
          break;
        default:
          message = 'Registration failed. Please try again.';
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

  void _navigateToLogin() {
    context.go('/login');
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validatePasswordStrength(String? value) {
    if (value != null && value.length < 8) {
      return 'Minimum 8 characters';
    }
    return null;
  }

  List<Widget> _buildFooter() {
    return [
      const TitledDivider(title: 'Or continue with'),
      const GoogleSignInButton(title: 'Sign up with Google'),
      const SizedBox(height: Spacing.md),
      AuthSwitchLink(
        promptText: 'Already have an account?',
        actionText: 'Sign in',
        onPressed: _navigateToLogin,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => MobileAuthLayout(
        heading: 'Create account',
        subtitle: 'Sign up for a new account to get started',
        form: _RegisterForm(
          formKey: _formKey,
          displayNameController: _displayNameController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          displayNameFocusNode: _displayNameFocusNode,
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          confirmPasswordFocusNode: _confirmPasswordFocusNode,
          isLoading: _isLoading,
          onRegister: _handleRegister,
          isDesktop: false,
          validatePasswordStrength: _validatePasswordStrength,
          validateConfirmPassword: _validateConfirmPassword,
        ),
        footer: _buildFooter(),
      ),
      desktop: (context) => DesktopAuthLayout(
        heading: 'Create account',
        subtitle: 'Sign up for a new account to get started',
        form: _RegisterForm(
          formKey: _formKey,
          displayNameController: _displayNameController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          displayNameFocusNode: _displayNameFocusNode,
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          confirmPasswordFocusNode: _confirmPasswordFocusNode,
          isLoading: _isLoading,
          onRegister: _handleRegister,
          isDesktop: true,
          validatePasswordStrength: _validatePasswordStrength,
          validateConfirmPassword: _validateConfirmPassword,
        ),
        footer: _buildFooter(),
      ),
    );
  }
}

// =============================================================================
// REGISTER FORM
// =============================================================================

/// Register-specific form with display name, email, password, and confirm password fields.
class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode displayNameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final bool isLoading;
  final VoidCallback onRegister;
  final bool isDesktop;
  final String? Function(String?) validatePasswordStrength;
  final String? Function(String?) validateConfirmPassword;

  const _RegisterForm({
    required this.formKey,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.displayNameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.isLoading,
    required this.onRegister,
    required this.isDesktop,
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
          NameInput(
            labelText: 'Display name',
            controller: displayNameController,
            focusNode: displayNameFocusNode,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => emailFocusNode.requestFocus(),
          ),
          const SizedBox(height: Spacing.md),
          EmailInput(
            labelText: 'Email address',
            controller: emailController,
            focusNode: emailFocusNode,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: Spacing.md),
          PasswordInput(
            labelText: 'Password',
            controller: passwordController,
            focusNode: passwordFocusNode,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => confirmPasswordFocusNode.requestFocus(),
            extraValidator: validatePasswordStrength,
          ),
          const SizedBox(height: Spacing.md),
          PasswordInput(
            labelText: 'Confirm password',
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocusNode,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onRegister(),
            extraValidator: validateConfirmPassword,
          ),
          const SizedBox(height: Spacing.lg),
          AuthContinueButton(
            isLoading: isLoading,
            onPressed: onRegister,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }
}
