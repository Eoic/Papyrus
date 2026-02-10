import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// A reusable grid/list view mode toggle using SegmentedButton.
///
/// Used across library, shelves, and other pages that offer
/// grid vs list view switching.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.isGridView,
    required this.onChanged,
  });

  final bool isGridView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          icon: Icon(Icons.grid_view, size: IconSizes.small),
        ),
        ButtonSegment(
          value: false,
          icon: Icon(Icons.view_list, size: IconSizes.small),
        ),
      ],
      selected: {isGridView},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
