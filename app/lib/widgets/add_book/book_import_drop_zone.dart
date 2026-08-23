import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/add_book/book_import_batch_item.dart';
import 'package:papyrus/widgets/add_book/book_import_controller.dart';

typedef DroppedBookFilesCallback = void Function(List<SelectedBookFile> files, {String? feedback});

class BookImportDropZone extends StatefulWidget {
  const BookImportDropZone({super.key, required this.isPicking, required this.onBrowse, required this.onDroppedFiles});

  final bool isPicking;
  final VoidCallback onBrowse;
  final DroppedBookFilesCallback onDroppedFiles;

  @override
  State<BookImportDropZone> createState() => _BookImportDropZoneState();
}

class _BookImportDropZoneState extends State<BookImportDropZone> {
  static const _formats = 'EPUB, PDF, MOBI, AZW3, TXT, CBR, and CBZ';
  static const _unsupportedDropMessage = 'No supported book files were dropped.';
  static const _skippedFilesMessage = 'Some files were skipped because their format is not supported.';

  bool _isDragging = false;
  bool _isFocused = false;
  bool _isReadingDrop = false;

  bool get _isBusy => widget.isPicking || _isReadingDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final supportsDrop = _supportsFileDrop(theme.platform);
    final isActive = _isDragging || _isFocused;
    final backgroundColor = _isDragging
        ? colorScheme.primaryContainer.withValues(alpha: 0.18)
        : _isFocused
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
        : Colors.transparent;
    final borderColor = isActive ? colorScheme.primary : colorScheme.outlineVariant;
    final instruction = supportsDrop ? 'Drag and drop book files here' : 'Choose book files';

    final surface = FocusableActionDetector(
      enabled: !_isBusy,
      mouseCursor: _isBusy ? SystemMouseCursors.basic : SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _browse();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _isFocused = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: CustomPaint(
          foregroundPainter: _DashedRoundedBorderPainter(
            color: borderColor,
            radius: AppRadius.xl,
            strokeWidth: isActive ? 2 : 1.25,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _isBusy ? null : widget.onBrowse,
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minimumHeight = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minimumHeight),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isBusy)
                              const SizedBox.square(dimension: 48, child: CircularProgressIndicator(strokeWidth: 3))
                            else
                              Icon(Icons.cloud_upload_outlined, size: 48, color: colorScheme.primary),
                            const SizedBox(height: Spacing.md),
                            Text(instruction, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              _formats,
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: Spacing.lg),
                            SizedBox(
                              width: 176,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, ComponentSizes.buttonHeightMobile),
                                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                                ),
                                onPressed: _isBusy ? null : widget.onBrowse,
                                icon: const Icon(Icons.folder_open_outlined),
                                label: const Text('Browse files', maxLines: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (!supportsDrop) return surface;
    return DropTarget(
      enable: !_isBusy,
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _readDroppedFiles,
      child: surface,
    );
  }

  void _browse() {
    if (!_isBusy) widget.onBrowse();
  }

  Future<void> _readDroppedFiles(DropDoneDetails details) async {
    if (_isBusy) return;
    final supportedItems = details.files.whereType<DropItemFile>().where(_isSupportedBook).toList(growable: false);
    final skippedFiles = supportedItems.length != details.files.length;

    setState(() {
      _isDragging = false;
      _isReadingDrop = true;
    });

    if (supportedItems.isEmpty) {
      setState(() => _isReadingDrop = false);
      widget.onDroppedFiles(const [], feedback: _unsupportedDropMessage);
      return;
    }

    final files = await Future.wait(supportedItems.map(_readBookFile));
    if (!mounted) return;
    setState(() => _isReadingDrop = false);
    widget.onDroppedFiles(files, feedback: skippedFiles ? _skippedFilesMessage : null);
  }

  bool _isSupportedBook(DropItemFile item) {
    final name = item.name.toLowerCase();
    final separator = name.lastIndexOf('.');
    if (separator < 0 || separator == name.length - 1) return false;
    return bookImportNativeExtensions.contains(name.substring(separator + 1));
  }

  Future<SelectedBookFile> _readBookFile(DropItemFile item) async {
    final bookmark = item.extraAppleBookmark;
    var hasSecurityScopedAccess = false;
    try {
      if (bookmark != null && bookmark.isNotEmpty) {
        hasSecurityScopedAccess = await DesktopDrop.instance.startAccessingSecurityScopedResource(bookmark: bookmark);
      }
      return SelectedBookFile(name: item.name, bytes: await item.readAsBytes());
    } catch (_) {
      return SelectedBookFile(name: item.name, bytes: null);
    } finally {
      if (hasSecurityScopedAccess && bookmark != null) {
        try {
          await DesktopDrop.instance.stopAccessingSecurityScopedResource(bookmark: bookmark);
        } catch (_) {
          // File reading has already completed; failure to release is not actionable here.
        }
      }
    }
  }
}

bool _supportsFileDrop(TargetPlatform platform) =>
    platform == TargetPlatform.windows || platform == TargetPlatform.macOS || platform == TargetPlatform.linux;

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color, required this.radius, required this.strokeWidth});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final inset = strokeWidth / 2;
    final bounds = Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth);
    final path = Path()..addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(radius - inset)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, math.min(distance + 8, metric.length)), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius || strokeWidth != oldDelegate.strokeWidth;
}
