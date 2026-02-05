import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';
import 'package:papyrus/widgets/auth/auth_hero_panel.dart';
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

  // TODO: Remove this flag before production - bypasses authentication
  static const bool _bypassAuth = true;

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Bypass validation and auth for testing
    if (_bypassAuth) {
      setState(() => _isLoading = true);
      // Simulate brief loading for UX
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.goNamed('LIBRARY');
      return;
    }

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

    // E-ink mode has its own dedicated layout
    if (isEink) {
      return _EinkLoginLayout(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        emailFocusNode: _emailFocusNode,
        passwordFocusNode: _passwordFocusNode,
        isLoading: _isLoading,
        onLogin: _handleLogin,
        onRegister: _navigateToRegister,
        onBack: _navigateBack,
      );
    }

    return ResponsiveBuilder(
      mobile: (context) => _MobileLoginLayout(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        emailFocusNode: _emailFocusNode,
        passwordFocusNode: _passwordFocusNode,
        isLoading: _isLoading,
        onLogin: _handleLogin,
        onRegister: _navigateToRegister,
        onBack: _navigateBack,
      ),
      desktop: (context) => _DesktopLoginLayout(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        emailFocusNode: _emailFocusNode,
        passwordFocusNode: _passwordFocusNode,
        isLoading: _isLoading,
        onLogin: _handleLogin,
        onRegister: _navigateToRegister,
        onBack: _navigateBack,
      ),
    );
  }
}

// =============================================================================
// MOBILE LAYOUT (0-599px)
// =============================================================================

class _MobileLoginLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const _MobileLoginLayout({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isLoading,
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Compact hero header with curved bottom
          CompactAuthHeader(
            isDark: isDark,
            height: ComponentSizes.mobileHeroHeight,
          ),
          // Form content
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Spacing.xl),
                        // Branding
                        const _AuthBranding(),
                        const SizedBox(height: Spacing.xl),
                        // Sign in header
                        Text(
                          'Sign in',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        // Login form
                        _LoginForm(
                          formKey: formKey,
                          emailController: emailController,
                          passwordController: passwordController,
                          emailFocusNode: emailFocusNode,
                          passwordFocusNode: passwordFocusNode,
                          isLoading: isLoading,
                          onLogin: onLogin,
                          isEink: false,
                          isDesktop: false,
                        ),
                        const Spacer(),
                        // Social sign-in section
                        const TitledDivider(title: 'Or continue with'),
                        const GoogleSignInButton(title: 'Sign in with Google'),
                        const SizedBox(height: Spacing.md),
                        // Sign up link
                        _SignUpLink(onRegister: onRegister, isEink: false),
                        const SizedBox(height: Spacing.lg),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DESKTOP LAYOUT (840px+) - Split Screen
// =============================================================================

class _DesktopLoginLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const _DesktopLoginLayout({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isLoading,
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          // Hero panel (60%)
          Expanded(flex: 6, child: AuthHeroPanel(isDark: isDark)),
          // Form panel (40%)
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(-4, 0),
                  ),
                ],
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(
                    ComponentSizes.authFormPanelPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ComponentSizes.authFormPanelMaxWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Branding
                        const _AuthBranding(),
                        const SizedBox(height: Spacing.xxl),
                        // Sign in header
                        Text(
                          'Sign in',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),
                        // Login form
                        _LoginForm(
                          formKey: formKey,
                          emailController: emailController,
                          passwordController: passwordController,
                          emailFocusNode: emailFocusNode,
                          passwordFocusNode: passwordFocusNode,
                          isLoading: isLoading,
                          onLogin: onLogin,
                          isEink: false,
                          isDesktop: true,
                        ),
                        const SizedBox(height: Spacing.lg),
                        // Social sign-in section
                        const TitledDivider(title: 'Or continue with'),
                        const GoogleSignInButton(title: 'Sign in with Google'),
                        const SizedBox(height: Spacing.xl),
                        // Sign up link
                        _SignUpLink(onRegister: onRegister, isEink: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// E-INK LAYOUT
// =============================================================================

class _EinkLoginLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const _EinkLoginLayout({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isLoading,
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // E-ink header bar with back button
            _EinkHeaderBar(onBack: onBack),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.pageMarginsEink),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Login form
                    _LoginForm(
                      formKey: formKey,
                      emailController: emailController,
                      passwordController: passwordController,
                      emailFocusNode: emailFocusNode,
                      passwordFocusNode: passwordFocusNode,
                      isLoading: isLoading,
                      onLogin: onLogin,
                      isEink: true,
                      isDesktop: false,
                    ),
                    const SizedBox(height: Spacing.xl),
                    // Social sign-in section
                    const TitledDivider(title: 'Or', isEink: true),
                    const SizedBox(height: Spacing.md),
                    const GoogleSignInButton(
                      title: 'Sign in with Google',
                      isEink: true,
                    ),
                    const SizedBox(height: Spacing.xl),
                    // Sign up link
                    _SignUpLink(onRegister: onRegister, isEink: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// E-ink header bar with back button and title.
class _EinkHeaderBar extends StatelessWidget {
  final VoidCallback onBack;

  const _EinkHeaderBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ComponentSizes.einkHeaderHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          SizedBox(
            width: ComponentSizes.einkHeaderHeight,
            height: ComponentSizes.einkHeaderHeight,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back,
                size: IconSizes.large,
                color: Colors.black,
              ),
            ),
          ),
          // Title
          const Expanded(
            child: Text(
              'SIGN IN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Spacer to balance the layout
          const SizedBox(width: ComponentSizes.einkHeaderHeight),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED COMPONENTS
// =============================================================================

/// Reusable login form widget.
/// Can be used across all layouts (mobile, desktop, e-ink).
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
    final inputHeight = isDesktop ? ComponentSizes.buttonHeightDesktop : null;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email field
          if (isDesktop && !isEink)
            SizedBox(
              height: inputHeight,
              child: EmailInput(
                labelText: 'Email address',
                controller: emailController,
                focusNode: emailFocusNode,
                isEink: isEink,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => passwordFocusNode.requestFocus(),
              ),
            )
          else
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
          if (isDesktop && !isEink)
            SizedBox(
              height: inputHeight,
              child: PasswordInput(
                labelText: 'Password',
                controller: passwordController,
                focusNode: passwordFocusNode,
                isEink: isEink,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onLogin(),
              ),
            )
          else
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
            if (!isDesktop) const SizedBox(height: Spacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password flow
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
            if (!isDesktop) const SizedBox(height: Spacing.sm),
          ] else
            const SizedBox(height: Spacing.lg),
          // Continue button
          _ContinueButton(
            isLoading: isLoading,
            onPressed: onLogin,
            isEink: isEink,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }
}

/// Continue/submit button with loading state.
class _ContinueButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isEink;
  final bool isDesktop;

  const _ContinueButton({
    required this.isLoading,
    required this.onPressed,
    required this.isEink,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEink) {
      return _buildEinkButton(context);
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

  Widget _buildEinkButton(BuildContext context) {
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
        isLoading ? 'SIGNING IN...' : 'CONTINUE',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Sign up link at the bottom of the form.
class _SignUpLink extends StatelessWidget {
  final VoidCallback onRegister;
  final bool isEink;

  const _SignUpLink({required this.onRegister, required this.isEink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEink) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "DON'T HAVE AN ACCOUNT?",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: Color(0xFF404040),
            ),
          ),
          TextButton(
            onPressed: onRegister,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationThickness: 2,
              ),
            ),
            child: const Text('SIGN UP'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onRegister,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Sign up'),
        ),
      ],
    );
  }
}

/// Branding element with logo and app name.
/// Placed at the top of the form panel.
class _AuthBranding extends StatelessWidget {
  const _AuthBranding();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/logo-icon-light.svg',
          width: 48,
          height: 48,
        ),
        const SizedBox(width: 16),
        Text(
          'Papyrus',
          style: TextStyle(
            fontFamily: 'MadimiOne',
            fontSize: 32,
            fontWeight: FontWeight.normal,
            color: AuthColors.gradientStartLight,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
