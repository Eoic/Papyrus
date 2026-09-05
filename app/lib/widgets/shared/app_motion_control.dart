import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';

/// Recreates only the built-in toggle's animation state when motion is disabled.
/// The focus node belongs to this wrapper so keyboard interaction can continue.
/// Pass a constant value for chips: their native duration overrides handle value
/// changes, while this wrapper refreshes those overrides when the theme changes.
class AppMotionControl extends StatefulWidget {
  final Object? value;
  final bool enabled;
  final FocusNode? focusNode;
  final Widget Function(FocusNode focusNode) builder;

  const AppMotionControl({super.key, required this.value, this.enabled = true, this.focusNode, required this.builder});

  @override
  State<AppMotionControl> createState() => _AppMotionControlState();
}

class _AppMotionControlState extends State<AppMotionControl> {
  final FocusNode _ownedFocusNode = FocusNode(debugLabel: 'AppMotionControl');
  Key? _previousKey;

  @override
  Widget build(BuildContext context) {
    final disabled = AppMotion.disabled(context);
    final focusNode = widget.focusNode ?? _ownedFocusNode;
    final key = ValueKey((disabled, disabled ? widget.value : null, disabled ? widget.enabled : null));
    if (_previousKey != null && key != _previousKey && focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && focusNode.canRequestFocus) focusNode.requestFocus();
      });
    }
    _previousKey = key;
    final child = KeyedSubtree(key: key, child: widget.builder(focusNode));
    if (!disabled) return child;
    return TickerMode(
      enabled: false,
      child: ListenableBuilder(
        listenable: focusNode,
        child: child,
        builder: (context, child) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: focusNode.hasFocus ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2) : null,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ownedFocusNode.dispose();
    super.dispose();
  }
}

final _instantChipAnimationStyle = ChipAnimationStyle(
  enableAnimation: AnimationStyle.noAnimation,
  selectAnimation: AnimationStyle.noAnimation,
  avatarDrawerAnimation: AnimationStyle.noAnimation,
  deleteDrawerAnimation: AnimationStyle.noAnimation,
);

ChipAnimationStyle? appChipAnimationStyle(BuildContext context) =>
    AppMotion.disabled(context) ? _instantChipAnimationStyle : null;
