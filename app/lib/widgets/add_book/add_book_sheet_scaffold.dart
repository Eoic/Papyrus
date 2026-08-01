import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// Lays out an add-book sheet with fixed header and footer regions.
class AddBookSheetScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget body;
  final Widget footer;
  final bool canClose;

  const AddBookSheetScaffold({
    super.key,
    required this.title,
    required this.onClose,
    required this.body,
    required this.footer,
    this.canClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          key: const Key('add-book-sheet-header'),
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), tooltip: 'Close', onPressed: canClose ? onClose : null),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
        Container(
          key: const Key('add-book-sheet-footer'),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: SafeArea(top: false, child: footer),
        ),
      ],
    );
  }
}
