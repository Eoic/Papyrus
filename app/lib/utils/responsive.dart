import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Device form factor categories
enum DeviceType { mobile, tablet, desktop }

/// Utility class for responsive design and platform detection.
class Responsive {
  Responsive._();

  // ===========================================================================
  // BREAKPOINT DETECTION
  // ===========================================================================

  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.desktopSmall) {
      return DeviceType.desktop;
    } else if (width >= Breakpoints.tablet) {
      return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }

  /// Check if the device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if the device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if the device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if the device is tablet or larger
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.tablet;
  }

  /// Check if the device is desktop or larger
  static bool isDesktopOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;
  }

  /// Check if the device is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktopLarge;
  }

  // ===========================================================================
  // PLATFORM DETECTION
  // ===========================================================================

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platform (iOS or Android)
  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if running on desktop platform (Windows, macOS, Linux)
  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Check if running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Check if running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  // ===========================================================================
  // RESPONSIVE VALUES
  // ===========================================================================

  /// Get page margin based on device type
  static double getPageMargin(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.desktop:
        return isLargeDesktop(context)
            ? Breakpoints.desktopLargeMargin
            : Breakpoints.desktopSmallMargin;
      case DeviceType.tablet:
        return Breakpoints.tabletMargin;
      case DeviceType.mobile:
        return Breakpoints.mobileMargin;
    }
  }

  /// Get grid column count based on device type
  static int getGridColumns(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.desktop:
        return Breakpoints.desktopColumns;
      case DeviceType.tablet:
        return Breakpoints.tabletColumns;
      case DeviceType.mobile:
        return Breakpoints.mobileColumns;
    }
  }

  /// Get gutter width based on device type
  static double getGutter(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.desktop:
        return Breakpoints.desktopGutter;
      case DeviceType.tablet:
        return Breakpoints.tabletGutter;
      case DeviceType.mobile:
        return Breakpoints.mobileGutter;
    }
  }

  /// Get button height based on device type.
  static double getButtonHeight(BuildContext context) {
    return isDesktop(context)
        ? ComponentSizes.buttonHeightDesktop
        : ComponentSizes.buttonHeightMobile;
  }

  /// Get touch target size based on device type.
  static double getTouchTarget(BuildContext context) {
    return isDesktop(context)
        ? TouchTargets.desktopRecommended
        : TouchTargets.mobileRecommended;
  }
}

/// A widget that builds different layouts based on screen size.
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile layout (required)
  final Widget Function(BuildContext context) mobile;

  /// Builder for tablet layout (optional, defaults to mobile)
  final Widget Function(BuildContext context)? tablet;

  /// Builder for desktop layout (optional, defaults to tablet or mobile)
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return (desktop ?? tablet ?? mobile)(context);
      case DeviceType.tablet:
        return (tablet ?? mobile)(context);
      case DeviceType.mobile:
        return mobile(context);
    }
  }
}

/// A widget that provides different values based on screen size.
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({required this.mobile, this.tablet, this.desktop});

  T get(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Extension on BuildContext for easy responsive access
extension ResponsiveContext on BuildContext {
  /// Check if the device is mobile
  bool get isMobile => Responsive.isMobile(this);

  /// Check if the device is tablet
  bool get isTablet => Responsive.isTablet(this);

  /// Check if the device is desktop
  bool get isDesktop => Responsive.isDesktop(this);

  /// Get the device type
  DeviceType get deviceType => Responsive.getDeviceType(this);

  /// Get page margin for current device
  double get pageMargin => Responsive.getPageMargin(this);

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
}
