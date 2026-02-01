import 'package:flutter/material.dart';
import 'package:papyrus/providers/book_details_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Custom e-ink tab bar for book details page.
/// Uses inverted colors (black bg, white text) for selected tab.
class EinkBookDetailsTabBar extends StatelessWidget {
  final BookDetailsTab selectedTab;
  final int annotationCount;
  final int noteCount;
  final ValueChanged<BookDetailsTab> onTabChanged;

  const EinkBookDetailsTabBar({
    super.key,
    required this.selectedTab,
    required this.annotationCount,
    required this.noteCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TouchTargets.einkMin,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: BorderWidths.einkDefault,
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            context,
            tab: BookDetailsTab.details,
            label: 'DETAILS',
            isFirst: true,
          ),
          _buildTab(
            context,
            tab: BookDetailsTab.annotations,
            label: 'ANNOTATIONS',
            count: annotationCount,
          ),
          _buildTab(
            context,
            tab: BookDetailsTab.notes,
            label: 'NOTES',
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = selectedTab == tab;
    final displayLabel = count != null && count > 0 ? '$label ($count)' : label;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            border: isLast
                ? null
                : const Border(
                    right: BorderSide(
                      color: Colors.black,
                      width: BorderWidths.einkDefault,
                    ),
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            displayLabel,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
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
