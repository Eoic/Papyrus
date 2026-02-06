import 'package:flutter/material.dart';
import 'package:papyrus/models/tag.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Bottom sheet for creating or editing a topic.
class AddTopicSheet extends StatefulWidget {
  /// The topic to edit, or null to create a new topic.
  final Tag? topic;

  /// Called when the topic is saved.
  final void Function(String name, String? description, String colorHex)?
  onSave;

  const AddTopicSheet({super.key, this.topic, this.onSave});

  /// Shows the add/edit topic sheet.
  static Future<void> show(
    BuildContext context, {
    Tag? topic,
    void Function(String name, String? description, String colorHex)? onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => AddTopicSheet(topic: topic, onSave: onSave),
    );
  }

  @override
  State<AddTopicSheet> createState() => _AddTopicSheetState();
}

class _AddTopicSheetState extends State<AddTopicSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedColorHex;

  bool get _isEditing => widget.topic != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.topic?.description ?? '',
    );
    _selectedColorHex =
        widget.topic?.colorHex ?? Tag.availableColors[5]; // Blue default
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Title
            Text(
              _isEditing ? 'Edit topic' : 'Create new topic',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.lg),

            // Name field
            Text(
              'Name',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter topic name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Description field
            Text(
              'Description (optional)',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Add a description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.all(Spacing.md),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Color picker
            Text(
              'Color',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            _buildColorPicker(context),
            const SizedBox(height: Spacing.xl),

            // Preview
            _buildPreview(context),
            const SizedBox(height: Spacing.lg),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _onSave : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Text(_isEditing ? 'Save changes' : 'Create topic'),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Widget _buildColorPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: Tag.availableColors.map((colorHex) {
        final color = _parseColor(colorHex);
        final isSelected = _selectedColorHex == colorHex;

        return GestureDetector(
          onTap: () => setState(() => _selectedColorHex = colorHex),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, size: 18, color: _getContrastColor(color))
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topicColor = _parseColor(_selectedColorHex);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: topicColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : 'Topic name',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _nameController.text.isEmpty
                        ? colorScheme.onSurfaceVariant
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _descriptionController.text,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Preview label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'Preview',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.onSave?.call(
      name,
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      _selectedColorHex,
    );
    Navigator.of(context).pop();
  }

  Color _parseColor(String hex) {
    try {
      final hexValue = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
