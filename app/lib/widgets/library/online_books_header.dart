import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Header for the online book search experience.
class OnlineBooksHeader extends StatelessWidget {
  const OnlineBooksHeader({
    super.key,
    required this.controller,
    required this.autofocus,
    required this.isSearching,
    required this.onBack,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool autofocus;
  final bool isSearching;
  final VoidCallback onBack;
  final ValueChanged<String> onSearch;

  void _submit() {
    final query = controller.text.trim();

    if (isSearching || query.isEmpty) {
      return;
    }

    onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < Breakpoints.tablet;
        final backButton = Semantics(
          label: 'Back',
          button: true,
          child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, tooltip: 'Back'),
        );
        final title = Text(
          'Online results',
          style: textTheme.headlineSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        if (useCompactLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  backButton,
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: title),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              _buildSearchField(),
            ],
          );
        }

        return Row(
          children: [
            backButton,
            const SizedBox(width: Spacing.sm),
            Expanded(flex: 2, child: title),
            const SizedBox(width: Spacing.lg),
            Expanded(flex: 3, child: _buildSearchField()),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final canSubmit = !isSearching && value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Search online books',
            suffixIcon: Semantics(
              label: 'Search',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: canSubmit ? _submit : null,
                tooltip: 'Search',
              ),
            ),
          ),
        );
      },
    );
  }
}
