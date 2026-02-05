import 'package:flutter/material.dart';
import 'color_schemes.g.dart';
import 'design_tokens.dart';

/// Display mode for the application.
/// Determines which theme and layout adaptations to use.
enum DisplayMode {
  /// Standard display (phone, tablet, desktop)
  standard,

  /// E-ink display mode (high contrast, no animations)
  eink,
}

/// Application theme configurations.
/// Provides ThemeData for light, dark, and e-ink display modes.
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // LIGHT THEME
  // ===========================================================================

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    // Typography
    textTheme: _textTheme,
    // Component themes
    elevatedButtonTheme: _elevatedButtonTheme(lightColorScheme),
    outlinedButtonTheme: _outlinedButtonTheme(lightColorScheme),
    textButtonTheme: _textButtonTheme(lightColorScheme),
    inputDecorationTheme: _inputDecorationTheme(lightColorScheme),
    cardTheme: _cardTheme(lightColorScheme),
    appBarTheme: _appBarTheme(lightColorScheme),
    bottomNavigationBarTheme: _bottomNavTheme(lightColorScheme),
    dividerTheme: _dividerTheme(lightColorScheme),
    snackBarTheme: _snackBarTheme(lightColorScheme),
    popupMenuTheme: _popupMenuTheme(lightColorScheme),
  );

  // ===========================================================================
  // DARK THEME
  // ===========================================================================

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    // Typography
    textTheme: _textTheme,
    // Component themes
    elevatedButtonTheme: _elevatedButtonTheme(darkColorScheme),
    outlinedButtonTheme: _outlinedButtonTheme(darkColorScheme),
    textButtonTheme: _textButtonTheme(darkColorScheme),
    inputDecorationTheme: _inputDecorationTheme(darkColorScheme),
    cardTheme: _cardTheme(darkColorScheme),
    appBarTheme: _appBarTheme(darkColorScheme),
    bottomNavigationBarTheme: _bottomNavTheme(darkColorScheme),
    dividerTheme: _dividerTheme(darkColorScheme),
    snackBarTheme: _snackBarTheme(darkColorScheme),
    popupMenuTheme: _popupMenuTheme(darkColorScheme),
  );

  // ===========================================================================
  // E-INK THEME
  // ===========================================================================

  static ThemeData get eink => ThemeData(
    useMaterial3: true,
    colorScheme: einkColorScheme,
    // Typography - larger for e-ink
    textTheme: _einkTextTheme,
    // Component themes - e-ink specific
    elevatedButtonTheme: _einkElevatedButtonTheme(),
    outlinedButtonTheme: _einkOutlinedButtonTheme(),
    textButtonTheme: _einkTextButtonTheme(),
    inputDecorationTheme: _einkInputDecorationTheme(),
    cardTheme: _einkCardTheme(),
    appBarTheme: _einkAppBarTheme(),
    bottomNavigationBarTheme: _einkBottomNavTheme(),
    dividerTheme: _einkDividerTheme(),
    snackBarTheme: _einkSnackBarTheme(),
    // Disable animations
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
  );

  // ===========================================================================
  // TYPOGRAPHY
  // ===========================================================================

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  // E-ink typography: larger minimum size, bolder weights
  static const TextTheme _einkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // ===========================================================================
  // STANDARD COMPONENT THEMES
  // ===========================================================================

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colors) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightMobile),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
          vertical: Spacing.buttonPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        elevation: AppElevation.level1,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightMobile),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
          vertical: Spacing.buttonPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        side: BorderSide(color: colors.outline, width: BorderWidths.thin),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(ColorScheme colors) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colors) {
    return InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: colors.outline,
          width: BorderWidths.inputDefault,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: colors.outline,
          width: BorderWidths.inputDefault,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: colors.primary,
          width: BorderWidths.inputFocused,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: colors.error,
          width: BorderWidths.inputError,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: colors.error,
          width: BorderWidths.inputError,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
    );
  }

  static CardThemeData _cardTheme(ColorScheme colors) {
    return CardThemeData(
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: const EdgeInsets.all(Spacing.sm),
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme colors) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: AppElevation.level1,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      titleTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme(ColorScheme colors) {
    return BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: AppElevation.level2,
    );
  }

  static DividerThemeData _dividerTheme(ColorScheme colors) {
    return DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: Spacing.md,
    );
  }

  static SnackBarThemeData _snackBarTheme(ColorScheme colors) {
    return SnackBarThemeData(
      backgroundColor: colors.inverseSurface,
      contentTextStyle: TextStyle(color: colors.onInverseSurface),
      actionTextColor: colors.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  static PopupMenuThemeData _popupMenuTheme(ColorScheme colors) {
    return PopupMenuThemeData(
      elevation: AppElevation.level3,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colors.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      textStyle: TextStyle(color: colors.onSurface),
      mouseCursor: WidgetStateMouseCursor.clickable,
    );
  }

  // ===========================================================================
  // E-INK COMPONENT THEMES
  // ===========================================================================

  static ElevatedButtonThemeData _einkElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightEink),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
          vertical: Spacing.buttonPaddingVertical,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 0,
        backgroundColor: EinkColors.black,
        foregroundColor: EinkColors.white,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _einkOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(ComponentSizes.buttonHeightEink),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.buttonPaddingHorizontal,
          vertical: Spacing.buttonPaddingVertical,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkDefault,
        ),
        backgroundColor: EinkColors.white,
        foregroundColor: EinkColors.black,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static TextButtonThemeData _einkTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: EinkColors.black,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  static InputDecorationTheme _einkInputDecorationTheme() {
    return const InputDecorationTheme(
      filled: true,
      fillColor: EinkColors.container,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkFocused,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkError,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkError,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      labelStyle: TextStyle(
        color: EinkColors.black,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(color: EinkColors.mediumGray, fontSize: 20),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }

  static CardThemeData _einkCardTheme() {
    return const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      margin: EdgeInsets.all(Spacing.md),
    );
  }

  static AppBarTheme _einkAppBarTheme() {
    return const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: EinkColors.white,
      foregroundColor: EinkColors.black,
      titleTextStyle: TextStyle(
        color: EinkColors.black,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      shape: Border(
        bottom: BorderSide(
          color: EinkColors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
    );
  }

  static BottomNavigationBarThemeData _einkBottomNavTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: EinkColors.white,
      selectedItemColor: EinkColors.black,
      unselectedItemColor: EinkColors.darkGray,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static DividerThemeData _einkDividerTheme() {
    return const DividerThemeData(
      color: EinkColors.lightGray,
      thickness: 2,
      space: Spacing.lg,
    );
  }

  static SnackBarThemeData _einkSnackBarTheme() {
    return const SnackBarThemeData(
      backgroundColor: EinkColors.black,
      contentTextStyle: TextStyle(color: EinkColors.white, fontSize: 16),
      actionTextColor: EinkColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      behavior: SnackBarBehavior.fixed,
    );
  }
}
