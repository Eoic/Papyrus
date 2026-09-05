import 'package:flutter/material.dart';

/// Calendar controls for displays where even the SDK's internal page and
/// year-selection transitions must be instant. Selection remains local until Save.
class StaticDatePicker extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final DateTimeRange? initialRange;
  final bool selectRange;
  final DatePickerEntryMode initialEntryMode;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;

  const StaticDatePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.initialRange,
    this.selectRange = false,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.helpText,
    this.cancelText,
    this.confirmText,
  });

  @override
  State<StaticDatePicker> createState() => _StaticDatePickerState();
}

class _StaticDatePickerState extends State<StaticDatePicker> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _start;
  DateTime? _end;
  late DateTime _month;
  late bool _input;
  bool _years = false;

  DateTime get _first => DateUtils.dateOnly(widget.firstDate);
  DateTime get _last => DateUtils.dateOnly(widget.lastDate);

  @override
  void initState() {
    super.initState();
    final initialStart = widget.initialRange?.start ?? widget.initialDate;
    _start = initialStart == null ? null : DateUtils.dateOnly(initialStart);
    _end = widget.initialRange == null ? null : DateUtils.dateOnly(widget.initialRange!.end);
    var displayed = _start ?? DateTime.now();
    if (displayed.isBefore(_first)) displayed = _first;
    if (displayed.isAfter(_last)) displayed = _last;
    _month = DateTime(displayed.year, displayed.month);
    _input =
        widget.initialEntryMode == DatePickerEntryMode.input ||
        widget.initialEntryMode == DatePickerEntryMode.inputOnly;
  }

  void _select(DateTime date) => setState(() {
    if (!widget.selectRange || _start == null || _end != null || date.isBefore(_start!)) {
      _start = date;
      _end = null;
    } else {
      _end = date;
    }
  });

  void _save() {
    if (_input) {
      _formKey.currentState!.save();
      if (!_formKey.currentState!.validate()) return;
    }
    if (_start == null || (widget.selectRange && (_end == null || _end!.isBefore(_start!)))) return;
    Navigator.of(context).pop(widget.selectRange ? DateTimeRange(start: _start!, end: _end!) : _start);
  }

  void _toggleEntryMode() {
    if (_input) {
      _formKey.currentState!.save();
      if (!_formKey.currentState!.validate()) return;
    }
    setState(() {
      _input = !_input;
      if (_start != null) _month = DateTime(_start!.year, _start!.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = MaterialLocalizations.of(context);
    final allowModeSwitch =
        widget.initialEntryMode != DatePickerEntryMode.calendarOnly &&
        widget.initialEntryMode != DatePickerEntryMode.inputOnly;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.helpText ?? (widget.selectRange ? labels.dateRangePickerHelpText : labels.datePickerHelpText),
                ),
              ),
              if (allowModeSwitch)
                IconButton(
                  tooltip: _input ? labels.calendarModeButtonLabel : labels.inputDateModeButtonLabel,
                  icon: Icon(_input ? Icons.calendar_today : Icons.edit_outlined),
                  onPressed: _toggleEntryMode,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.selectRange
                ? '${_start == null ? labels.dateRangeStartLabel : labels.formatMediumDate(_start!)} – '
                      '${_end == null ? labels.dateRangeEndLabel : labels.formatMediumDate(_end!)}'
                : _start == null
                ? ''
                : labels.formatMediumDate(_start!),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const Divider(),
        Flexible(child: SingleChildScrollView(child: _input ? _buildInput(labels) : _buildCalendar(labels))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.cancelText ?? labels.cancelButtonLabel),
              ),
              TextButton(onPressed: _save, child: Text(widget.confirmText ?? labels.okButtonLabel)),
            ],
          ),
        ),
      ],
    );
    if (widget.selectRange) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: content),
          ),
        ),
      );
    }
    return Dialog(child: SizedBox(width: 328, child: content));
  }

  Widget _buildInput(MaterialLocalizations labels) => Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          InputDatePickerFormField(
            initialDate: _start,
            firstDate: _first,
            lastDate: _last,
            fieldLabelText: widget.selectRange ? labels.dateRangeStartLabel : null,
            onDateSaved: (value) => _start = value,
          ),
          if (widget.selectRange) ...[
            const SizedBox(height: 16),
            InputDatePickerFormField(
              initialDate: _end,
              firstDate: _first,
              lastDate: _last,
              fieldLabelText: labels.dateRangeEndLabel,
              selectableDayPredicate: (day) => _start == null || !day.isBefore(_start!),
              onDateSaved: (value) => _end = value,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildCalendar(MaterialLocalizations labels) {
    final previous = DateTime(_month.year, _month.month - 1);
    final next = DateTime(_month.year, _month.month + 1);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _years = !_years),
                  child: Text(labels.formatMonthYear(_month)),
                ),
              ),
              IconButton(
                tooltip: labels.previousMonthTooltip,
                onPressed: DateTime(_month.year, _month.month).isAfter(DateTime(_first.year, _first.month))
                    ? () => setState(() {
                        _month = previous;
                        _years = false;
                      })
                    : null,
                icon: const BackButtonIcon(),
              ),
              IconButton(
                tooltip: labels.nextMonthTooltip,
                onPressed: next.isAfter(_last)
                    ? null
                    : () => setState(() {
                        _month = next;
                        _years = false;
                      }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        if (_years)
          SizedBox(
            height: 280,
            child: YearPicker(
              firstDate: _first,
              lastDate: _last,
              selectedDate: _month,
              onChanged: (date) => setState(() {
                var month = DateTime(date.year, _month.month);
                if (month.isBefore(DateTime(_first.year, _first.month))) month = DateTime(_first.year, _first.month);
                if (month.isAfter(_last)) month = DateTime(_last.year, _last.month);
                _month = month;
                _years = false;
              }),
            ),
          )
        else
          _buildDays(labels),
      ],
    );
  }

  Widget _buildDays(MaterialLocalizations labels) {
    final offset = (DateTime(_month.year, _month.month).weekday % 7 - labels.firstDayOfWeekIndex + 7) % 7;
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Table(
        children: [
          TableRow(
            children: List.generate(
              7,
              (i) => SizedBox(
                height: 36,
                child: Center(child: Text(labels.narrowWeekdays[(i + labels.firstDayOfWeekIndex) % 7])),
              ),
            ),
          ),
          for (var row = 0; row < 6; row++)
            TableRow(
              children: List.generate(7, (column) {
                final day = row * 7 + column - offset + 1;
                if (day < 1 || day > count) return const SizedBox(height: 40);
                final date = DateTime(_month.year, _month.month, day);
                final selected = DateUtils.isSameDay(date, _start) || DateUtils.isSameDay(date, _end);
                final inRange = _start != null && _end != null && date.isAfter(_start!) && date.isBefore(_end!);
                return SizedBox(
                  height: 40,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      backgroundColor: selected
                          ? colors.primary
                          : inRange
                          ? colors.primaryContainer
                          : null,
                      foregroundColor: selected
                          ? colors.onPrimary
                          : inRange
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                    onPressed: date.isBefore(_first) || date.isAfter(_last) ? null : () => _select(date),
                    child: Text(labels.formatDecimal(day)),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
