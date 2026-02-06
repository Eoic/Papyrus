import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Information grid for book metadata.
/// Displays key-value pairs like Publisher, ISBN, Format, etc.
class BookInfoGrid extends StatelessWidget {
  final BookData book;

  const BookInfoGrid({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = _buildEntries();

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

  List<_InfoEntry> _buildEntries() {
    final entries = <_InfoEntry>[];

    entries.add(_InfoEntry('Format', book.formatLabel));

    if (book.totalPages != null) {
      entries.add(_InfoEntry('Pages', '${book.totalPages}'));
    }

    if (book.publisher != null && book.publisher!.isNotEmpty) {
      entries.add(_InfoEntry('Publisher', book.publisher!));
    }

    if (book.publicationDate != null) {
      entries.add(
        _InfoEntry(
          'Published',
          DateFormat.yMMMMd().format(book.publicationDate!),
        ),
      );
    }

    if (book.isbn13 != null && book.isbn13!.isNotEmpty) {
      entries.add(_InfoEntry('ISBN-13', book.isbn13!));
    } else if (book.isbn != null && book.isbn!.isNotEmpty) {
      entries.add(_InfoEntry('ISBN', book.isbn!));
    }

    if (book.language != null && book.language!.isNotEmpty) {
      entries.add(_InfoEntry('Language', book.language!));
    }

    return entries;
  }
}

class _InfoEntry {
  final String label;
  final String value;

  const _InfoEntry(this.label, this.value);
}
