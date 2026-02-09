import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Widget for picking book cover images from file or URL.
class CoverImagePicker extends StatefulWidget {
  final String? initialUrl;
  final Uint8List? initialBytes;
  final void Function(String? url) onUrlChanged;
  final void Function(Uint8List? bytes) onFileChanged;
  final bool isDesktop;
  final double? coverWidth;
  final double? coverHeight;

  const CoverImagePicker({
    super.key,
    this.initialUrl,
    this.initialBytes,
    required this.onUrlChanged,
    required this.onFileChanged,
    this.isDesktop = false,
    this.coverWidth,
    this.coverHeight,
  });

  @override
  State<CoverImagePicker> createState() => _CoverImagePickerState();
}

class _CoverImagePickerState extends State<CoverImagePicker> {
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _showUrlInput = false;
  bool _isLoading = false;
  String? _error;

  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialUrl;
    _imageBytes = widget.initialBytes;
    _urlController.text = widget.initialUrl ?? '';
    _showUrlInput =
        widget.initialUrl?.isNotEmpty == true && widget.initialBytes == null;
  }

  @override
  void didUpdateWidget(CoverImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync URL when parent provides a new one (e.g., from metadata fetch)
    if (widget.initialUrl != oldWidget.initialUrl) {
      setState(() {
        _imageUrl = widget.initialUrl;
        _urlController.text = widget.initialUrl ?? '';
        // Clear bytes if URL changed from external source
        if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
          _imageBytes = null;
        }
      });
    }
    // Sync bytes when parent provides new ones
    if (widget.initialBytes != oldWidget.initialBytes) {
      setState(() {
        _imageBytes = widget.initialBytes;
        if (widget.initialBytes != null) {
          _imageUrl = null;
          _urlController.clear();
        }
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  double get _coverWidth =>
      widget.coverWidth ?? (widget.isDesktop ? 280.0 : 180.0);
  double get _coverHeight =>
      widget.coverHeight ?? (widget.isDesktop ? 420.0 : 270.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover preview (always centered)
        Center(child: _buildCoverPreview(context)),
        SizedBox(height: widget.isDesktop ? Spacing.md : Spacing.lg),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showUrlInput = !_showUrlInput),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('URL'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _showUrlInput
                      ? colorScheme.secondaryContainer
                      : null,
                ),
              ),
            ),
          ],
        ),

        // URL input
        if (_showUrlInput) ...[
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://...',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _urlController.clear();
                        _onUrlChanged('');
                      },
                      tooltip: 'Clear URL',
                    )
                  : null,
            ),
            keyboardType: TextInputType.url,
            style: Theme.of(context).textTheme.bodySmall,
            onChanged: _onUrlChanged,
            onSubmitted: (_) => _applyUrl(),
          ),
        ],

        // Error message
        if (_error != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            _error!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCoverPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: _coverWidth,
        height: _coverHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: _buildCoverImage(context),
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => _buildPlaceholder(context),
          ),
          Positioned(top: 8, right: 8, child: _buildRemoveButton(context)),
        ],
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => _buildPlaceholder(context),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
          Positioned(top: 8, right: 8, child: _buildRemoveButton(context)),
        ],
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildRemoveButton(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _clearImage,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: widget.isDesktop ? 56 : 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Tap to add cover',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: widget.isDesktop ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes != null) {
          // Check file size (max 5MB)
          if (file.bytes!.length > 5 * 1024 * 1024) {
            setState(() {
              _error = 'Image must be less than 5MB';
              _isLoading = false;
            });
            return;
          }

          setState(() {
            _imageBytes = file.bytes;
            _imageUrl = null;
            _showUrlInput = false;
            _isLoading = false;
          });

          widget.onFileChanged(file.bytes);
          widget.onUrlChanged(null);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image';
        _isLoading = false;
      });
    }
  }

  void _onUrlChanged(String value) {
    final url = value.trim();
    setState(() {
      _imageUrl = url.isEmpty ? null : url;
      if (url.isNotEmpty) {
        _imageBytes = null;
      }
    });

    widget.onUrlChanged(url.isEmpty ? null : url);
    if (url.isNotEmpty) {
      widget.onFileChanged(null);
    }
  }

  void _applyUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _imageUrl = url;
      _imageBytes = null;
    });

    widget.onUrlChanged(url);
    widget.onFileChanged(null);
  }

  void _clearImage() {
    setState(() {
      _imageUrl = null;
      _imageBytes = null;
      _urlController.clear();
    });

    widget.onUrlChanged(null);
    widget.onFileChanged(null);
  }
}
