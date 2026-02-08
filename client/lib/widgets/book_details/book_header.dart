import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/book_action_buttons.dart';
import 'package:papyrus/widgets/book_details/book_cover_image.dart';
import 'package:papyrus/widgets/book_details/book_progress_bar.dart';

/// Header section for book details page.
/// Contains cover image, title, author, metadata, progress bar, and action buttons.
class BookHeader extends StatelessWidget {
  final BookData book;
  final bool isDesktop;
  final VoidCallback? onContinueReading;
  final VoidCallback? onUpdateProgress;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onEdit;

  const BookHeader({
    super.key,
    required this.book,
    this.isDesktop = false,
    this.onContinueReading,
    this.onUpdateProgress,
    this.onToggleFavorite,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return _buildDesktopHeader(context);
    }
    return _buildMobileHeader(context);
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image
        BookCoverImage(
          imageUrl: book.coverURL,
          bookTitle: book.title,
          size: BookCoverSize.large,
        ),
        const SizedBox(width: Spacing.xl),

        // Book info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                book.title,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (book.subtitle != null && book.subtitle!.isNotEmpty) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  book.subtitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.sm),

              // Author
              Text(
                book.allAuthors,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: Spacing.md),

              // Meta row: rating, format, topics
              _buildMetaRow(context, colorScheme),
              const SizedBox(height: Spacing.lg),

              // Progress bar
              if (book.progress > 0 || book.isPhysical) ...[
                BookProgressBar(
                  progress: book.progress,
                  currentPage: book.currentPage,
                  totalPages: book.totalPages,
                  onTap: book.isPhysical ? onUpdateProgress : null,
                ),
                const SizedBox(height: Spacing.lg),
              ],

              // Action buttons
              BookActionButtons(
                book: book,
                isDesktop: true,
                onContinueReading: onContinueReading,
                onUpdateProgress: onUpdateProgress,
                onToggleFavorite: onToggleFavorite,
                onEdit: onEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        children: [
          const SizedBox(height: Spacing.lg),

          // Cover image (centered)
          BookCoverImage(
            imageUrl: book.coverURL,
            bookTitle: book.title,
            size: BookCoverSize.medium,
          ),
          const SizedBox(height: Spacing.md),

          // Title (centered)
          Text(
            book.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (book.subtitle != null && book.subtitle!.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              book.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Spacing.sm),

          // Author (centered)
          Text(
            book.allAuthors,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.md),

          // Meta row: rating, format, pages
          _buildMobileMetaRow(context, colorScheme),
          const SizedBox(height: Spacing.md),

          // Progress bar
          if (book.progress > 0 || book.isPhysical) ...[
            BookProgressBar(
              progress: book.progress,
              currentPage: book.currentPage,
              totalPages: book.totalPages,
              height: 4,
              onTap: book.isPhysical ? onUpdateProgress : null,
            ),
            const SizedBox(height: Spacing.md),
          ],

          // Action buttons
          BookActionButtons(
            book: book,
            isDesktop: false,
            onContinueReading: onContinueReading,
            onUpdateProgress: onUpdateProgress,
            onToggleFavorite: onToggleFavorite,
            onEdit: onEdit,
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, ColorScheme colorScheme) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Format badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            book.formatLabel,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        // Topics (first 2)
        ...book.topics
            .take(2)
            .map(
              (topic) => Chip(
                label: Text(topic),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildMobileMetaRow(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(book.formatLabel, style: Theme.of(context).textTheme.bodyMedium),
        if (book.totalPages != null) ...[
          Text('  •  ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(
            '${book.totalPages} pages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
