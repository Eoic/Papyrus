import 'package:flutter/material.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/widgets/shared/app_motion_control.dart';

typedef _ShelfSortSelection = ({ShelfSortOption option, bool ascending});

bool _isEinkTheme(ThemeData theme) {
  final border = theme.inputDecorationTheme.border;
  return border is OutlineInputBorder &&
      border.borderRadius == BorderRadius.zero &&
      border.borderSide.width >= BorderWidths.einkDefault;
}

class _ChipEntry {
  final String id;
  final bool isActive;
  final int defaultOrder;
  final Widget child;

  const _ChipEntry({required this.id, required this.isActive, required this.defaultOrder, required this.child});
}

class _SelectionOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const _SelectionOption({required this.value, required this.label, this.icon});
}

class _DropdownFilterChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool isSelected;
  final String? tooltip;
  final VoidCallback onPressed;

  const _DropdownFilterChip({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEink = _isEinkTheme(theme);
    final foregroundColor = isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$semanticLabel: $label',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0),
        child: AppMotionControl(
          value: null,
          builder: (focusNode) => ActionChip(
            focusNode: focusNode,
            chipAnimationStyle: appChipAnimationStyle(context),
            tooltip: tooltip,
            avatar: Icon(icon, size: 18, color: foregroundColor),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: foregroundColor),
              ],
            ),
            labelStyle: TextStyle(color: foregroundColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            backgroundColor: isSelected ? colorScheme.secondaryContainer : colorScheme.surfaceContainerLow,
            side: BorderSide(
              color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
              width: isEink ? BorderWidths.einkDefault : BorderWidths.thin,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isEink ? AppRadius.none : AppRadius.full),
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _SingleSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<_SelectionOption<T>> options;
  final T selectedValue;

  const _SingleSelectionSheet({required this.title, required this.options, required this.selectedValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.value == selectedValue;

              return Semantics(
                selected: isSelected,
                child: ListTile(
                  selected: isSelected,
                  leading: option.icon == null ? null : Icon(option.icon),
                  title: Text(option.label),
                  trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<T?> _showSingleSelectionSheet<T>(
  BuildContext context, {
  required String title,
  required List<_SelectionOption<T>> options,
  required T selectedValue,
}) {
  return showModalBottomSheet<T>(
    sheetAnimationStyle: AppMotion.animationStyle(context),
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SingleSelectionSheet<T>(title: title, options: options, selectedValue: selectedValue),
  );
}

class ShelvesFilterChips extends StatelessWidget {
  final double? horizontalPadding;

  const ShelvesFilterChips({super.key, this.horizontalPadding});

  static const List<_SelectionOption<ShelfContentsFilter>> _contentsOptions = [
    _SelectionOption(value: ShelfContentsFilter.all, label: 'Any'),
    _SelectionOption(value: ShelfContentsFilter.withBooks, label: 'With books', icon: Icons.auto_stories_outlined),
    _SelectionOption(value: ShelfContentsFilter.empty, label: 'Empty', icon: Icons.inventory_2_outlined),
  ];

  static const List<_SelectionOption<ShelfTypeFilter>> _typeOptions = [
    _SelectionOption(value: ShelfTypeFilter.all, label: 'Any'),
    _SelectionOption(value: ShelfTypeFilter.regular, label: 'Regular', icon: Icons.shelves),
    _SelectionOption(value: ShelfTypeFilter.smart, label: 'Smart', icon: Icons.auto_awesome_outlined),
  ];

  static const List<_SelectionOption<_ShelfSortSelection>> _sortOptions = [
    _SelectionOption(value: (option: ShelfSortOption.name, ascending: true), label: 'Name (A-Z)'),
    _SelectionOption(value: (option: ShelfSortOption.name, ascending: false), label: 'Name (Z-A)'),
    _SelectionOption(value: (option: ShelfSortOption.bookCount, ascending: true), label: 'Book count (Ascending)'),
    _SelectionOption(value: (option: ShelfSortOption.bookCount, ascending: false), label: 'Book count (Descending)'),
    _SelectionOption(value: (option: ShelfSortOption.dateCreated, ascending: false), label: 'Date created (newest)'),
    _SelectionOption(value: (option: ShelfSortOption.dateCreated, ascending: true), label: 'Date created (oldest)'),
    _SelectionOption(value: (option: ShelfSortOption.dateModified, ascending: false), label: 'Date modified (newest)'),
    _SelectionOption(value: (option: ShelfSortOption.dateModified, ascending: true), label: 'Date modified (oldest)'),
  ];

  static const List<_SelectionOption<ShelvesViewMode>> _viewOptions = [
    _SelectionOption(value: ShelvesViewMode.smallGrid, label: 'Small grid'),
    _SelectionOption(value: ShelvesViewMode.largeGrid, label: 'Large grid'),
    _SelectionOption(value: ShelvesViewMode.list, label: 'List'),
  ];

  @override
  Widget build(BuildContext context) {
    final isEink = _isEinkTheme(Theme.of(context));
    final provider = context.watch<ShelvesProvider>();
    final selectedContents = _optionFor(_contentsOptions, provider.contentsFilter);
    final selectedType = _optionFor(_typeOptions, provider.typeFilter);
    final selectedSortValue = (option: provider.shelfSortOption, ascending: provider.shelfSortAscending);
    final selectedSort = _optionFor(_sortOptions, selectedSortValue);
    final selectedView = _optionFor(_viewOptions, provider.viewMode);

    final chips = <_ChipEntry>[
      _ChipEntry(
        id: 'contents',
        defaultOrder: 0,
        isActive: provider.contentsFilter != ShelfContentsFilter.all,
        child: _DropdownFilterChip(
          label: provider.contentsFilter == ShelfContentsFilter.all ? 'Contents' : selectedContents.label,
          semanticLabel: 'Shelf contents',
          icon: Icons.auto_stories_outlined,
          isSelected: provider.contentsFilter != ShelfContentsFilter.all,
          tooltip: 'Filter by shelf contents',
          onPressed: () => _selectSingle<ShelfContentsFilter>(
            context: context,
            title: 'Shelf contents',
            options: _contentsOptions,
            selectedValue: provider.contentsFilter,
            onSelected: provider.setContentsFilter,
          ),
        ),
      ),
      _ChipEntry(
        id: 'sort',
        defaultOrder: 1,
        isActive: provider.shelfSortOption != ShelfSortOption.name || !provider.shelfSortAscending,
        child: _DropdownFilterChip(
          label: selectedSort.label,
          semanticLabel: 'Shelf sorting',
          icon: Icons.sort_rounded,
          isSelected: provider.shelfSortOption != ShelfSortOption.name || !provider.shelfSortAscending,
          tooltip: 'Sort shelves',
          onPressed: () => _selectSingle<_ShelfSortSelection>(
            context: context,
            title: 'Sort shelves',
            options: _sortOptions,
            selectedValue: selectedSortValue,
            onSelected: (selection) => provider.setShelfSortOption(selection.option, ascending: selection.ascending),
          ),
        ),
      ),
      _ChipEntry(
        id: 'type',
        defaultOrder: 2,
        isActive: provider.typeFilter != ShelfTypeFilter.all,
        child: _DropdownFilterChip(
          label: provider.typeFilter == ShelfTypeFilter.all ? 'Type' : selectedType.label,
          semanticLabel: 'Shelf type',
          icon: Icons.shelves,
          isSelected: provider.typeFilter != ShelfTypeFilter.all,
          tooltip: 'Filter by shelf type',
          onPressed: () => _selectSingle<ShelfTypeFilter>(
            context: context,
            title: 'Shelf type',
            options: _typeOptions,
            selectedValue: provider.typeFilter,
            onSelected: provider.setTypeFilter,
          ),
        ),
      ),
      _ChipEntry(
        id: 'view',
        defaultOrder: 3,
        isActive: provider.viewMode != ShelvesViewMode.smallGrid,
        child: _DropdownFilterChip(
          label: selectedView.label,
          semanticLabel: 'View mode',
          icon: Icons.grid_on,
          isSelected: provider.viewMode != ShelvesViewMode.smallGrid,
          tooltip: 'Change view mode',
          onPressed: () => _selectSingle<ShelvesViewMode>(
            context: context,
            title: 'View mode',
            options: _viewOptions,
            selectedValue: provider.viewMode,
            onSelected: provider.setViewMode,
          ),
        ),
      ),
    ];

    chips.sort((a, b) {
      final activeComparison = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
      return activeComparison != 0 ? activeComparison : a.defaultOrder.compareTo(b.defaultOrder);
    });

    final orderKey = [...chips.map((chip) => chip.id), if (provider.hasActiveShelfControls) 'clear-all'].join('-');

    return SizedBox(
      height: TouchTargets.mobileRecommended,
      child: AnimatedSwitcher(
        key: ValueKey(AppMotion.disabled(context)),
        duration: AppMotion.duration(context, AnimationDurations.standard),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(alignment: Alignment.centerLeft, children: [...previousChildren, ?currentChild]);
        },
        child: ListView.separated(
          key: ValueKey(orderKey),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 16),
          itemCount: chips.length + (provider.hasActiveShelfControls ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index < chips.length) {
              final chip = chips[index];
              return KeyedSubtree(key: ValueKey(chip.id), child: chip.child);
            }

            return Align(
              alignment: Alignment.center,
              child: TextButton(
                key: const ValueKey('clear-all'),
                onPressed: provider.clearShelfControls,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, TouchTargets.mobileMin),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: isEink ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero) : null,
                ),
                child: const Text('Clear all'),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectSingle<T>({
    required BuildContext context,
    required String title,
    required List<_SelectionOption<T>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) async {
    final result = await _showSingleSelectionSheet<T>(
      context,
      title: title,
      options: options,
      selectedValue: selectedValue,
    );

    if (result == null || result == selectedValue) {
      return;
    }

    onSelected(result);
  }

  static _SelectionOption<T> _optionFor<T>(List<_SelectionOption<T>> options, T selectedValue) {
    return options.firstWhere((option) => option.value == selectedValue);
  }
}
