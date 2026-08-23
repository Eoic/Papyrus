import 'package:flutter/material.dart';
import 'package:papyrus/providers/book_storage_status_controller.dart';
import 'package:papyrus/themes/design_tokens.dart';

class BookAccountStatusBadge extends StatelessWidget {
  final BookAccountStatus status;

  const BookAccountStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, icon, foreground, background) = switch (status) {
      BookAccountStatus.saved => (
        'Saved',
        Icons.cloud_done_outlined,
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
      ),
      BookAccountStatus.syncing => (
        'Syncing…',
        Icons.cloud_sync_outlined,
        colorScheme.primary,
        colorScheme.primaryContainer,
      ),
      BookAccountStatus.failed => (
        'Sync failed',
        Icons.cloud_off_outlined,
        colorScheme.onErrorContainer,
        colorScheme.errorContainer,
      ),
    };

    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Icon(icon, size: 14, color: foreground),
        ),
      ),
    );
  }
}
