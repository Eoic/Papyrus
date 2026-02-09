import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Full-screen camera overlay for scanning ISBN barcodes.
class IsbnScannerDialog extends StatefulWidget {
  const IsbnScannerDialog({super.key});

  /// Show the scanner and return the scanned ISBN, or null if cancelled.
  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const IsbnScannerDialog(),
      ),
    );
  }

  @override
  State<IsbnScannerDialog> createState() => _IsbnScannerDialogState();
}

class _IsbnScannerDialogState extends State<IsbnScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _hasScanned = true;
    Navigator.of(context).pop(barcode!.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan ISBN'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.no_photography,
                          size: IconSizes.display,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: Spacing.md),
                        Text(
                          'Camera unavailable',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Please check camera permissions and try again.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Spacing.lg),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Go back'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                Text(
                  'Point camera at ISBN barcode',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: Spacing.md),
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    return IconButton(
                      onPressed: () => _controller.toggleTorch(),
                      icon: Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                        size: IconSizes.medium,
                      ),
                      tooltip: 'Toggle flash',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
