import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/add_book_sheet_scaffold.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';

typedef DigitalBookFilePicker = Future<List<SelectedBookFile>> Function();

/// Selects one or more digital books before they are processed for import.
class DigitalBookImportSheet extends StatefulWidget {
  const DigitalBookImportSheet({
    super.key,
    required this.pickFiles,
    required this.onConfirm,
    required this.onCancel,
    this.scrollController,
  });

  final DigitalBookFilePicker pickFiles;
  final ValueChanged<List<SelectedBookFile>> onConfirm;
  final VoidCallback onCancel;
  final ScrollController? scrollController;

  static const _webExtensions = ['epub'];
  static const _nativeExtensions = ['epub', 'pdf', 'mobi', 'azw3', 'txt', 'cbr', 'cbz'];

  /// Opens the file-selection step as its own root-level modal sheet.
  static Future<List<SelectedBookFile>?> show(BuildContext context, {DigitalBookFilePicker? pickFiles}) async {
    Future<List<SelectedBookFile>?>? sheetCompleted;
    final files = await showModalBottomSheet<List<SelectedBookFile>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) {
        sheetCompleted = ModalRoute.of<List<SelectedBookFile>>(sheetContext)?.completed;
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => DigitalBookImportSheet(
            pickFiles: pickFiles ?? _pickFiles,
            scrollController: scrollController,
            onCancel: () => Navigator.of(sheetContext).pop(),
            onConfirm: (files) => Navigator.of(sheetContext).pop(files),
          ),
        );
      },
    );
    await sheetCompleted;
    return files;
  }

  static Future<List<SelectedBookFile>> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kIsWeb ? _webExtensions : _nativeExtensions,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return const [];

    return result.files.map((file) => SelectedBookFile(name: file.name, bytes: file.bytes)).toList();
  }

  @override
  State<DigitalBookImportSheet> createState() => _DigitalBookImportSheetState();
}

class _DigitalBookImportSheetState extends State<DigitalBookImportSheet> {
  List<SelectedBookFile> _files = const [];
  bool _isPicking = false;
  String? _pickerError;

  List<SelectedBookFile> get _readableFiles => _files.where((file) => file.bytes != null).toList(growable: false);

  Future<void> _browse() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _pickerError = null;
    });

    try {
      final files = await widget.pickFiles();
      if (!mounted || files.isEmpty) return;
      setState(() => _files = List.unmodifiable(files));
    } catch (_) {
      if (!mounted) return;
      setState(() => _pickerError = 'Could not open the selected files. Please try again.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _remove(SelectedBookFile file) {
    setState(() => _files = List.unmodifiable(_files.where((candidate) => !identical(candidate, file))));
  }

  @override
  Widget build(BuildContext context) {
    final readableFiles = _readableFiles;
    final fileCount = _files.length;
    final importLabel = 'Import $fileCount ${fileCount == 1 ? 'book' : 'books'}';

    return AddBookSheetScaffold(
      title: 'Import digital books',
      onClose: widget.onCancel,
      body: ListView(
        key: const Key('digital-import-selection-list'),
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        children: [
          Text('Select one or more digital book files to import.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _isPicking ? null : _browse,
              icon: _isPicking
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: const Text('Browse files'),
            ),
          ),
          if (_pickerError case final message?) ...[
            const SizedBox(height: Spacing.sm),
            Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_files.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Text('${_files.length} selected', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            ..._files.map((file) => _SelectedFileRow(file: file, onRemove: () => _remove(file))),
          ],
        ],
      ),
      footer: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: Spacing.sm,
        overflowSpacing: Spacing.sm,
        children: [
          TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
          FilledButton(
            onPressed: readableFiles.isEmpty ? null : () => widget.onConfirm(_files),
            child: Text(importLabel),
          ),
        ],
      ),
    );
  }
}

class _SelectedFileRow extends StatelessWidget {
  const _SelectedFileRow({required this.file, required this.onRemove});

  final SelectedBookFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final readable = file.bytes != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          readable ? Icons.description_outlined : Icons.error_outline,
          color: readable ? null : colorScheme.error,
        ),
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: readable ? null : Text('Unreadable', style: TextStyle(color: colorScheme.error)),
        trailing: IconButton(tooltip: 'Remove ${file.name}', onPressed: onRemove, icon: const Icon(Icons.close)),
      ),
    );
  }
}
