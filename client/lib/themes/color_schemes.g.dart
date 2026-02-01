import 'package:flutter/material.dart';

// =============================================================================
// LIGHT COLOR SCHEME
// =============================================================================

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF5654A8),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE2DFFF),
  onPrimaryContainer: Color(0xFF100563),
  secondary: Color(0xFF5D5C71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE3E0F9),
  onSecondaryContainer: Color(0xFF1A1A2C),
  tertiary: Color(0xFF7A5368),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8EA),
  onTertiaryContainer: Color(0xFF2F1124),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFFFBFF),
  onSurface: Color(0xFF1C1B1F),
  surfaceContainerHighest: Color(0xFFE4E1EC),
  onSurfaceVariant: Color(0xFF47464F),
  outline: Color(0xFF787680),
  onInverseSurface: Color(0xFFF3EFF4),
  inverseSurface: Color(0xFF313034),
  inversePrimary: Color(0xFFC3C0FF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF5654A8),
  outlineVariant: Color(0xFFC8C5D0),
  scrim: Color(0xFF000000),
);

// =============================================================================
// DARK COLOR SCHEME
// =============================================================================

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFC3C0FF),
  onPrimary: Color(0xFF272377),
  primaryContainer: Color(0xFF3E3C8F),
  onPrimaryContainer: Color(0xFFE2DFFF),
  secondary: Color(0xFFC7C4DD),
  onSecondary: Color(0xFF2F2F42),
  secondaryContainer: Color(0xFF464559),
  onSecondaryContainer: Color(0xFFE3E0F9),
  tertiary: Color(0xFFEAB9D2),
  onTertiary: Color(0xFF472639),
  tertiaryContainer: Color(0xFF603C50),
  onTertiaryContainer: Color(0xFFFFD8EA),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF1C1B1F),
  onSurface: Color(0xFFE5E1E6),
  surfaceContainerHighest: Color(0xFF47464F),
  onSurfaceVariant: Color(0xFFC8C5D0),
  outline: Color(0xFF928F9A),
  onInverseSurface: Color(0xFF1C1B1F),
  inverseSurface: Color(0xFFE5E1E6),
  inversePrimary: Color(0xFF5654A8),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFC3C0FF),
  outlineVariant: Color(0xFF47464F),
  scrim: Color(0xFF000000),
);

// =============================================================================
// E-INK COLOR SCHEME
// =============================================================================
// High contrast, grayscale-only colors optimized for e-ink displays.
// Rules:
// - NO gradients - use solid fills only
// - NO shadows - use 2px black borders instead
// - NO transparency/opacity - all colors must be solid
// - Maximum 5 grayscale values for optimal e-ink rendering

const einkColorScheme = ColorScheme(
  brightness: Brightness.light,
  // Primary elements: pure black
  primary: Color(0xFF000000),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF5F5F5),
  onPrimaryContainer: Color(0xFF000000),
  // Secondary: dark gray
  secondary: Color(0xFF404040),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFF5F5F5),
  onSecondaryContainer: Color(0xFF000000),
  // Tertiary: same as secondary for e-ink
  tertiary: Color(0xFF404040),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFF5F5F5),
  onTertiaryContainer: Color(0xFF000000),
  // Error: black (no red on e-ink)
  error: Color(0xFF000000),
  errorContainer: Color(0xFFF5F5F5),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF000000),
  // Surfaces: pure white
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF000000),
  surfaceContainerHighest: Color(0xFFF5F5F5),
  onSurfaceVariant: Color(0xFF404040),
  // Outlines: black for visibility
  outline: Color(0xFF000000),
  onInverseSurface: Color(0xFF000000),
  inverseSurface: Color(0xFFFFFFFF),
  inversePrimary: Color(0xFF000000),
  // Shadows: none (use borders instead)
  shadow: Color(0x00000000),
  surfaceTint: Color(0xFF000000),
  outlineVariant: Color(0xFFC0C0C0),
  scrim: Color(0xFF000000),
);

// E-ink specific colors for custom use
class EinkColors {
  EinkColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF404040);
  static const Color mediumGray = Color(0xFF808080);
  static const Color lightGray = Color(0xFFC0C0C0);
  static const Color container = Color(0xFFF5F5F5);
}
