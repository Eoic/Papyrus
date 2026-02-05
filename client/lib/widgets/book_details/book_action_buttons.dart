import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Action buttons for book details page.
/// Shows Continue Reading, Add to Shelf, and Edit buttons.
class BookActionButtons extends StatelessWidget {
  final BookData book;
  final VoidCallback? onContinueReading;
  final VoidCallback? onAddToShelf;
  final VoidCallback? onEdit;
  final bool isDesktop;

  const BookActionButtons({
    super.key,
    required this.book,
    this.onContinueReading,
    this.onAddToShelf,
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
        // Continue Reading button (primary)
        if (isDesktop)
          SizedBox(
            width: 160,
            height: buttonHeight,
            child: FilledButton.icon(
              onPressed: onContinueReading,
              icon: Icon(
                book.progress > 0 ? Icons.play_arrow : Icons.menu_book,
              ),
              label: Text(book.progress > 0 ? 'Continue' : 'Start Reading'),
            ),
          )
        else
          Expanded(
            flex: 2,
            child: SizedBox(
              height: buttonHeight,
              child: FilledButton.icon(
                onPressed: onContinueReading,
                icon: Icon(
                  book.progress > 0 ? Icons.play_arrow : Icons.menu_book,
                ),
                label: Text(book.progress > 0 ? 'Continue' : 'Read'),
              ),
            ),
          ),
        const SizedBox(width: Spacing.sm),

        // Add to Shelf button (outlined)
        SizedBox(
          width: buttonHeight,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: onAddToShelf,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Icon(Icons.library_add_outlined, color: colorScheme.primary),
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
