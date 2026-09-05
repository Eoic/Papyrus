import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:papyrus/widgets/shared/persistent_save.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

/// Dialog for adding or editing a note.
class NoteDialog extends StatelessWidget {
  final String bookId;
  final Note? existingNote;
  final FutureOr<void> Function(Note)? onSave;

  const NoteDialog({super.key, required this.bookId, this.existingNote, this.onSave});

  bool get isEditing => existingNote != null;

  /// Shows the dialog and returns the created/updated note, or null if cancelled.
  static Future<Note?> show(
    BuildContext context, {
    required String bookId,
    Note? existingNote,
    FutureOr<void> Function(Note)? onSave,
  }) async {
    return showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => _BottomSheetNote(bookId: bookId, existingNote: existingNote, onSave: onSave),
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
  final FutureOr<void> Function(Note)? onSave;

  const _BottomSheetNote({required this.bookId, this.existingNote, this.onSave});

  @override
  State<_BottomSheetNote> createState() => _BottomSheetNoteState();
}

class _BottomSheetNoteState extends State<_BottomSheetNote> with PersistentSave<_BottomSheetNote> {
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
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
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

  Future<void> _save() async {
    if (isSaving) return;
    if (_formKey.currentState?.validate() ?? false) {
      final note = Note(
        id: widget.existingNote?.id ?? const Uuid().v4(),
        bookId: widget.bookId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        location: widget.existingNote?.location,
        tags: _tags,
        isPinned: widget.existingNote?.isPinned ?? false,
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
      );
      final saved = await persist(() => widget.onSave?.call(note));
      if (saved && mounted) Navigator.of(context).pop(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Container(
          key: const Key('note-bottom-sheet'),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
                child: Column(
                  children: [
                    const BottomSheetHandle(),
                    const SizedBox(height: Spacing.md),
                    BottomSheetHeader(
                      title: isEditing ? 'Edit note' : 'New note',
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: _save,
                      canSave: !isSaving,
                      canCancel: !isSaving,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
              const Divider(height: 1),

              // Form
              Flexible(
                fit: FlexFit.loose,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    key: const Key('note-form-scroll'),
                    scrollBehavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    shrinkWrap: true,
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
                                textCapitalization: TextCapitalization.sentences,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.md),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                key: const Key('note-content-field'),
                                controller: _contentController,
                                decoration: const InputDecoration(
                                  labelText: 'Content',
                                  hintText: 'Write your note...',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                minLines: 8,
                                maxLines: 12,
                                textAlignVertical: TextAlignVertical.top,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter some content';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: Spacing.md),

                              // Tag input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _tagController,
                                      decoration: const InputDecoration(
                                        labelText: 'Tags',
                                        hintText: 'Add a tag...',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _addTag(),
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  IconButton.filled(onPressed: _addTag, icon: const Icon(Icons.add)),
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
                                      deleteIcon: const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeTag(tag),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                )
                              else
                                Text(
                                  'Tags will appear here',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
        ),
      ),
    );
  }
}
