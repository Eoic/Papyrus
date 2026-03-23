import 'package:flutter/material.dart';
import 'package:papyrus/providers/book_details_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Custom e-ink tab bar for book details page.
/// Uses inverted colors for the selected tab via colorScheme.
class EinkBookDetailsTabBar extends StatelessWidget {
  final BookDetailsTab selectedTab;
  final int bookmarkCount;
  final int annotationCount;
  final int noteCount;
  final ValueChanged<BookDetailsTab> onTabChanged;

  const EinkBookDetailsTabBar({
    super.key,
    required this.selectedTab,
    required this.bookmarkCount,
    required this.annotationCount,
    required this.noteCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: TouchTargets.einkMin,
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            context,
            tab: BookDetailsTab.details,
            label: 'Details',
            isLast: false,
          ),
          _buildTab(
            context,
            tab: BookDetailsTab.bookmarks,
            label: 'Bookmarks',
            count: bookmarkCount,
            isLast: false,
          ),
          _buildTab(
            context,
            tab: BookDetailsTab.annotations,
            label: 'Annotations',
            count: annotationCount,
            isLast: false,
          ),
          _buildTab(
            context,
            tab: BookDetailsTab.notes,
            label: 'Notes',
            count: noteCount,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required BookDetailsTab tab,
    required String label,
    int? count,
    required bool isLast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedTab == tab;
    final displayLabel = count != null && count > 0 ? '$label ($count)' : label;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            border: isLast
                ? null
                : Border(
                    right: BorderSide(
                      color: colorScheme.outline,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            displayLabel,
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
