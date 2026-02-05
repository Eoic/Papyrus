import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// E-ink header bar with back button and centered title.
/// Used on auth pages (login, register) in e-ink mode.
class EinkAuthHeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const EinkAuthHeaderBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ComponentSizes.einkHeaderHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          SizedBox(
            width: ComponentSizes.einkHeaderHeight,
            height: ComponentSizes.einkHeaderHeight,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back,
                size: IconSizes.large,
                color: Colors.black,
              ),
            ),
          ),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Spacer to balance the layout
          const SizedBox(width: ComponentSizes.einkHeaderHeight),
        ],
      ),
    );
  }
}
