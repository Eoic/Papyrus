import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

/// Bottom sheet for changing reading status of multiple books.
class BulkStatusSheet extends StatelessWidget {
  final int bookCount;
  final void Function(ReadingStatus status) onStatusSelected;

  const BulkStatusSheet({
    super.key,
    required this.bookCount,
    required this.onStatusSelected,
  });

  /// Show as a bottom sheet on mobile.
  static Future<void> show(
    BuildContext context, {
    required int bookCount,
    required void Function(ReadingStatus status) onStatusSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => BulkStatusSheet(
        bookCount: bookCount,
        onStatusSelected: onStatusSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.lg),
            Text(
              'Change status for $bookCount ${bookCount == 1 ? 'book' : 'books'}',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.md),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('Mark as reading'),
              onTap: () {
                Navigator.pop(context);
                onStatusSelected(ReadingStatus.inProgress);
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Mark as finished'),
              onTap: () {
                Navigator.pop(context);
                onStatusSelected(ReadingStatus.completed);
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.bookmark_outline,
                color: colorScheme.onSurfaceVariant,
              ),
              title: const Text('Mark as unread'),
              onTap: () {
                Navigator.pop(context);
                onStatusSelected(ReadingStatus.notStarted);
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}
