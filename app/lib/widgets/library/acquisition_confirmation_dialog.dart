import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';

Future<bool> showAcquisitionConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
}) async {
  return await showDialog<bool>(
        animationStyle: AppMotion.animationStyle(context),
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;
}
