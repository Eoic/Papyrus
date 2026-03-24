import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/titled_divider.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= Breakpoints.desktopSmall;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome-illustration.png',
              fit: BoxFit.cover,
              alignment: isDesktop ? Alignment.centerLeft : Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark
                        ? const Color(0xCC18161D)
                        : const Color(0x885654A8)),
                    (isDark
                        ? const Color(0xE61A1720)
                        : const Color(0xC03E3C8F)),
                    (isDark
                        ? const Color(0xF518161C)
                        : const Color(0xE01F1D2B)),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: isDesktop
                      ? const Alignment(0.75, -0.2)
                      : const Alignment(0, -0.45),
                  radius: isDesktop ? 1.2 : 1.0,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isDesktop) {
                  final minDesktopHeight =
                      constraints.maxHeight - (Spacing.xl * 2);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.pageMarginsDesktop * 2,
                      vertical: Spacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minDesktopHeight > 0 ? minDesktopHeight : 0,
                      ),
                      child: _DesktopWelcomeContent(
                        maxHeight: constraints.maxHeight,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.pageMarginsTablet,
                    vertical: Spacing.md,
                  ),
                  child: _MobileWelcomeContent(
                    maxHeight: constraints.maxHeight - (Spacing.md * 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopWelcomeContent extends StatelessWidget {
  final double maxHeight;

  const _DesktopWelcomeContent({required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isShortDesktop = maxHeight < 860;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isShortDesktop ? Spacing.lg : Spacing.xl,
            vertical: isShortDesktop ? Spacing.lg : Spacing.xl,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WelcomeCopy(
                titleStyle:
                    (isShortDesktop
                            ? theme.textTheme.headlineLarge
                            : theme.textTheme.displaySmall)
                        ?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'MadimiOne',
                        ),
                subtitleStyle:
                    (isShortDesktop
                            ? theme.textTheme.bodyLarge
                            : theme.textTheme.titleLarge)
                        ?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                center: true,
                logoSize: isShortDesktop ? 96 : 120,
                titleSpacing: isShortDesktop ? 12 : 20,
                subtitleSpacing: isShortDesktop ? 12 : Spacing.md,
              ),
              SizedBox(height: isShortDesktop ? Spacing.lg : Spacing.xl),
              _WelcomeActions(
                center: true,
                compact: isShortDesktop,
                useSurfaceColors: true,
                isDesktop: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileWelcomeContent extends StatelessWidget {
  final double maxHeight;

  const _MobileWelcomeContent({required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isShortScreen = maxHeight < 760;

    return SizedBox(
      height: maxHeight,
      child: Column(
        children: [
          Spacer(flex: isShortScreen ? 2 : 3),
          _WelcomeCopy(
            titleStyle:
                (isShortScreen
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.headlineLarge)
                    ?.copyWith(color: Colors.white, fontFamily: 'MadimiOne'),
            subtitleStyle:
                (isShortScreen
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: isShortScreen ? 1.5 : 1.55,
                    ),
            center: true,
            logoSize: isShortScreen ? 88 : 104,
            titleSpacing: isShortScreen ? 12 : 20,
            subtitleSpacing: isShortScreen ? 12 : Spacing.md,
          ),
          SizedBox(height: isShortScreen ? Spacing.lg : Spacing.xl),
          const _WelcomeActions(center: true, compact: true),
          Spacer(flex: isShortScreen ? 3 : 4),
          SizedBox(height: isShortScreen ? Spacing.lg : Spacing.xl),
        ],
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool center;
  final double logoSize;
  final double titleSpacing;
  final double subtitleSpacing;

  const _WelcomeCopy({
    required this.titleStyle,
    required this.subtitleStyle,
    required this.center,
    this.logoSize = 128,
    this.titleSpacing = Spacing.lg,
    this.subtitleSpacing = Spacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(height: titleSpacing),
        Text(
          'Papyrus',
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: titleStyle,
        ),
        SizedBox(height: subtitleSpacing),
        Text(
          'Manage your library, track reading progress, and read anywhere.',
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: subtitleStyle,
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  final bool center;
  final bool compact;
  final bool useSurfaceColors;
  final bool isDesktop;

  const _WelcomeActions({
    required this.center,
    this.compact = false,
    this.useSurfaceColors = false,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CreateAccountButton(isDesktop: isDesktop),
        const SizedBox(height: Spacing.md),
        _SignInButton(isDesktop: isDesktop, useSurfaceColors: useSurfaceColors),
        SizedBox(height: compact ? Spacing.sm : Spacing.sm),
        TitledDivider(
          title: 'or',
          verticalPadding: compact ? Spacing.sm : Spacing.md,
        ),
        _OfflineModeLink(center: center),
      ],
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  final bool isDesktop;

  const _CreateAccountButton({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () => context.go('/register'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(
          isDesktop
              ? ComponentSizes.buttonHeightDesktop
              : ComponentSizes.buttonHeightMobile,
        ),
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
      child: const Text(
        'Create an account',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final bool isDesktop;
  final bool useSurfaceColors;

  const _SignInButton({
    required this.isDesktop,
    required this.useSurfaceColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(
          isDesktop
              ? ComponentSizes.buttonHeightDesktop
              : ComponentSizes.buttonHeightMobile,
        ),
        foregroundColor: useSurfaceColors
            ? theme.colorScheme.onSurface
            : Colors.white,
        side: BorderSide(
          color: useSurfaceColors
              ? theme.colorScheme.outline
              : Colors.white.withValues(alpha: 0.38),
          width: BorderWidths.thin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
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

class _OfflineModeLink extends StatelessWidget {
  final bool center;

  const _OfflineModeLink({required this.center});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          context.read<AuthProvider>().setOfflineMode(true);
          context.goNamed('LIBRARY');
        },
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Use offline mode'),
      ),
    );
  }
}
