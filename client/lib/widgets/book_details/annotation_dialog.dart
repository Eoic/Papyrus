import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

/// Bottom sheet for creating or editing an annotation manually.
class AnnotationDialog extends StatefulWidget {
  final String bookId;
  final Annotation? existingAnnotation;

  const AnnotationDialog({
    super.key,
    required this.bookId,
    this.existingAnnotation,
  });

  /// Shows the dialog and returns the created/updated annotation, or null if cancelled.
  static Future<Annotation?> show(
    BuildContext context, {
    required String bookId,
    Annotation? existingAnnotation,
  }) {
    return showModalBottomSheet<Annotation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AnnotationDialog(
        bookId: bookId,
        existingAnnotation: existingAnnotation,
      ),
    );
  }

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _pageController;
  late final TextEditingController _chapterController;
  late final TextEditingController _noteController;
  late HighlightColor _selectedColor;

  bool get _isEditing => widget.existingAnnotation != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.existingAnnotation?.selectedText ?? '',
    );
    _pageController = TextEditingController(
      text: widget.existingAnnotation?.location.pageNumber.toString() ?? '',
    );
    _chapterController = TextEditingController(
      text: widget.existingAnnotation?.location.chapterTitle ?? '',
    );
    _noteController = TextEditingController(
      text: widget.existingAnnotation?.note ?? '',
    );
    _selectedColor = widget.existingAnnotation?.color ?? HighlightColor.yellow;
  }

  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    _chapterController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final page = int.parse(_pageController.text);
    final chapter = _chapterController.text.trim();
    final note = _noteController.text.trim();

    final annotation = Annotation(
      id:
          widget.existingAnnotation?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      selectedText: _textController.text.trim(),
      color: _selectedColor,
      location: BookLocation(
        pageNumber: page,
        chapterTitle: chapter.isNotEmpty ? chapter : null,
      ),
      note: note.isNotEmpty ? note : null,
      createdAt: widget.existingAnnotation?.createdAt ?? DateTime.now(),
      updatedAt: _isEditing ? DateTime.now() : null,
    );
    Navigator.of(context).pop(annotation);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.md,
                    Spacing.md,
                    0,
                  ),
                  child: Column(
                    children: [
                      const BottomSheetHandle(),
                      const SizedBox(height: Spacing.md),
                      BottomSheetHeader(
                        title: _isEditing
                            ? 'Edit annotation'
                            : 'New annotation',
                        onCancel: () => Navigator.of(context).pop(),
                        onSave: _save,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                const Divider(height: 1),

                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(Spacing.md),
                      children: [
                        // Highlighted text
                        TextFormField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            labelText: 'Highlighted text',
                            hintText: 'Enter the passage you highlighted...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          autofocus: !_isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the highlighted text';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.md),

                        // Page number
                        TextFormField(
                          controller: _pageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Page number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a page number';
                            }
                            final page = int.tryParse(value);
                            if (page == null || page < 1) {
                              return 'Enter a valid page number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.md),

                        // Chapter title (optional)
                        TextFormField(
                          controller: _chapterController,
                          decoration: const InputDecoration(
                            labelText: 'Chapter title (optional)',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: Spacing.md),

                        // Highlight color
                        Text(
                          'Highlight color',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Wrap(
                          spacing: Spacing.sm,
                          children: HighlightColor.values.map((color) {
                            final isSelected = color == _selectedColor;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: color.accentColor,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: color.accentColor,
                                        size: IconSizes.small,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: Spacing.md),

                        // Note (optional)
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                            hintText: 'Add your thoughts about this passage...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
