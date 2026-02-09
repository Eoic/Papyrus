import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/add_book_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/file_import_item_card.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:provider/provider.dart';

/// Sheet for the digital book import flow: file picking, processing, and review.
class FileImportSheet extends StatelessWidget {
  const FileImportSheet({super.key});

  /// Show the import sheet immediately, then pick files.
  static Future<void> show(BuildContext context) async {
    final provider = AddBookProvider();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    if (isDesktop) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.dialog),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 640,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: const ImportContent(isDesktop: true),
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => ImportContent(
              isDesktop: false,
              scrollController: scrollController,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@visibleForTesting
class ImportContent extends StatefulWidget {
  final bool isDesktop;
  final ScrollController? scrollController;

  /// When false, skips auto-launching the file picker in initState.
  /// Used by tests to render the widget in a pre-configured provider state.
  @visibleForTesting
  final bool autoPick;

  const ImportContent({
    super.key,
    required this.isDesktop,
    this.scrollController,
    this.autoPick = true,
  });

  @override
  State<ImportContent> createState() => ImportContentState();
}

class ImportContentState extends State<ImportContent> {
  bool _hasStartedPicking = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPicking();
      });
    }
  }

  Future<void> _startPicking() async {
    if (_hasStartedPicking) return;
    _hasStartedPicking = true;

    final provider = context.read<AddBookProvider>();
    final hasPicked = await provider.pickFiles();

    if (!mounted) return;

    if (!hasPicked) {
      Navigator.of(context).pop();
      return;
    }

    final dataStore = context.read<DataStore>();
    provider.processFiles(dataStore);
  }

  Future<bool> _showCancelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel import?'),
        content: const Text(
          'Files that have been processed will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel import'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleCancel() async {
    final shouldCancel = await _showCancelDialog();
    if (shouldCancel && mounted) {
      final provider = context.read<AddBookProvider>();
      provider.cancelProcessing();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddBookProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    final isPicking = provider.isPicking;
    final isProcessing = provider.isProcessing;
    final isReview = !isPicking && !isProcessing && provider.items.isNotEmpty;

    final firstSuccessIndex = isReview
        ? provider.items.indexWhere((i) => i.status == FileImportStatus.success)
        : -1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isPicking) return;
        await _handleCancel();
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.md,
          bottom: widget.isDesktop
              ? Spacing.lg
              : viewInsets.bottom + Spacing.lg,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // DraggableScrollableSheet passes unconstrained cross-axis width
            // during its first layout frame on web. Return an empty widget for
            // that transient frame to avoid BoxConstraints infinite width
            // crashes in Material widgets like OutlinedButton.
            if (!constraints.hasBoundedWidth) {
              return const SizedBox.shrink();
            }
            return ListView(
              controller: widget.scrollController,
              children: [
                if (!widget.isDesktop) ...[
                  const BottomSheetHandle(),
                  const SizedBox(height: Spacing.lg),
                ],
                _buildHeader(
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  provider: provider,
                  isPicking: isPicking,
                  isProcessing: isProcessing,
                  isReview: isReview,
                ),
                const SizedBox(height: Spacing.md),
                if (isPicking)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Opening file picker...',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (var i = 0; i < provider.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: Spacing.sm),
                    FileImportItemCard(
                      item: provider.items[i],
                      index: i,
                      isReviewPhase: isReview,
                      isDesktop: widget.isDesktop,
                      initiallyExpanded: isReview && i == firstSuccessIndex,
                      onRemove: isReview ? (i) => provider.removeItem(i) : null,
                    ),
                  ],
                  const SizedBox(height: Spacing.md),
                  _buildFooter(
                    provider: provider,
                    isPicking: isPicking,
                    isProcessing: isProcessing,
                    isReview: isReview,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader({
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required AddBookProvider provider,
    required bool isPicking,
    required bool isProcessing,
    required bool isReview,
  }) {
    if (isPicking) {
      return Text('Import digital books', style: textTheme.headlineSmall);
    }

    if (isProcessing) {
      final totalCount = provider.totalCount;
      final processedCount = provider.processedCount;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importing $totalCount ${totalCount == 1 ? 'book' : 'books'}',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          LinearProgressIndicator(
            value: totalCount > 0 ? processedCount / totalCount : 0,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '$processedCount of $totalCount processed',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (isReview) {
      final successCount = provider.successCount;
      final totalCount = provider.totalCount;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            successCount == 1
                ? 'Review imported book'
                : 'Review imported books',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '$successCount of $totalCount ${totalCount == 1 ? 'book' : 'books'} ready to add',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Text('Import digital books', style: textTheme.headlineSmall);
  }

  // ============================================================================
  // FOOTER
  // ============================================================================

  Widget _buildFooter({
    required AddBookProvider provider,
    required bool isPicking,
    required bool isProcessing,
    required bool isReview,
  }) {
    // No buttons during picking
    if (isPicking) return const SizedBox.shrink();

    if (isProcessing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: _handleCancel, child: const Text('Cancel')),
        ],
      );
    }

    if (isReview) {
      final successCount = provider.successCount;
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: _handleCancel, child: const Text('Cancel')),
          const SizedBox(width: Spacing.sm),
          FilledButton(
            onPressed:
                provider.hasSuccessfulItems && !provider.isAddingToLibrary
                ? () => _addToLibrary(provider)
                : null,
            child: provider.isAddingToLibrary
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    successCount == 1
                        ? 'Add to library'
                        : 'Add $successCount books to library',
                  ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _addToLibrary(AddBookProvider provider) async {
    final dataStore = context.read<DataStore>();
    final count = await provider.addToLibrary(dataStore);

    if (!mounted) return;

    // Capture messenger before popping (context becomes invalid after pop)
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Added 1 book to library'
              : 'Added $count books to library',
        ),
      ),
    );
  }
}
