import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

/// Bottom sheet for creating or editing a bookmark manually.
class BookmarkDialog extends StatefulWidget {
  final String bookId;
  final int? pageCount;
  final Bookmark? existingBookmark;

  const BookmarkDialog({
    super.key,
    required this.bookId,
    this.pageCount,
    this.existingBookmark,
  });

  /// Shows the dialog and returns the created/updated bookmark, or null if cancelled.
  static Future<Bookmark?> show(
    BuildContext context, {
    required String bookId,
    int? pageCount,
    Bookmark? existingBookmark,
  }) {
    return showModalBottomSheet<Bookmark>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => BookmarkDialog(
        bookId: bookId,
        pageCount: pageCount,
        existingBookmark: existingBookmark,
      ),
    );
  }

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pageController;
  late final TextEditingController _chapterController;
  late final TextEditingController _noteController;
  late String _selectedColor;

  bool get _isEditing => widget.existingBookmark != null;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.existingBookmark?.pageNumber?.toString() ?? '',
    );
    _chapterController = TextEditingController(
      text: widget.existingBookmark?.chapterTitle ?? '',
    );
    _noteController = TextEditingController(
      text: widget.existingBookmark?.note ?? '',
    );
    _selectedColor =
        widget.existingBookmark?.colorHex ?? Bookmark.availableColors.first;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chapterController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final page = int.parse(_pageController.text);
    final position = widget.pageCount != null
        ? (page / widget.pageCount!).clamp(0.0, 1.0)
        : 0.0;
    final chapter = _chapterController.text.trim();
    final note = _noteController.text.trim();

    final bookmark = Bookmark(
      id:
          widget.existingBookmark?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      position: position,
      pageNumber: page,
      chapterTitle: chapter.isNotEmpty ? chapter : null,
      note: note.isNotEmpty ? note : null,
      colorHex: _selectedColor,
      createdAt: widget.existingBookmark?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(bookmark);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BottomSheetHandle(),
                const SizedBox(height: Spacing.md),
                BottomSheetHeader(
                  title: _isEditing ? 'Edit bookmark' : 'New bookmark',
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _save,
                ),
                const SizedBox(height: Spacing.lg),

                // Page number
                TextFormField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Page number',
                    border: const OutlineInputBorder(),
                    suffixText: widget.pageCount != null
                        ? 'of ${widget.pageCount}'
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a page number';
                    }
                    final page = int.tryParse(value);
                    if (page == null || page < 1) {
                      return 'Enter a valid page number';
                    }
                    if (widget.pageCount != null && page > widget.pageCount!) {
                      return 'Page exceeds total pages (${widget.pageCount})';
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

                // Note (optional)
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: Spacing.md),

                // Color picker
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  children: Bookmark.availableColors.map((hex) {
                    final isSelected = hex == _selectedColor;
                    final color = Color(
                      int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                    );
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: colorScheme.onSurface,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: colorScheme.surface,
                                size: IconSizes.small,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: Spacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
