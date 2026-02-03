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
  final bool isEinkMode;
  final bool isDesktop;

  const BookActionButtons({
    super.key,
    required this.book,
    this.onContinueReading,
    this.onAddToShelf,
    this.onEdit,
    this.isEinkMode = false,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEinkMode) {
      return _buildEinkButtons(context);
    }
    return _buildStandardButtons(context);
  }

  Widget _buildStandardButtons(BuildContext context) {
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

  Widget _buildEinkButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary button - Continue Reading
        SizedBox(
          height: TouchTargets.einkRecommended,
          child: ElevatedButton(
            onPressed: onContinueReading,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            child: Text(
              book.progress > 0 ? 'CONTINUE READING' : 'START READING',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),

        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: TouchTargets.einkMin,
                child: OutlinedButton(
                  onPressed: onAddToShelf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'ADD TO SHELF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: SizedBox(
                height: TouchTargets.einkMin,
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'EDIT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
