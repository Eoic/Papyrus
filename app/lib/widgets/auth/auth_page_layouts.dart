import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/auth/auth_branding.dart';
import 'package:papyrus/widgets/auth/auth_hero_panel.dart';

/// Mobile auth layout: compact hero header + scrollable form panel.
class MobileAuthLayout extends StatelessWidget {
  final String heading;
  final String subtitle;

  /// The form widget (login form, register form, etc.)
  final Widget form;

  /// Widgets placed below the form (divider, social button, switch link).
  final List<Widget> footer;

  /// Whether to show branding, heading, and subtitle above the form.
  final bool showHeader;

  const MobileAuthLayout({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.form,
    required this.footer,
    this.showHeader = true,
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
                        if (showHeader) ...[
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
                        ],
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
/// Includes a swap button to flip hero/form positions.
class DesktopAuthLayout extends StatefulWidget {
  final String heading;
  final String subtitle;

  /// The form widget (login form, register form, etc.)
  final Widget form;

  /// Widgets placed below the form (divider, social button, switch link).
  final List<Widget> footer;

  /// Whether to show branding, heading, and subtitle above the form.
  final bool showHeader;

  const DesktopAuthLayout({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.form,
    required this.footer,
    this.showHeader = true,
  });

  /// Persists swap state across page navigations within the same session.
  static bool _isSwapped = false;

  @override
  State<DesktopAuthLayout> createState() => _DesktopAuthLayoutState();
}

class _DesktopAuthLayoutState extends State<DesktopAuthLayout> {
  void _toggleSwap() {
    setState(() {
      DesktopAuthLayout._isSwapped = !DesktopAuthLayout._isSwapped;
    });
  }

  Widget _buildFormPanel(ThemeData theme) {
    final isSwapped = DesktopAuthLayout._isSwapped;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: Offset(isSwapped ? 4 : -4, 0),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ComponentSizes.authFormPanelPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ComponentSizes.authFormPanelMaxWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHeader) ...[
                  const AuthBranding(),
                  const SizedBox(height: Spacing.md),
                  Text(
                    widget.heading,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                ],
                widget.form,
                ...widget.footer,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSwapped = DesktopAuthLayout._isSwapped;

    final hero = Expanded(flex: 6, child: AuthHeroPanel(isDark: isDark));
    final form = Expanded(flex: 4, child: _buildFormPanel(theme));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Row(children: isSwapped ? [form, hero] : [hero, form]),
          // Swap button at the hero/form boundary
          Positioned(
            left: isSwapped ? null : 0,
            right: isSwapped ? 0 : null,
            top: 0,
            bottom: 0,
            child: _SwapPanelsButton(
              isSwapped: isSwapped,
              onPressed: _toggleSwap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular button that sits at the boundary between hero and form panels.
class _SwapPanelsButton extends StatelessWidget {
  final bool isSwapped;
  final VoidCallback onPressed;

  const _SwapPanelsButton({required this.isSwapped, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Position at 60% from the left (hero/form boundary)
        final totalWidth = MediaQuery.of(context).size.width;
        final boundaryOffset = totalWidth * 0.6;

        return SizedBox(
          width: totalWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(
                isSwapped
                    ? totalWidth - boundaryOffset - 20
                    : boundaryOffset - 20,
                0,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: theme.colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    child: Icon(
                      Icons.swap_horiz,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
