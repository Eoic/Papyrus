import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';

/// A loader whose indeterminate state stays static when motion is disabled.
class AppCircularProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final String? semanticsLabel;

  const AppCircularProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 4,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) => _MotionProgress(
    builder: (controller) => CircularProgressIndicator(
      value: value,
      color: color,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      semanticsLabel: semanticsLabel,
      controller: value == null ? controller : null,
    ),
  );
}

class AppLinearProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double? minHeight;
  final BorderRadiusGeometry? borderRadius;
  final String? semanticsLabel;

  const AppLinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.minHeight,
    this.borderRadius,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) => _MotionProgress(
    builder: (controller) => LinearProgressIndicator(
      value: value,
      color: color,
      backgroundColor: backgroundColor,
      minHeight: minHeight,
      borderRadius: borderRadius,
      semanticsLabel: semanticsLabel,
      controller: value == null ? controller : null,
    ),
  );
}

class _MotionProgress extends StatefulWidget {
  final Widget Function(AnimationController? controller) builder;
  const _MotionProgress({required this.builder});

  @override
  State<_MotionProgress> createState() => _MotionProgressState();
}

class _MotionProgressState extends State<_MotionProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _staticPhase;

  @override
  void initState() {
    super.initState();
    _staticPhase = AnimationController(vsync: this, value: 0.5);
  }

  @override
  void dispose() {
    _staticPhase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = AppMotion.disabled(context);
    return TickerMode(enabled: !disabled, child: widget.builder(disabled ? _staticPhase : null));
  }
}
