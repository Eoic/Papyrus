import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Empty state widget for when a book has no notes.
class EmptyNotesState extends StatelessWidget {
  final VoidCallback? onAddNote;
  final bool isEinkMode;

  const EmptyNotesState({
    super.key,
    this.onAddNote,
    this.isEinkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isEinkMode) {
      return _buildEinkState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Create notes to capture your thoughts about this book.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: onAddNote,
            icon: const Icon(Icons.add),
            label: const Text('Add Note'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEinkState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.pageMarginsEink),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO NOTES',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Create notes to capture your thoughts about this book.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            height: TouchTargets.einkRecommended,
            child: ElevatedButton(
              onPressed: onAddNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
              ),
              child: const Text(
                'ADD NOTE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
