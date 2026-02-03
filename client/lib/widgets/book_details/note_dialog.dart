import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// Dialog for adding or editing a note.
class NoteDialog extends StatelessWidget {
  final String bookId;
  final Note? existingNote;

  const NoteDialog({super.key, required this.bookId, this.existingNote});

  bool get isEditing => existingNote != null;

  /// Shows the dialog and returns the created/updated note, or null if cancelled.
  static Future<Note?> show(
    BuildContext context, {
    required String bookId,
    Note? existingNote,
  }) async {
    final displayMode = context.read<DisplayModeProvider>();

    if (displayMode.isEinkMode) {
      return showDialog<Note>(
        context: context,
        builder: (context) =>
            _EinkNoteDialog(bookId: bookId, existingNote: existingNote),
      );
    }

    return showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _BottomSheetNote(bookId: bookId, existingNote: existingNote),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Bottom sheet implementation for mobile/desktop.
class _BottomSheetNote extends StatefulWidget {
  final String bookId;
  final Note? existingNote;

  const _BottomSheetNote({required this.bookId, this.existingNote});

  @override
  State<_BottomSheetNote> createState() => _BottomSheetNoteState();
}

class _BottomSheetNoteState extends State<_BottomSheetNote> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  final _titleFocusNode = FocusNode();
  late List<String> _tags;

  bool get isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.existingNote?.tags ?? []);

    // Auto-focus title field when sheet opens (only for new notes)
    if (!isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final note = Note(
        id:
            widget.existingNote?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: widget.bookId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        location: widget.existingNote?.location,
        tags: _tags,
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
      );
      Navigator.of(context).pop(note);
    }
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
                // Handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    0,
                    Spacing.md,
                    Spacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      Text(
                        isEditing ? 'Edit Note' : 'New Note',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: _save, child: const Text('Save')),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Enter note title',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacing.md),

                          // Content field
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'Content',
                              hintText: 'Write your note...',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 8,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter some content';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacing.md),

                          // Tags section
                          Text(
                            'Tags',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: Spacing.sm),

                          // Tag input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a tag...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              IconButton.filled(
                                onPressed: _addTag,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),

                          // Tags display
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: Spacing.sm),
                            Wrap(
                              spacing: Spacing.xs,
                              runSpacing: Spacing.xs,
                              children: _tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeTag(tag),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
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

/// E-ink specific dialog implementation.
class _EinkNoteDialog extends StatefulWidget {
  final String bookId;
  final Note? existingNote;

  const _EinkNoteDialog({required this.bookId, this.existingNote});

  @override
  State<_EinkNoteDialog> createState() => _EinkNoteDialogState();
}

class _EinkNoteDialogState extends State<_EinkNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  late List<String> _tags;

  bool get isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.existingNote?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final note = Note(
        id:
            widget.existingNote?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: widget.bookId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        location: widget.existingNote?.location,
        tags: _tags,
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
      );
      Navigator.of(context).pop(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(Spacing.pageMarginsEink),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                isEditing ? 'EDIT NOTE' : 'ADD NOTE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Title field
              Text(
                'TITLE',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.xs),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter note title',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault * 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(Spacing.md),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              // Content field
              Text(
                'CONTENT',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.xs),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Write your note...',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault * 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(Spacing.md),
                  alignLabelWithHint: true,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              // Tags section
              Text(
                'TAGS',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.xs),

              // Tag input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add a tag...',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: BorderWidths.einkDefault,
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: BorderWidths.einkDefault,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: BorderWidths.einkDefault * 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(Spacing.sm),
                        isDense: true,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  SizedBox(
                    height: TouchTargets.einkMin,
                    child: OutlinedButton(
                      onPressed: _addTag,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                          color: Colors.black,
                          width: BorderWidths.einkDefault,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                        ),
                      ),
                      child: const Text(
                        'ADD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              // Tags display
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  _tags.map((t) => '[$t]').join('  '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: Spacing.xs),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: _tags.map((tag) {
                    return SizedBox(
                      height: TouchTargets.einkMin - 8,
                      child: OutlinedButton(
                        onPressed: () => _removeTag(tag),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.black,
                            width: BorderWidths.einkDefault,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag),
                            const SizedBox(width: Spacing.xs),
                            const Icon(Icons.close, size: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: Spacing.lg),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: TouchTargets.einkMin,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.black,
                            width: BorderWidths.einkDefault,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: SizedBox(
                      height: TouchTargets.einkMin,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
