import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/book_progress_bar.dart';

/// Card displaying the currently reading book with progress and continue button.
class ContinueReadingCard extends StatelessWidget {
  /// The book currently being read.
  final BookData? book;

  /// Called when continue reading is pressed.
  final VoidCallback? onContinue;

  /// Whether to use desktop styling (larger cover, different layout).
  final bool isDesktop;

  /// Whether to use e-ink styling.
  final bool isEinkMode;

  const ContinueReadingCard({
    super.key,
    this.book,
    this.onContinue,
    this.isDesktop = false,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return isEinkMode
          ? _buildEinkEmptyState(context)
          : _buildEmptyState(context);
    }

    if (isEinkMode) return _buildEinkCard(context);
    if (isDesktop) return _buildDesktopCard(context);
    return _buildMobileCard(context);
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Row(
        children: [
          // Cover
          _buildCover(context, width: 80, height: 120),
          const SizedBox(width: Spacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book!.title,
                  style: textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  book!.author,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.sm),
                BookProgressBar(
                  progress: book!.progress,
                  currentPage: book!.currentPage,
                  totalPages: book!.totalPages,
                  showLabel: true,
                  height: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // Play button
          _buildPlayButton(context),
        ],
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Row(
        children: [
          // Cover
          _buildCover(context, width: 120, height: 180),
          const SizedBox(width: Spacing.lg),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  book!.title,
                  style: textTheme.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  book!.author,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.md),
                BookProgressBar(
                  progress: book!.progress,
                  currentPage: book!.currentPage,
                  totalPages: book!.totalPages,
                  showLabel: true,
                  height: 4,
                ),
                const SizedBox(height: Spacing.md),
                FilledButton.icon(
                  onPressed: onContinue ?? () => _navigateToBook(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                _buildEinkCover(context),
                const SizedBox(width: Spacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book!.title.toUpperCase(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        book!.author,
                        style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacing.sm),
                      BookProgressBar(
                        progress: book!.progress,
                        currentPage: book!.currentPage,
                        totalPages: book!.totalPages,
                        showLabel: true,
                        isEinkMode: true,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Continue button
          GestureDetector(
            onTap: onContinue ?? () => _navigateToBook(context),
            child: Container(
              width: double.infinity,
              height: TouchTargets.einkRecommended,
              color: Colors.black,
              child: Center(
                child: Text(
                  'CONTINUE READING',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // EMPTY STATES
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: BorderWidths.thin,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No book in progress',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Start reading from your library',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.md),
          TextButton(
            onPressed: () => context.go('/library'),
            child: const Text('Browse library'),
          ),
        ],
      ),
    );
  }

  Widget _buildEinkEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                const Icon(Icons.menu_book_outlined, size: 48),
                const SizedBox(height: Spacing.md),
                Text(
                  "YOU'RE NOT READING ANYTHING",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/library'),
            child: Container(
              width: double.infinity,
              height: TouchTargets.einkRecommended,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.black,
                    width: BorderWidths.einkDefault,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'GO TO LIBRARY',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildCover(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: book?.coverURL != null && book!.coverURL!.isNotEmpty
          ? Image.network(
              book!.coverURL!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildCoverPlaceholder(context),
            )
          : _buildCoverPlaceholder(context),
    );
  }

  Widget _buildEinkCover(BuildContext context) {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: book?.coverURL != null && book!.coverURL!.isNotEmpty
          ? Image.network(
              book!.coverURL!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildCoverPlaceholder(context),
            )
          : _buildCoverPlaceholder(context),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Icon(
        Icons.menu_book,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 48,
      height: 48,
      child: FilledButton(
        onPressed: onContinue ?? () => _navigateToBook(context),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        child: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
      ),
    );
  }

  void _navigateToBook(BuildContext context) {
    if (book != null) {
      context.push('/library/details/${book!.id}');
    }
  }
}
