import 'package:flutter/material.dart';
import 'package:papyrus/providers/enums/library_reading_status.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/utils/text_utils.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/themes/app_motion.dart';

final statusTiles = [
  (icon: Icons.auto_stories, status: LibraryReadingStatus.inProgress, title: "in progress"),
  (icon: Icons.check_circle_outline, status: LibraryReadingStatus.completed, title: "finished"),
  (icon: Icons.bookmark_add_outlined, status: LibraryReadingStatus.unread, title: "unread"),
];

/// Bottom sheet for changing reading status of multiple books.
class BulkStatusSheet extends StatelessWidget {
  final int bookCount;
  final void Function(LibraryReadingStatus status) onStatusSelected;

  const BulkStatusSheet({super.key, required this.bookCount, required this.onStatusSelected});

  /// Show as a bottom sheet on mobile.
  static Future<void> show(
    BuildContext context, {
    required int bookCount,
    required void Function(LibraryReadingStatus status) onStatusSelected,
  }) {
    return showModalBottomSheet(
      sheetAnimationStyle: AppMotion.animationStyle(context),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (context) => BulkStatusSheet(bookCount: bookCount, onStatusSelected: onStatusSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
            child: Text(
              'Change status for $bookCount ${maybePluralize(bookCount, "book")}',
              style: textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.md),
            child: Column(
              children: [
                for (final tile in statusTiles)
                  ListTile(
                    leading: Icon(tile.icon),
                    title: Text('Mark as ${tile.title}'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    onTap: () {
                      Navigator.pop(context);
                      onStatusSelected(tile.status);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
