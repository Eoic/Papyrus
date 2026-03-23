import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Cover image size variants.
enum BookCoverSize {
  /// Desktop book details: 240x360
  large,

  /// Mobile book details: 180x270
  medium,

  /// Grid thumbnail: 120x180
  gridThumbnail,

  /// List thumbnail: 60x90
  listThumbnail,
}

/// Book cover image widget with size variants and placeholder.
class BookCoverImage extends StatelessWidget {
  final String? imageUrl;
  final String? bookTitle;
  final BookCoverSize size;

  const BookCoverImage({
    super.key,
    this.imageUrl,
    this.bookTitle,
    this.size = BookCoverSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: _buildImage(context, colorScheme),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme colorScheme) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _buildPlaceholder(context, colorScheme),
        progressIndicatorBuilder: (context, url, progress) =>
            _buildLoadingIndicator(context, colorScheme, progress),
      );
    }
    return _buildPlaceholder(context, colorScheme);
  }

  Widget _buildPlaceholder(BuildContext context, ColorScheme colorScheme) {
    final dimensions = _getDimensions();
    final iconSize = dimensions.width * 0.3;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: iconSize.clamp(24.0, 64.0),
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          if (bookTitle != null && size != BookCoverSize.listThumbnail) ...[
            const SizedBox(height: Spacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text(
                bookTitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(
    BuildContext context,
    ColorScheme colorScheme,
    DownloadProgress progress,
  ) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          value: progress.progress,
          strokeWidth: 2,
        ),
      ),
    );
  }

  _CoverDimensions _getDimensions() {
    switch (size) {
      case BookCoverSize.large:
        return const _CoverDimensions(240, 360);
      case BookCoverSize.medium:
        return const _CoverDimensions(180, 270);
      case BookCoverSize.gridThumbnail:
        return const _CoverDimensions(120, 180);
      case BookCoverSize.listThumbnail:
        return const _CoverDimensions(60, 90);
    }
  }
}

class _CoverDimensions {
  final double width;
  final double height;

  const _CoverDimensions(this.width, this.height);
}
