// Design tokens for the Papyrus book management application.
// These tokens define the visual language across all platforms and themes.

// =============================================================================
// SPACING SYSTEM (8px grid)
// =============================================================================

class Spacing {
  Spacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Common combinations
  static const double buttonPaddingHorizontal = 24.0;
  static const double buttonPaddingVertical = 12.0;
  static const double cardPadding = 16.0;
  static const double listItemPaddingHorizontal = 16.0;
  static const double listItemPaddingVertical = 12.0;
  static const double formFieldSpacing = 16.0;

  // Page margins by platform
  static const double pageMarginsPhone = 16.0;
  static const double pageMarginsTablet = 24.0;
  static const double pageMarginsDesktop = 32.0;
  static const double pageMarginsEink = 48.0;
}

// =============================================================================
// RESPONSIVE BREAKPOINTS
// =============================================================================

class Breakpoints {
  Breakpoints._();

  // Width breakpoints
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktopSmall = 840;
  static const double desktopLarge = 1200;

  // Grid columns
  static const int mobileColumns = 4;
  static const int tabletColumns = 8;
  static const int desktopColumns = 12;

  // Gutters
  static const double mobileGutter = 16.0;
  static const double tabletGutter = 24.0;
  static const double desktopGutter = 24.0;

  // Margins
  static const double mobileMargin = 16.0;
  static const double tabletMargin = 24.0;
  static const double desktopSmallMargin = 24.0;
  static const double desktopLargeMargin = 32.0;
}

// =============================================================================
// BORDER RADIUS
// =============================================================================

class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 28.0;
  static const double full = 9999.0;

  // Specific uses
  static const double button = 8.0;
  static const double input = 4.0;
  static const double card = 12.0;
  static const double dialog = 28.0;
  static const double bottomSheet = 16.0;
  static const double googleButton = 40.0;

  // E-ink: Use none or sm only
  static const double einkButton = 0.0;
  static const double einkInput = 0.0;
  static const double einkCard = 0.0;
}

// =============================================================================
// TOUCH TARGETS
// =============================================================================

class TouchTargets {
  TouchTargets._();

  // Mobile
  static const double mobileMin = 44.0;
  static const double mobileRecommended = 48.0;
  static const double mobileSpacing = 8.0;

  // Desktop
  static const double desktopMin = 36.0;
  static const double desktopRecommended = 40.0;
  static const double desktopSpacing = 4.0;

  // E-ink (larger for imprecise touch)
  static const double einkMin = 56.0;
  static const double einkRecommended = 64.0;
  static const double einkSpacing = 16.0;
}

// =============================================================================
// COMPONENT SIZES
// =============================================================================

class ComponentSizes {
  ComponentSizes._();

  // Buttons
  static const double buttonHeightMobile = 50.0;
  static const double buttonHeightDesktop = 56.0;
  static const double buttonHeightEink = 64.0;
  static const double buttonMinWidth = 64.0;

  // Inputs
  static const double inputHeight = 56.0;
  static const double inputHeightEink = 64.0;

  // App bar
  static const double appBarHeight = 64.0;
  static const double einkHeaderHeight = 72.0;

  // Bottom navigation
  static const double bottomNavHeight = 80.0;

  // Logo sizes
  static const double logoWelcomeMobile = 150.0;
  static const double logoWelcomeDesktop = 200.0;
  static const double logoWelcomeEink = 200.0;
  static const double logoHeader = 80.0;
  static const double logoSmall = 48.0;

  // Card widths
  static const double authCardWidth = 480.0;
  static const double authCardPadding = 48.0;

  // Book covers
  static const double bookCoverWidthGrid = 120.0;
  static const double bookCoverHeightGrid = 180.0;
  static const double bookCoverWidthList = 60.0;
  static const double bookCoverHeightList = 90.0;
}

// =============================================================================
// ELEVATION / SHADOWS
// =============================================================================

class AppElevation {
  AppElevation._();

  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;

  // E-ink: No elevation, use borders instead
  static const double eink = 0.0;
}

// =============================================================================
// ANIMATION DURATIONS
// =============================================================================

class AnimationDurations {
  AnimationDurations._();

  static const Duration quick = Duration(milliseconds: 100);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasis = Duration(milliseconds: 300);
  static const Duration complex = Duration(milliseconds: 500);

  // E-ink: instant (no animations)
  static const Duration eink = Duration.zero;
}

// =============================================================================
// BORDER WIDTHS
// =============================================================================

class BorderWidths {
  BorderWidths._();

  static const double thin = 1.0;
  static const double medium = 2.0;
  static const double thick = 4.0;

  // Standard
  static const double inputDefault = 1.0;
  static const double inputFocused = 2.0;
  static const double inputError = 2.0;

  // E-ink: Minimum 2px for visibility
  static const double einkDefault = 2.0;
  static const double einkFocused = 4.0;
  static const double einkError = 4.0;
}

// =============================================================================
// ICON SIZES
// =============================================================================

class IconSizes {
  IconSizes._();

  static const double small = 18.0;
  static const double medium = 24.0;
  static const double large = 48.0;

  // Context-specific
  static const double navigation = 24.0;
  static const double action = 24.0;
  static const double listItem = 24.0;
  static const double indicator = 18.0;
  static const double display = 48.0;
}
