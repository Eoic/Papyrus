import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/settings/settings_section.dart';

class AcquisitionSettingsSection extends StatelessWidget {
  const AcquisitionSettingsSection({
    super.key,
    required this.title,
    this.emptyMessage,
    this.onAdd,
    this.children = const [],
  });

  final String title;
  final String? emptyMessage;
  final VoidCallback? onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            if (onAdd != null)
              Semantics(
                label: 'Add to $title',
                button: true,
                onTap: onAdd,
                child: ExcludeSemantics(
                  child: TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: IconSizes.small),
                    label: const Text('Add'),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        if (children.isNotEmpty)
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: Spacing.sm),
            children[index],
          ]
        else if (emptyMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text(emptyMessage!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}
