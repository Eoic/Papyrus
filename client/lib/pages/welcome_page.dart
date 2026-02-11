import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';
import 'package:provider/provider.dart';

/// Welcome page for the Papyrus book management application.
/// Provides responsive layouts for mobile and desktop displays.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationDurations.complex,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => _MobileWelcomeLayout(
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
        scaleAnimation: _scaleAnimation,
      ),
      desktop: (context) => _DesktopWelcomeLayout(
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
        scaleAnimation: _scaleAnimation,
      ),
    );
  }
}

// =============================================================================
// MOBILE LAYOUT
// =============================================================================

class _MobileWelcomeLayout extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  const _MobileWelcomeLayout({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.pageMarginsPhone,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo and branding section
              _AnimatedBrandingSection(
                fadeAnimation: fadeAnimation,
                scaleAnimation: scaleAnimation,
                logoSize: ComponentSizes.logoWelcomeMobile,
                titleStyle: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                ),
                taglineStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              // Action buttons section
              _AnimatedButtonsSection(
                fadeAnimation: fadeAnimation,
                slideAnimation: slideAnimation,
                buttonWidth: double.infinity,
              ),
              const SizedBox(height: Spacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DESKTOP LAYOUT
// =============================================================================

class _DesktopWelcomeLayout extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  const _DesktopWelcomeLayout({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageMarginsDesktop,
                  vertical: Spacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and branding section
                    _AnimatedBrandingSection(
                      fadeAnimation: fadeAnimation,
                      scaleAnimation: scaleAnimation,
                      logoSize: ComponentSizes.logoWelcomeDesktop,
                      titleStyle: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w400,
                      ),
                      taglineStyle: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    // Action buttons section
                    _AnimatedButtonsSection(
                      fadeAnimation: fadeAnimation,
                      slideAnimation: slideAnimation,
                      buttonWidth: 320,
                    ),
                  ],
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
// SHARED COMPONENTS
// =============================================================================

/// Animated branding section with logo, title, and tagline.
class _AnimatedBrandingSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final double logoSize;
  final TextStyle? titleStyle;
  final TextStyle? taglineStyle;

  const _AnimatedBrandingSection({
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.logoSize,
    required this.titleStyle,
    required this.taglineStyle,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: _BrandingContent(
          logoSize: logoSize,
          titleStyle: titleStyle,
          taglineStyle: taglineStyle,
        ),
      ),
    );
  }
}

/// Static branding content (logo, title, tagline).
class _BrandingContent extends StatelessWidget {
  final double logoSize;
  final TextStyle? titleStyle;
  final TextStyle? taglineStyle;

  const _BrandingContent({
    required this.logoSize,
    required this.titleStyle,
    required this.taglineStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Image.asset(
          'assets/images/logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: Spacing.md),
        // App title
        Text('Papyrus', style: titleStyle, textAlign: TextAlign.center),
        const SizedBox(height: Spacing.sm),
        // Tagline
        Text(
          'Your ultimate digital library',
          style: taglineStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Animated buttons section with primary and secondary actions.
class _AnimatedButtonsSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final double buttonWidth;

  const _AnimatedButtonsSection({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.buttonWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: _ButtonsContent(buttonWidth: buttonWidth),
      ),
    );
  }
}

/// Static buttons content.
class _ButtonsContent extends StatelessWidget {
  final double buttonWidth;

  const _ButtonsContent({required this.buttonWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary action: Get started
          const _PrimaryButton(),
          const SizedBox(height: Spacing.md),
          // Secondary action: Sign in
          const _SecondaryButton(),
          const SizedBox(height: Spacing.md),
          // Tertiary action: Offline mode
          const _OfflineModeLink(),
        ],
      ),
    );
  }
}

/// Primary "Get started" button.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () => context.go('/register'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightMobile),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal + 2,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      child: const Text(
        'Get started',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Secondary "Sign in" button.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightMobile),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: BorderWidths.thin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal + 2,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      child: const Text(
        'Sign in',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Tertiary "Use offline mode" link.
class _OfflineModeLink extends StatelessWidget {
  const _OfflineModeLink();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () {
        context.read<GoogleSignInProvider>().setOfflineMode(true);
        context.goNamed('LIBRARY');
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
      ),
      child: Text(
        'Use offline mode',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Subtle background gradient for desktop layout.
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.2,
          colors: isDark
              ? [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  theme.colorScheme.surface,
                ]
              : [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.surface,
                ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
