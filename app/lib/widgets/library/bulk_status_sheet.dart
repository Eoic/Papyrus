import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/text_utils.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';

final statusTiles = [
  (
    icon: Icons.auto_stories,
    status: ReadingStatus.inProgress,
    title: "in progress",
  ),
  (
    icon: Icons.check_circle_outline,
    status: ReadingStatus.completed,
    title: "finished",
  ),
  (
    icon: Icons.bookmark_add_outlined,
    status: ReadingStatus.notStarted,
    title: "unread",
  ),
];

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              0,
            ),
            child: Text(
              'Change status for $bookCount ${maybePluralize(bookCount, "book")}',
              style: textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.md,
            ),
            child: Column(
              children: [
                for (final tile in statusTiles)
                  ListTile(
                    leading: Icon(tile.icon),
                    title: Text('Mark as ${tile.title}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onStatusSelected(tile.status);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
