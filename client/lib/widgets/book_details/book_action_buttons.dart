import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Action buttons for book details page.
/// Shows Continue Reading (or Update Progress for physical books), Favorite, and Edit buttons.
class BookActionButtons extends StatelessWidget {
  final BookData book;
  final VoidCallback? onContinueReading;
  final VoidCallback? onUpdateProgress;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onEdit;
  final bool isDesktop;

  const BookActionButtons({
    super.key,
    required this.book,
    this.onContinueReading,
    this.onUpdateProgress,
    this.onToggleFavorite,
    this.onEdit,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonHeight = isDesktop
        ? ComponentSizes.buttonHeightDesktop
        : ComponentSizes.buttonHeightMobile;

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
                    onPressed: onContinueReading,
                    icon: Icon(
                      book.progress > 0 ? Icons.play_arrow : Icons.menu_book,
                    ),
                    label: Text(
                      book.progress > 0 ? 'Continue' : 'Start reading',
                    ),
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
                      onPressed: onContinueReading,
                      icon: Icon(
                        book.progress > 0 ? Icons.play_arrow : Icons.menu_book,
                      ),
                      label: Text(book.progress > 0 ? 'Continue' : 'Read'),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Icon(Icons.edit_outlined, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
