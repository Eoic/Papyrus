import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/widgets/shared/static_date_picker.dart';

/// Uses instant calendar controls as well as an instant route when motion is disabled.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (!AppMotion.disabled(context)) {
    return showDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate);
  }
  return showDialog<DateTime>(
    context: context,
    animationStyle: AnimationStyle.noAnimation,
    builder: (context) => StaticDatePicker(initialDate: initialDate, firstDate: firstDate, lastDate: lastDate),
  );
}

Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
  bool useRootNavigator = true,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? saveText,
  TransitionBuilder? builder,
}) {
  if (!AppMotion.disabled(context)) {
    return showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
      useRootNavigator: useRootNavigator,
      initialEntryMode: initialEntryMode,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      saveText: saveText,
      builder: builder,
    );
  }
  return showDialog<DateTimeRange>(
    context: context,
    useRootNavigator: useRootNavigator,
    useSafeArea: false,
    animationStyle: AnimationStyle.noAnimation,
    builder: (context) {
      final dialog = StaticDatePicker(
        selectRange: true,
        initialRange: initialDateRange,
        firstDate: firstDate,
        lastDate: lastDate,
        initialEntryMode: initialEntryMode,
        helpText: helpText,
        cancelText: cancelText,
        confirmText: saveText ?? confirmText,
      );
      return builder == null ? dialog : builder(context, dialog);
    },
  );
}
