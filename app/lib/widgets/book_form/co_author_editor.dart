import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Editable co-author chips with add dialog. Used in book forms.
class CoAuthorEditor extends StatelessWidget {
  final List<String> coAuthors;
  final void Function(List<String>) onChanged;

  const CoAuthorEditor({
    super.key,
    required this.coAuthors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Co-authors',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.xs),
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: [
            ...coAuthors.map(
              (author) => Chip(
                label: Text(author),
                onDeleted: () {
                  final updated = List<String>.from(coAuthors)..remove(author);
                  onChanged(updated);
                },
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () => _showAddDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add co-author'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter co-author name',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(ctx, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name is String && name.isNotEmpty) {
        final updated = List<String>.from(coAuthors)..add(name);
        onChanged(updated);
      }
    });
  }
}
