import 'package:flutter/material.dart';

/// Motion policy carried by the theme, independent of responsive layout.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  final bool reduceAnimations;

  const AppMotion({this.reduceAnimations = false});

  static bool disabled(BuildContext context) =>
      (Theme.of(context).extension<AppMotion>()?.reduceAnimations ?? false) || MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration normalDuration) =>
      disabled(context) ? Duration.zero : normalDuration;

  static AnimationStyle? animationStyle(BuildContext context) => disabled(context) ? AnimationStyle.noAnimation : null;

  @override
  AppMotion copyWith({bool? reduceAnimations}) =>
      AppMotion(reduceAnimations: reduceAnimations ?? this.reduceAnimations);

  @override
  AppMotion lerp(covariant AppMotion? other, double t) =>
      AppMotion(reduceAnimations: reduceAnimations || (other?.reduceAnimations ?? false));
}

class AppMotionScope extends StatelessWidget {
  final bool reduceAnimations;
  final Widget child;

  const AppMotionScope({super.key, required this.reduceAnimations, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final disabled = reduceAnimations || AppMotion.disabled(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: disabled),
      child: HeroMode(enabled: !disabled, child: child),
    );
  }
}

class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
