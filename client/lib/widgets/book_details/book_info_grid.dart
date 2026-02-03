import 'package:flutter/material.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Information grid for book metadata.
/// Displays key-value pairs like Publisher, ISBN, Format, etc.
class BookInfoGrid extends StatelessWidget {
  final BookData book;
  final bool isEinkMode;

  const BookInfoGrid({super.key, required this.book, this.isEinkMode = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = _buildEntries();

    if (isEinkMode) {
      return _buildEinkGrid(context, entries);
    }
    return _buildStandardGrid(context, colorScheme, entries);
  }

  Widget _buildStandardGrid(
    BuildContext context,
    ColorScheme colorScheme,
    List<_InfoEntry> entries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEinkGrid(BuildContext context, List<_InfoEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Column(
        children: entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final isLast = index == entries.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.label.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_InfoEntry> _buildEntries() {
    final entries = <_InfoEntry>[];

    // Format
    entries.add(_InfoEntry('Format', book.formatLabel));

    // Pages
    if (book.totalPages != null) {
      entries.add(_InfoEntry('Pages', '${book.totalPages}'));
    }

    // These would come from extended BookData in the future
    // For now, use placeholder data based on sample books
    final sampleInfo = _getSampleInfoForBook(book.id);
    entries.addAll(sampleInfo);

    return entries;
  }

  List<_InfoEntry> _getSampleInfoForBook(String bookId) {
    // Sample metadata for demo purposes
    switch (bookId) {
      case '1':
        return [
          const _InfoEntry('Publisher', 'Addison-Wesley'),
          const _InfoEntry('Published', 'October 30, 2019'),
          const _InfoEntry('ISBN', '978-0135957059'),
          const _InfoEntry('Language', 'English'),
        ];
      case '2':
        return [
          const _InfoEntry('Publisher', 'Pearson'),
          const _InfoEntry('Published', 'August 1, 2008'),
          const _InfoEntry('ISBN', '978-0132350884'),
          const _InfoEntry('Language', 'English'),
        ];
      case '3':
        return [
          const _InfoEntry('Publisher', 'Addison-Wesley'),
          const _InfoEntry('Published', 'October 31, 1994'),
          const _InfoEntry('ISBN', '978-0201633610'),
          const _InfoEntry('Language', 'English'),
        ];
      default:
        return [
          const _InfoEntry('Publisher', 'Unknown'),
          const _InfoEntry('Language', 'English'),
        ];
    }
  }
}

class _InfoEntry {
  final String label;
  final String value;

  const _InfoEntry(this.label, this.value);
}
