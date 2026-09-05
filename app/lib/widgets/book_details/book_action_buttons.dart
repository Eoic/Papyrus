import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';

enum BookReadingActionState { ready, download, checking, syncing, failed, downloading, unavailable }

/// Action buttons for book details page.
/// Shows Continue Reading (or Update Progress for physical books), Favorite, and Edit buttons.
class BookActionButtons extends StatelessWidget {
  final Book book;
  final VoidCallback? onContinueReading;
  final VoidCallback? onUpdateProgress;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onEdit;
  final bool isDesktop;
  final BookReadingActionState readingActionState;

  const BookActionButtons({
    super.key,
    required this.book,
    this.onContinueReading,
    this.onUpdateProgress,
    this.onToggleFavorite,
    this.onEdit,
    this.isDesktop = false,
    this.readingActionState = BookReadingActionState.ready,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonHeight = isDesktop ? ComponentSizes.buttonHeightDesktop : ComponentSizes.buttonHeightMobile;
    final normalReadingLabel = book.progress > 0
        ? 'Continue'
        : isDesktop
        ? 'Start reading'
        : 'Read';
    final digitalLabel = switch (readingActionState) {
      BookReadingActionState.ready || BookReadingActionState.download => normalReadingLabel,
      BookReadingActionState.checking => 'Checking file…',
      BookReadingActionState.syncing => 'Syncing book…',
      BookReadingActionState.failed => 'Sync failed',
      BookReadingActionState.downloading => 'Downloading…',
      BookReadingActionState.unavailable => 'File unavailable',
    };
    final canUseDigitalAction =
        readingActionState == BookReadingActionState.ready || readingActionState == BookReadingActionState.download;
    final digitalIcon = switch (readingActionState) {
      BookReadingActionState.ready => Icon(book.progress > 0 ? Icons.play_arrow : Icons.menu_book),
      BookReadingActionState.download => const Icon(Icons.download_outlined),
      BookReadingActionState.downloading => const SizedBox.square(
        dimension: 18,
        child: AppCircularProgressIndicator(strokeWidth: 2),
      ),
      BookReadingActionState.checking => const Icon(Icons.hourglass_empty),
      BookReadingActionState.syncing => const Icon(Icons.cloud_sync_outlined),
      BookReadingActionState.failed => const Icon(Icons.cloud_off_outlined),
      BookReadingActionState.unavailable => const Icon(Icons.file_download_off_outlined),
    };

    return Row(
      mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Primary action button
        if (isDesktop)
          SizedBox(
            width: 180,
            height: buttonHeight,
            child: book.isPhysical
                ? FilledButton.icon(
                    onPressed: onUpdateProgress,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Update progress'),
                  )
                : FilledButton.icon(
                    onPressed: canUseDigitalAction ? onContinueReading : null,
                    icon: digitalIcon,
                    label: Text(digitalLabel),
                  ),
          )
        else
          Expanded(
            flex: 2,
            child: SizedBox(
              height: buttonHeight,
              child: book.isPhysical
                  ? FilledButton.icon(
                      onPressed: onUpdateProgress,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Update progress'),
                    )
                  : FilledButton.icon(
                      onPressed: canUseDigitalAction ? onContinueReading : null,
                      icon: digitalIcon,
                      label: Text(digitalLabel),
                    ),
            ),
          ),
        const SizedBox(width: Spacing.sm),

        // Favorite toggle button
        SizedBox(
          width: buttonHeight,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: onToggleFavorite,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: Icon(
              book.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: book.isFavorite ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),

        // Edit button (icon only)
        SizedBox(
          width: buttonHeight,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: Icon(Icons.edit_outlined, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
