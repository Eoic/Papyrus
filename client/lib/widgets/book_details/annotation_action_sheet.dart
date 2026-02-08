import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Result of annotation action sheet selection.
enum AnnotationAction { editNote, delete }

/// Bottom sheet for annotation actions (edit note, delete).
class AnnotationActionSheet extends StatelessWidget {
  final Annotation annotation;

  const AnnotationActionSheet({super.key, required this.annotation});

  /// Shows the action sheet and returns the selected action.
  static Future<AnnotationAction?> show(
    BuildContext context, {
    required Annotation annotation,
  }) async {
    return showModalBottomSheet<AnnotationAction>(
      context: context,
      builder: (context) => AnnotationActionSheet(annotation: annotation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Annotation location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                annotation.location.shortLocation,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(),

            // Edit note action
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
              title: const Text('Edit note'),
              onTap: () => Navigator.of(context).pop(AnnotationAction.editNote),
            ),

            // Delete action
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Delete annotation',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () => Navigator.of(context).pop(AnnotationAction.delete),
            ),

            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }
}
