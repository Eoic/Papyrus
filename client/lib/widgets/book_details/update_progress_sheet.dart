import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

/// Bottom sheet for manually updating reading progress of a physical book.
class UpdateProgressSheet extends StatefulWidget {
  final Book book;
  final void Function(int page, double position) onSave;

  const UpdateProgressSheet({
    super.key,
    required this.book,
    required this.onSave,
  });

  /// Shows the bottom sheet and calls [onSave] when the user saves.
  static Future<void> show(
    BuildContext context, {
    required Book book,
    required void Function(int page, double position) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => UpdateProgressSheet(book: book, onSave: onSave),
    );
  }

  @override
  State<UpdateProgressSheet> createState() => _UpdateProgressSheetState();
}

class _UpdateProgressSheetState extends State<UpdateProgressSheet> {
  late final TextEditingController _pageController;
  double _sliderValue = 0.0;
  bool get _hasPageCount => widget.book.pageCount != null;

  @override
  void initState() {
    super.initState();
    final currentPage = widget.book.currentPage;
    _pageController = TextEditingController(
      text: currentPage != null && currentPage > 0 ? '$currentPage' : '',
    );
    _sliderValue = widget.book.currentPosition;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _calculatePosition() {
    if (_hasPageCount) {
      final page = int.tryParse(_pageController.text) ?? 0;
      if (page <= 0) return 0.0;
      return (page / widget.book.pageCount!).clamp(0.0, 1.0);
    }
    return _sliderValue;
  }

  int _calculatePage() {
    if (_hasPageCount) {
      return (int.tryParse(_pageController.text) ?? 0).clamp(
        0,
        widget.book.pageCount!,
      );
    }
    return (_sliderValue * (widget.book.pageCount ?? 100)).round();
  }

  void _save() {
    final position = _calculatePosition();
    final page = _hasPageCount ? _calculatePage() : 0;
    widget.onSave(page, position);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.md),
              BottomSheetHeader(
                title: 'Update progress',
                onCancel: () => Navigator.of(context).pop(),
                onSave: _save,
              ),
              const SizedBox(height: Spacing.md),
              const Divider(height: 1),
              const SizedBox(height: Spacing.md),

              if (_hasPageCount) _buildPageInput(context) else _buildSlider(),

              const SizedBox(height: Spacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Page input row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Page'),
            const SizedBox(width: Spacing.sm),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.sm,
                  ),
                ),
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text('of ${widget.book.pageCount} pages'),
          ],
        ),
        const SizedBox(height: Spacing.md),

        // Live percentage preview
        Text(
          '${(_calculatePosition() * 100).round()}% complete',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        Text(
          '${(_sliderValue * 100).round()}% complete',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.md),
        Slider(
          value: _sliderValue,
          onChanged: (value) => setState(() => _sliderValue = value),
        ),
      ],
    );
  }
}
