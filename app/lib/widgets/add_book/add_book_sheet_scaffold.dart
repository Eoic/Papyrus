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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 280;
        final verticalPadding = isCompactHeight ? 0.0 : Spacing.md;
        final handleSpacing = isCompactHeight ? 0.0 : Spacing.lg;

        return Column(
          children: [
            Container(
              key: const Key('add-book-sheet-header'),
              padding: EdgeInsets.fromLTRB(Spacing.lg, verticalPadding, Spacing.lg, verticalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BottomSheetHandle(),
                  SizedBox(height: handleSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: isCompactHeight ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textScaler: isCompactHeight ? TextScaler.noScaling : null,
                        ),
                      ),
                      IconButton(
                        constraints: isCompactHeight ? const BoxConstraints.tightFor(width: 44, height: 44) : null,
                        icon: const Icon(Icons.close),
                        padding: isCompactHeight ? EdgeInsets.zero : null,
                        tooltip: 'Close',
                        onPressed: canClose ? onClose : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: body),
            Container(
              key: const Key('add-book-sheet-footer'),
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: verticalPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: SafeArea(top: false, child: footer),
            ),
          ],
        );
      },
    );
  }
}
