import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Reusable date picker field for book forms (add and edit).
class BookDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  const BookDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged(null);
                },
              ),
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 20),
              onPressed: () => _pickDate(context),
            ),
          ],
        ),
      ),
      onTap: () => _pickDate(context),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = DateFormat.yMMMMd().format(picked);
      onChanged(picked);
    }
  }
}
