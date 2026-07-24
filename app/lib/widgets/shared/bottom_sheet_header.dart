import 'package:flutter/material.dart';

/// A reusable header row for bottom sheets.
///
/// Renders Cancel (TextButton) on the left, [title] centered, and
/// Save (FilledButton) on the right.
class BottomSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool canSave;

  const BottomSheetHeader({
    super.key,
    required this.title,
    required this.onCancel,
    this.onSave,
    this.saveLabel = 'Save',
    this.canSave = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: onSave == null
                ? const SizedBox.shrink()
                : FilledButton(onPressed: canSave ? onSave : null, child: Text(saveLabel)),
          ),
        ),
      ],
    );
  }
}
