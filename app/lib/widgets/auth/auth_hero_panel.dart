import 'package:flutter/material.dart';
import 'package:papyrus/widgets/auth/curved_bottom_clipper.dart';

/// Hero gradient colors for auth pages.
class AuthColors {
  AuthColors._();

  // Light mode gradient
  static const Color gradientStartLight = Color(0xFF5654A8);
  static const Color gradientEndLight = Color(0xFF3E3C8F);

  // Dark mode gradient
  static const Color gradientStartDark = Color(0xFF3E3C8F);
  static const Color gradientEndDark = Color(0xFF272377);
}

/// Desktop hero panel with illustration background (no branding overlay).
/// Branding should be placed on the form side for better UX.
class AuthHeroPanel extends StatelessWidget {
  final bool isDark;

  const AuthHeroPanel({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final gradientStart = isDark
        ? AuthColors.gradientStartDark
        : AuthColors.gradientStartLight;
    final gradientEnd = isDark
        ? AuthColors.gradientEndDark
        : AuthColors.gradientEndLight;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background (fallback)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
          ),
        ),
        // Illustration filling the panel - clean, no overlays
        Positioned.fill(
          child: Image.asset(
            'assets/images/auth-illustration.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ],
    );
  }
}

/// Compact hero header for mobile auth pages (no branding overlay).
/// Branding should be placed in the form area below.
class CompactAuthHeader extends StatelessWidget {
  final bool isDark;
  final double height;

  const CompactAuthHeader({super.key, this.isDark = false, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final gradientStart = isDark
        ? AuthColors.gradientStartDark
        : AuthColors.gradientStartLight;
    final gradientEnd = isDark
        ? AuthColors.gradientEndDark
        : AuthColors.gradientEndLight;

    return ClipPath(
      clipper: CurvedBottomClipper(curveHeight: 30),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradientStart, gradientEnd],
                ),
              ),
            ),
            // Illustration - clean, no overlays
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth-illustration.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
