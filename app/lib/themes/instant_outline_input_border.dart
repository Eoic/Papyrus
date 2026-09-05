import 'package:flutter/material.dart';

/// Keeps Flutter's outline geometry without interpolating between border states.
/// InputDecorator's private border controller otherwise animates focus changes
/// even when MediaQuery.disableAnimations is true.
class InstantOutlineInputBorder extends OutlineInputBorder {
  const InstantOutlineInputBorder({super.borderSide, super.borderRadius, super.gapPadding});

  @override
  InstantOutlineInputBorder copyWith({BorderSide? borderSide, BorderRadius? borderRadius, double? gapPadding}) =>
      InstantOutlineInputBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
        gapPadding: gapPadding ?? this.gapPadding,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => this;

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b ?? this;
}
