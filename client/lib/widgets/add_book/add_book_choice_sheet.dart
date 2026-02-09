import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/add_physical_book_sheet.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// Choice sheet for selecting how to add a book: digital import or physical.
class AddBookChoiceSheet extends StatelessWidget {
  const AddBookChoiceSheet({required this.callerContext, super.key});

  /// The context of the page that opened this sheet.
  ///
  /// Used to show follow-up sheets after this one is dismissed, since the
  /// dialog/bottom-sheet's own context becomes invalid after popping.
  final BuildContext callerContext;

  /// Show the choice sheet (bottom sheet on mobile, dialog on desktop).
  static Future<void> show(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: AddBookChoiceSheet(callerContext: context),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.md,
          bottom: Spacing.lg,
        ),
        child: AddBookChoiceSheet(callerContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDesktop =
        MediaQuery.of(context).size.width >= Breakpoints.desktopSmall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop) ...[
          const BottomSheetHandle(),
          const SizedBox(height: Spacing.lg),
        ],
        Text('Add book', style: textTheme.headlineSmall),
        const SizedBox(height: Spacing.lg),
        _ChoiceOption(
          icon: Icons.upload_file,
          title: 'Import digital books',
          subtitle: 'EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ',
          onTap: () {},
        ),
        const SizedBox(height: Spacing.sm),
        _ChoiceOption(
          icon: Icons.menu_book,
          title: 'Add physical book',
          subtitle: 'Enter details manually',
          onTap: () {
            Navigator.of(context).pop();
            AddPhysicalBookSheet.show(callerContext);
          },
        ),
      ],
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
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
