import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_header.dart';

typedef AcquisitionCommandLabel = String Function(String command);

Future<String?> showAcquisitionCommandSheet({
  required BuildContext context,
  required String endpointName,
  required String endpointKindLabel,
  required List<String> commands,
  required AcquisitionCommandLabel commandLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (sheetContext) => Padding(
      key: const Key('acquisition-command-sheet'),
      padding: const EdgeInsets.all(Spacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: Spacing.md),
            BottomSheetHeader(title: endpointName, onCancel: () => Navigator.of(sheetContext).pop()),
            const SizedBox(height: Spacing.sm),
            Text(
              endpointKindLabel,
              style: Theme.of(
                sheetContext,
              ).textTheme.labelLarge?.copyWith(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.sm),
            for (final command in commands)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_arrow),
                title: Text(commandLabel(command)),
                subtitle: Text(command),
                onTap: () => Navigator.of(sheetContext).pop(command),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<List<int>?> showAcquisitionIdsSheet({required BuildContext context, required String title}) {
  var enteredIds = '';

  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (sheetContext) => Padding(
      key: const Key('acquisition-arr-ids-sheet'),
      padding: EdgeInsets.zero,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.md),
              BottomSheetHeader(
                title: title,
                onCancel: () => Navigator.of(sheetContext).pop(),
                saveLabel: 'Run',
                onSave: () {
                  final ids = enteredIds
                      .split(',')
                      .map((value) => int.tryParse(value.trim()))
                      .whereType<int>()
                      .toList();

                  Navigator.of(sheetContext).pop(ids);
                },
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'IDs',
                  helperText: 'Comma-separated IDs from the Arr application',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => enteredIds = value,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool?> showAcquisitionRemoveSheet({required BuildContext context, required String endpointName}) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;

      return Padding(
        key: const Key('acquisition-remove-sheet'),
        padding: const EdgeInsets.all(Spacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.md),
              BottomSheetHeader(title: 'Remove $endpointName?', onCancel: () => Navigator.of(sheetContext).pop(false)),
              const SizedBox(height: Spacing.md),
              const Text('Saved credentials for this integration will be removed.'),
              const SizedBox(height: Spacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
