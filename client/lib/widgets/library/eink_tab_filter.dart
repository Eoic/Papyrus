import 'package:flutter/material.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

/// E-ink optimized tab-based filter for library content.
/// High contrast, large touch targets, no animations.
class EinkTabFilter extends StatelessWidget {
  const EinkTabFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = [
      _TabData(type: LibraryFilterType.all, label: 'ALL'),
      _TabData(type: LibraryFilterType.shelves, label: 'SHELVES'),
      _TabData(type: LibraryFilterType.topics, label: 'TOPICS'),
      _TabData(type: LibraryFilterType.favorites, label: 'FAVORITES'),
    ];

    return Container(
      height: TouchTargets.einkMin,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline,
            width: BorderWidths.einkDefault,
          ),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = libraryProvider.isFilterActive(tab.type);

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => libraryProvider.setFilter(tab.type),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    border: Border(
                      right: BorderSide(color: colorScheme.outline, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tab.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabData {
  final LibraryFilterType type;
  final String label;

  const _TabData({required this.type, required this.label});
}
