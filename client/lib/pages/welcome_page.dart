import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/responsive.dart';

/// Welcome page for the Papyrus book management application.
/// Provides responsive layouts for mobile, desktop, and e-ink displays.
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
    final displayMode = context.watch<DisplayModeProvider>();
    final isEink = displayMode.isEinkMode;

    return ResponsiveBuilder(
      mobile: (context) => _MobileWelcomeLayout(
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
        scaleAnimation: _scaleAnimation,
        isEink: isEink,
      ),
      desktop: (context) => _DesktopWelcomeLayout(
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
        scaleAnimation: _scaleAnimation,
        isEink: isEink,
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
  final bool isEink;

  const _MobileWelcomeLayout({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
    required this.isEink,
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
                isEink: isEink,
                logoSize: ComponentSizes.logoWelcomeMobile,
                titleStyle: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: isEink ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: isEink ? 2.0 : 0,
                ),
                taglineStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: isEink
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              // Action buttons section
              _AnimatedButtonsSection(
                fadeAnimation: fadeAnimation,
                slideAnimation: slideAnimation,
                isEink: isEink,
                buttonWidth: double.infinity,
              ),
              SizedBox(height: isEink ? Spacing.lg : Spacing.md),
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
  final bool isEink;

  const _DesktopWelcomeLayout({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
    required this.isEink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (only for standard mode)
          if (!isEink) const _BackgroundGradient(),
          // Content
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
                      isEink: isEink,
                      logoSize: ComponentSizes.logoWelcomeDesktop,
                      titleStyle: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 56,
                        fontWeight: isEink ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: isEink ? 3.0 : 0,
                      ),
                      taglineStyle: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        color: isEink
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isEink ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: isEink ? Spacing.xxl : Spacing.xl),
                    // Action buttons section
                    _AnimatedButtonsSection(
                      fadeAnimation: fadeAnimation,
                      slideAnimation: slideAnimation,
                      isEink: isEink,
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
  final bool isEink;
  final double logoSize;
  final TextStyle? titleStyle;
  final TextStyle? taglineStyle;

  const _AnimatedBrandingSection({
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.isEink,
    required this.logoSize,
    required this.titleStyle,
    required this.taglineStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Skip animations in e-ink mode
    if (isEink) {
      return _BrandingContent(
        isEink: isEink,
        logoSize: logoSize,
        titleStyle: titleStyle,
        taglineStyle: taglineStyle,
      );
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: _BrandingContent(
          isEink: isEink,
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
  final bool isEink;
  final double logoSize;
  final TextStyle? titleStyle;
  final TextStyle? taglineStyle;

  const _BrandingContent({
    required this.isEink,
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
        _WelcomeLogo(size: logoSize, isEink: isEink),
        SizedBox(height: isEink ? Spacing.lg : Spacing.md),
        // App title
        Text(
          isEink ? 'PAPYRUS' : 'Papyrus',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
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

/// Welcome logo with optional e-ink styling.
class _WelcomeLogo extends StatelessWidget {
  final double size;
  final bool isEink;

  const _WelcomeLogo({required this.size, required this.isEink});

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Apply grayscale filter for e-ink mode
      color: isEink ? Colors.black : null,
      colorBlendMode: isEink ? BlendMode.srcIn : null,
    );

    // Add a subtle container for e-ink mode to ensure visibility
    if (isEink) {
      logo = Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        child: logo,
      );
    }

    return logo;
  }
}

/// Animated buttons section with primary and secondary actions.
class _AnimatedButtonsSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final bool isEink;
  final double buttonWidth;

  const _AnimatedButtonsSection({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.isEink,
    required this.buttonWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Skip animations in e-ink mode
    if (isEink) {
      return _ButtonsContent(isEink: isEink, buttonWidth: buttonWidth);
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: _ButtonsContent(isEink: isEink, buttonWidth: buttonWidth),
      ),
    );
  }
}

/// Static buttons content.
class _ButtonsContent extends StatelessWidget {
  final bool isEink;
  final double buttonWidth;

  const _ButtonsContent({required this.isEink, required this.buttonWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary action: Get started
          _PrimaryButton(isEink: isEink),
          SizedBox(height: isEink ? Spacing.lg : Spacing.md),
          // Secondary action: Sign in
          _SecondaryButton(isEink: isEink),
          SizedBox(height: isEink ? Spacing.lg : Spacing.md),
          // Tertiary action: Offline mode
          _OfflineModeLink(isEink: isEink),
        ],
      ),
    );
  }
}

/// Primary "Get started" button.
class _PrimaryButton extends StatelessWidget {
  final bool isEink;

  const _PrimaryButton({required this.isEink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () => context.go('/register'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(
          isEink
              ? ComponentSizes.buttonHeightEink
              : ComponentSizes.buttonHeightMobile,
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: isEink ? AppElevation.eink : AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isEink ? AppRadius.einkButton : AppRadius.button,
          ),
          side: isEink
              ? BorderSide(
                  color: theme.colorScheme.primary,
                  width: BorderWidths.einkDefault,
                )
              : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal + 2,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      child: Text(
        'Get started',
        style: TextStyle(
          fontSize: isEink ? 20 : 16,
          fontWeight: isEink ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: isEink ? 0.5 : 0,
        ),
      ),
    );
  }
}

/// Secondary "Sign in" button.
class _SecondaryButton extends StatelessWidget {
  final bool isEink;

  const _SecondaryButton({required this.isEink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(
          isEink
              ? ComponentSizes.buttonHeightEink
              : ComponentSizes.buttonHeightMobile,
        ),
        side: BorderSide(
          color: isEink ? Colors.black : theme.colorScheme.outline,
          width: isEink ? BorderWidths.einkDefault : BorderWidths.thin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isEink ? AppRadius.einkButton : AppRadius.button,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal + 2,
          vertical: Spacing.buttonPaddingVertical,
        ),
      ),
      child: Text(
        'Sign in',
        style: TextStyle(
          fontSize: isEink ? 20 : 16,
          fontWeight: isEink ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: isEink ? 0.5 : 0,
        ),
      ),
    );
  }
}

/// Tertiary "Use offline mode" link.
class _OfflineModeLink extends StatelessWidget {
  final bool isEink;

  const _OfflineModeLink({required this.isEink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // E-ink mode: underlined text button with larger touch target
    if (isEink) {
      return SizedBox(
        height: TouchTargets.einkRecommended,
        child: TextButton(
          onPressed: () => context.goNamed('LIBRARY'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          child: const Text(
            'Use offline mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
        ),
      );
    }

    // Standard mode: subtle text button
    return TextButton(
      onPressed: () => context.goNamed('LIBRARY'),
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

/// Subtle background gradient for desktop layout (standard mode only).
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
