import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';

/// Opens the same drawer without a sliding transition on e-ink displays.
void openAppDrawer(BuildContext context, ScaffoldState? scaffold) {
  if (scaffold == null) return;
  if (!AppMotion.disabled(context)) {
    scaffold.openDrawer();
    return;
  }
  final drawer = scaffold.widget.drawer;
  if (drawer == null) return;
  showDialog<void>(
    context: context,
    useSafeArea: false,
    animationStyle: AnimationStyle.noAnimation,
    builder: (_) => Align(alignment: AlignmentDirectional.centerStart, child: drawer),
  );
}
