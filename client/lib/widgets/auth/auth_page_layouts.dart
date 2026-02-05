import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/auth/auth_branding.dart';
import 'package:papyrus/widgets/auth/auth_hero_panel.dart';
import 'package:papyrus/widgets/auth/eink_auth_header_bar.dart';

/// Mobile auth layout: compact hero header + scrollable form panel.
class MobileAuthLayout extends StatelessWidget {
  final String heading;
  final String subtitle;

  /// The form widget (login form, register form, etc.)
  final Widget form;

  /// Widgets placed below the form (divider, social button, switch link).
  final List<Widget> footer;

  const MobileAuthLayout({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.form,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          CompactAuthHeader(
            isDark: isDark,
            height: ComponentSizes.mobileHeroHeight,
          ),
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
                        const AuthBranding(),
                        const SizedBox(height: Spacing.md),
                        Text(
                          heading,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        form,
                        const Spacer(),
                        ...footer,
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

/// Desktop auth layout: hero panel (60%) + form panel (40%).
class DesktopAuthLayout extends StatelessWidget {
  final String heading;
  final String subtitle;

  /// The form widget (login form, register form, etc.)
  final Widget form;

  /// Widgets placed below the form (divider, social button, switch link).
  final List<Widget> footer;

  const DesktopAuthLayout({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.form,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          Expanded(flex: 6, child: AuthHeroPanel(isDark: isDark)),
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
                        const AuthBranding(),
                        const SizedBox(height: Spacing.md),
                        Text(
                          heading,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),
                        form,
                        ...footer,
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

/// E-ink auth layout: header bar + scrollable content area.
class EinkAuthLayout extends StatelessWidget {
  final String headerTitle;
  final VoidCallback onBack;

  /// The form widget (login form, register form, etc.)
  final Widget form;

  /// Widgets placed below the form (divider, social button, switch link).
  final List<Widget> footer;

  const EinkAuthLayout({
    super.key,
    required this.headerTitle,
    required this.onBack,
    required this.form,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            EinkAuthHeaderBar(title: headerTitle, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.pageMarginsEink),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [form, ...footer],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
