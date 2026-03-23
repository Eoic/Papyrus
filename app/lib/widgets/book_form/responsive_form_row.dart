import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Responsive row that lays out children horizontally on desktop and
/// vertically on mobile. Used in book forms.
class ResponsiveFormRow extends StatelessWidget {
  final bool isDesktop;
  final List<Widget> children;

  const ResponsiveFormRow({
    super.key,
    required this.isDesktop,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop || children.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.expand((w) sync* {
          yield w;
          yield const SizedBox(height: Spacing.md);
        }).toList()..removeLast(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.expand((w) sync* {
        yield Expanded(child: w);
        yield const SizedBox(width: Spacing.md);
      }).toList()..removeLast(),
    );
  }
}
