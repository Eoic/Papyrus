import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<T?> showGuardedModalBottomSheet<T>({
  required BuildContext context,
  required ValueListenable<bool> busy,
  required WidgetBuilder builder,
  required ShapeBorder shape,
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);

  return navigator.push(
    _GuardedModalBottomSheetRoute<T>(
      busy: busy,
      builder: builder,
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      shape: shape,
    ),
  );
}

class _GuardedModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _GuardedModalBottomSheetRoute({
    required ValueListenable<bool> busy,
    required super.builder,
    required super.capturedThemes,
    required super.barrierLabel,
    required super.barrierOnTapHint,
    required super.modalBarrierColor,
    required super.shape,
  }) : _busy = busy,
       super(
         isScrollControlled: true,
         isDismissible: true,
         enableDrag: true,
         showDragHandle: true,
         useSafeArea: true,
         clipBehavior: Clip.antiAlias,
       );

  final ValueListenable<bool> _busy;

  @override
  bool get isDismissible => !_busy.value;

  @override
  bool get enableDrag => !_busy.value;

  @override
  bool get showDragHandle => !_busy.value;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return ValueListenableBuilder<bool>(
      valueListenable: _busy,
      builder: (_, _, _) {
        return super.buildPage(context, animation, secondaryAnimation);
      },
    );
  }

  @override
  void install() {
    super.install();
    _busy.addListener(_handleBusyChanged);
  }

  @override
  void dispose() {
    _busy.removeListener(_handleBusyChanged);
    super.dispose();
  }

  void _handleBusyChanged() {
    changedInternalState();
  }
}
