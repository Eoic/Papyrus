import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/add_physical_book_sheet.dart';
import 'package:papyrus/widgets/add_book/book_import_sheet.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// Choice sheet for selecting digital import, physical entry, or optional online search.
class AddBookChoiceSheet extends StatefulWidget {
  const AddBookChoiceSheet({required this.callerContext, this.onFindOnline, super.key});

  /// The context of the page that opened this sheet.
  final BuildContext callerContext;

  /// Enables the online search option when provided.
  final VoidCallback? onFindOnline;

  /// Show the choice sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onFindOnline,
    DigitalBookFilePicker? digitalFilePicker,
    BookImportProcessor? bookImportProcessor,
    ImportedBookFileDeleter? deleteImportedBookFile,
  }) async {
    Future<_AddBookChoice?>? sheetCompleted;
    final choice = await showModalBottomSheet<_AddBookChoice>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) {
        sheetCompleted = ModalRoute.of<_AddBookChoice>(sheetContext)?.completed;

        return Padding(
          padding: const EdgeInsets.only(left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.lg),
          child: AddBookChoiceSheet(callerContext: context, onFindOnline: onFindOnline),
        );
      },
    );

    await sheetCompleted;

    if (!context.mounted || choice == null) {
      return;
    }

    switch (choice) {
      case _AddBookChoice.importDigital:
        await BookImportSheet.show(
          context,
          pickFiles: digitalFilePicker,
          processor: bookImportProcessor,
          deleteBookFile: deleteImportedBookFile,
        );
      case _AddBookChoice.addPhysical:
        await AddPhysicalBookSheet.show(context);
      case _AddBookChoice.findOnline:
        onFindOnline?.call();
    }
  }

  @override
  State<AddBookChoiceSheet> createState() => _AddBookChoiceSheetState();
}

class _AddBookChoiceSheetState extends State<AddBookChoiceSheet> {
  bool _isSelecting = false;

  void _select(_AddBookChoice choice) {
    if (_isSelecting) {
      return;
    }

    _isSelecting = true;
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: Spacing.lg),
        Text('Add book', style: textTheme.headlineSmall),
        const SizedBox(height: Spacing.lg),
        _ChoiceOption(
          icon: Icons.upload_file,
          title: 'Import digital books',
          subtitle: 'EPUB, PDF, AZW3, MOBI, CBZ/CBR',
          onTap: () => _select(_AddBookChoice.importDigital),
        ),
        const SizedBox(height: Spacing.sm),
        _ChoiceOption(
          icon: Icons.menu_book,
          title: 'Add physical book',
          subtitle: 'Enter details manually',
          onTap: () => _select(_AddBookChoice.addPhysical),
        ),
        if (widget.onFindOnline != null) ...[
          const SizedBox(height: Spacing.sm),
          _ChoiceOption(
            icon: Icons.travel_explore_outlined,
            title: 'Find books online',
            subtitle: 'Search connected book sources',
            onTap: () => _select(_AddBookChoice.findOnline),
          ),
        ],
      ],
    );
  }
}

enum _AddBookChoice { importDigital, addPhysical, findOnline }

class _ChoiceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
