import 'dart:async';

import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';

/// Keeps editors open until their local write succeeds.
mixin PersistentSave<T extends StatefulWidget> on State<T> {
  bool isSaving = false;

  Future<bool> persist(FutureOr<void> Function() save) async {
    if (isSaving) return false;
    setState(() => isSaving = true);
    try {
      await save();
      return mounted;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snackBarAnimationStyle: AppMotion.animationStyle(context),
          const SnackBar(content: Text('Could not save changes. Please try again.')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
