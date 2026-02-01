import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/book_details/book_info_grid.dart';
import 'package:provider/provider.dart';

/// Details tab content for book details page.
/// Shows description, information grid, shelves, and topics.
class BookDetails extends StatefulWidget {
  final BookData book;
  final bool isDescriptionExpanded;
  final VoidCallback? onToggleDescription;

  const BookDetails({
    super.key,
    required this.book,
    this.isDescriptionExpanded = false,
    this.onToggleDescription,
  });

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  @override
  Widget build(BuildContext context) {
    final displayMode = context.watch<DisplayModeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (displayMode.isEinkMode) {
      return _buildEinkLayout(context);
    }
    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description column (60%)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Description'),
                const SizedBox(height: Spacing.sm),
                _buildDescription(context, showFull: true),
                const SizedBox(height: Spacing.xl),
                _buildSectionTitle(context, 'Shelves'),
                const SizedBox(height: Spacing.sm),
                _buildShelvesChips(context),
                const SizedBox(height: Spacing.lg),
                _buildSectionTitle(context, 'Topics'),
                const SizedBox(height: Spacing.sm),
                _buildTopicsChips(context),
              ],
            ),
          ),
          const SizedBox(width: Spacing.xxl),
          // Information column (40%)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Information'),
                const SizedBox(height: Spacing.sm),
                BookInfoGrid(book: widget.book),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Description'),
          const SizedBox(height: Spacing.sm),
          _buildDescription(context),
          const SizedBox(height: Spacing.lg),
          _buildSectionTitle(context, 'Information'),
          const SizedBox(height: Spacing.sm),
          BookInfoGrid(book: widget.book),
          const SizedBox(height: Spacing.lg),
          _buildSectionTitle(context, 'Shelves'),
          const SizedBox(height: Spacing.sm),
          _buildShelvesChips(context),
          const SizedBox(height: Spacing.lg),
          _buildSectionTitle(context, 'Topics'),
          const SizedBox(height: Spacing.sm),
          _buildTopicsChips(context),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  Widget _buildEinkLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.pageMarginsEink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEinkSectionTitle(context, 'DESCRIPTION'),
          const SizedBox(height: Spacing.sm),
          _buildDescription(context, showFull: true),
          const SizedBox(height: Spacing.xl),
          _buildEinkSectionTitle(context, 'INFORMATION'),
          const SizedBox(height: Spacing.sm),
          BookInfoGrid(book: widget.book, isEinkMode: true),
          const SizedBox(height: Spacing.xl),
          _buildEinkSectionTitle(context, 'SHELVES'),
          const SizedBox(height: Spacing.sm),
          _buildShelvesText(context),
          const SizedBox(height: Spacing.xl),
          _buildEinkSectionTitle(context, 'TOPICS'),
          const SizedBox(height: Spacing.sm),
          _buildTopicsText(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
      ],
    );
  }

  Widget _buildEinkSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
        ),
        const Divider(
          height: Spacing.sm,
          thickness: 2,
          color: Colors.black,
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, {bool showFull = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    // Sample description - would come from book data in the future
    final description = _getSampleDescription(widget.book.id);

    if (description.isEmpty) {
      return Text(
        'No description available.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
      );
    }

    final shouldTruncate = !showFull && !widget.isDescriptionExpanded;
    final maxLines = shouldTruncate ? 4 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
          maxLines: maxLines,
          overflow: shouldTruncate ? TextOverflow.ellipsis : null,
        ),
        if (!showFull && description.length > 200) ...[
          const SizedBox(height: Spacing.xs),
          GestureDetector(
            onTap: widget.onToggleDescription,
            child: Text(
              widget.isDescriptionExpanded ? 'Show less' : 'Read more',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShelvesChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.book.shelves.isEmpty) {
      return Text(
        'Not assigned to any shelf.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: widget.book.shelves.map((shelf) {
        return Chip(
          label: Text(shelf),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            // TODO: Implement remove from shelf
          },
        );
      }).toList(),
    );
  }

  Widget _buildTopicsChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.book.topics.isEmpty) {
      return Text(
        'No topics assigned.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: widget.book.topics.map((topic) {
        return Chip(
          avatar: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getTopicColor(topic),
              shape: BoxShape.circle,
            ),
          ),
          label: Text(topic),
        );
      }).toList(),
    );
  }

  Widget _buildShelvesText(BuildContext context) {
    if (widget.book.shelves.isEmpty) {
      return Text(
        'Not assigned to any shelf.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Text(
      widget.book.shelves.join(', '),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildTopicsText(BuildContext context) {
    if (widget.book.topics.isEmpty) {
      return Text(
        'No topics assigned.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Text(
      widget.book.topics.join(', '),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Color _getTopicColor(String topic) {
    // Generate consistent color based on topic name
    final hash = topic.hashCode;
    final colors = [
      const Color(0xFF5654A8),
      const Color(0xFF7A5368),
      const Color(0xFF4A6741),
      const Color(0xFF8B6914),
      const Color(0xFF6B4423),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getSampleDescription(String bookId) {
    switch (bookId) {
      case '1':
        return 'The Pragmatic Programmer is one of those rare tech books you\'ll read, re-read, and read again over the years. Whether you\'re new to the field or an experienced practitioner, you\'ll come away with fresh insights each and every time.\n\nDave Thomas and Andy Hunt wrote the first edition of this influential book in 1999 to help their clients create better software and rediscover the joy of coding. These lessons have helped a generation of programmers examine the very essence of software development, independent of any particular language, framework, or methodology, and the Pragmatic philosophy has spawned hundreds of books, screencasts, and audio books, as well as thousands of careers and success stories.';
      case '2':
        return 'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees. Every year, countless hours and significant resources are lost because of poorly written code. But it doesn\'t have to be that way.\n\nNoted software expert Robert C. Martin presents a revolutionary paradigm with Clean Code: A Handbook of Agile Software Craftsmanship. Martin has teamed up with his colleagues from Object Mentor to distill their best agile practice of cleaning code "on the fly" into a book that will instill within you the values of a software craftsman and make you a better programmer—but only if you work at it.';
      case '3':
        return 'Capturing a wealth of experience about the design of object-oriented software, four top-notch designers present a catalog of simple and succinct solutions to commonly occurring design problems. Previously undocumented, these 23 patterns allow designers to create more flexible, elegant, and ultimately reusable designs without having to rediscover the design solutions themselves.';
      default:
        return 'No description available for this book.';
    }
  }
}
