import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Community book detail page showing ratings and reviews.
class CommunityBookPage extends StatelessWidget {
  final String? catalogBookId;

  const CommunityBookPage({super.key, this.catalogBookId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Book details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.md),
              Text(
                'Community book details',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Ratings, reviews, and book info will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
