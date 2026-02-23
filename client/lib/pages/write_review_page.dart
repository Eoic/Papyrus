import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Page for writing a book review.
class WriteReviewPage extends StatelessWidget {
  final String? catalogBookId;
  final String? bookTitle;

  const WriteReviewPage({super.key, this.catalogBookId, this.bookTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle != null ? 'Review: $bookTitle' : 'Write review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your rating', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(
              'Rating selection will be implemented with the API.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text('Your review', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            const Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
