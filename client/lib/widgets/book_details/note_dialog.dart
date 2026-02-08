import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

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

/// Bottom sheet implementation for adding/editing notes.
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
                        title: isEditing ? 'Edit note' : 'New note',
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
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(Spacing.md),
                          sliver: SliverToBoxAdapter(
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
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: Spacing.md),
                              ],
                            ),
                          ),
                        ),

                        // Content field — fills remaining space
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Spacing.md,
                              0,
                              Spacing.md,
                              Spacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _contentController,
                                    decoration: const InputDecoration(
                                      labelText: 'Content',
                                      hintText: 'Write your note...',
                                      border: OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter some content';
                                      }
                                      return null;
                                    },
                                  ),
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
                                const SizedBox(height: Spacing.sm),
                                if (_tags.isNotEmpty)
                                  Wrap(
                                    spacing: Spacing.xs,
                                    runSpacing: Spacing.xs,
                                    children: _tags.map((tag) {
                                      return Chip(
                                        label: Text(tag),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        onDeleted: () => _removeTag(tag),
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  )
                                else
                                  Text(
                                    'Tags will appear here',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
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
