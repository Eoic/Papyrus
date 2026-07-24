import 'package:flutter/material.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/themes/design_tokens.dart';

typedef AcquisitionEndpointTestCallback =
    Future<void> Function({
      required AcquisitionEndpointKind kind,
      required Uri baseUrl,
      String? apiKey,
      String? username,
      String? password,
    });

typedef AcquisitionEndpointSaveCallback =
    Future<void> Function({
      required String name,
      required AcquisitionEndpointKind kind,
      required Uri baseUrl,
      required bool enabled,
      String? apiKey,
      String? username,
      String? password,
    });

Future<bool?> showAcquisitionEndpointEditor({
  required BuildContext context,
  required List<AcquisitionEndpointKind> endpointKinds,
  required AcquisitionEndpointTestCallback onTest,
  required AcquisitionEndpointSaveCallback onSave,
  AcquisitionEndpoint? endpoint,
  AcquisitionEndpointKind? initialKind,
}) {
  final editor = AcquisitionEndpointEditor(
    endpoint: endpoint,
    endpointKinds: endpointKinds,
    initialKind: initialKind,
    onTest: onTest,
    onSave: onSave,
  );

  if (MediaQuery.sizeOf(context).width < Breakpoints.tablet) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => KeyedSubtree(
        key: const Key('acquisition-endpoint-sheet'),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: FractionallySizedBox(heightFactor: .92, child: editor),
        ),
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      key: const Key('acquisition-endpoint-dialog'),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760), child: editor),
    ),
  );
}

class AcquisitionEndpointEditor extends StatefulWidget {
  const AcquisitionEndpointEditor({
    required this.endpointKinds,
    required this.onTest,
    required this.onSave,
    this.endpoint,
    this.initialKind,
    super.key,
  });

  final AcquisitionEndpoint? endpoint;
  final List<AcquisitionEndpointKind> endpointKinds;
  final AcquisitionEndpointKind? initialKind;
  final AcquisitionEndpointTestCallback onTest;
  final AcquisitionEndpointSaveCallback onSave;

  @override
  State<AcquisitionEndpointEditor> createState() => _AcquisitionEndpointEditorState();
}

class _AcquisitionEndpointEditorState extends State<AcquisitionEndpointEditor> {
  final _formKey = GlobalKey<FormState>();
  final _urlFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  final _apiKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AcquisitionEndpointKind _kind;
  late bool _enabled;
  bool _showApiKey = false;
  bool _showPassword = false;
  bool _testing = false;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  bool get _busy => _testing || _saving;

  bool get _usesApiKey => _kind.isIndexer || _kind.isArr;

  bool get _usesUsername {
    return _kind == AcquisitionEndpointKind.qbittorrent || _kind == AcquisitionEndpointKind.transmission;
  }

  bool get _usesPassword => _usesUsername || _kind == AcquisitionEndpointKind.deluge;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.endpoint?.name ?? '');
    _urlController = TextEditingController(text: widget.endpoint?.baseUrl.toString() ?? '');
    _kind = widget.endpoint?.kind ?? widget.initialKind ?? widget.endpointKinds.first;
    _enabled = widget.endpoint?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.md),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.endpoint == null ? 'Add integration' : 'Edit integration',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeading(label: 'Integration'),
                      const SizedBox(height: Spacing.formFieldSpacing),
                      TextFormField(
                        key: const Key('acquisition-name'),
                        controller: _nameController,
                        enabled: !_busy,
                        decoration: const InputDecoration(labelText: 'Name'),
                        textInputAction: TextInputAction.next,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: Spacing.formFieldSpacing),
                      DropdownButtonFormField<AcquisitionEndpointKind>(
                        key: const Key('acquisition-type'),
                        initialValue: _kind,
                        items: widget.endpointKinds
                            .map((kind) => DropdownMenuItem(value: kind, child: Text(kind.label)))
                            .toList(),
                        onChanged: widget.endpoint == null && !_busy
                            ? (kind) => setState(() {
                                _kind = kind ?? _kind;
                                _message = null;
                              })
                            : null,
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: Spacing.lg),
                      _SectionHeading(label: 'Connection'),
                      const SizedBox(height: Spacing.formFieldSpacing),
                      FormField<String>(
                        key: _urlFieldKey,
                        initialValue: _urlController.text,
                        validator: _validateUrl,
                        builder: (field) {
                          return TextField(
                            key: const Key('acquisition-url'),
                            controller: _urlController,
                            enabled: !_busy,
                            decoration: InputDecoration(labelText: 'Server URL', errorText: field.errorText),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            onChanged: field.didChange,
                          );
                        },
                      ),
                      if (_usesApiKey) ...[
                        const SizedBox(height: Spacing.formFieldSpacing),
                        TextFormField(
                          key: const Key('acquisition-api-key'),
                          controller: _apiKeyController,
                          enabled: !_busy,
                          obscureText: !_showApiKey,
                          decoration: InputDecoration(
                            labelText: 'API key',
                            suffixIcon: IconButton(
                              tooltip: _showApiKey ? 'Hide API key' : 'Show API key',
                              onPressed: _busy ? null : () => setState(() => _showApiKey = !_showApiKey),
                              icon: Icon(_showApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            ),
                          ),
                        ),
                      ],
                      if (_usesUsername) ...[
                        const SizedBox(height: Spacing.formFieldSpacing),
                        TextFormField(
                          key: const Key('acquisition-username'),
                          controller: _usernameController,
                          enabled: !_busy,
                          decoration: const InputDecoration(labelText: 'Username'),
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                      if (_usesPassword) ...[
                        const SizedBox(height: Spacing.formFieldSpacing),
                        TextFormField(
                          key: const Key('acquisition-password'),
                          controller: _passwordController,
                          enabled: !_busy,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              tooltip: _showPassword ? 'Hide password' : 'Show password',
                              onPressed: _busy ? null : () => setState(() => _showPassword = !_showPassword),
                              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            ),
                          ),
                        ),
                      ],
                      if (widget.endpoint != null) ...[
                        const SizedBox(height: Spacing.formFieldSpacing),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enabled'),
                          value: _enabled,
                          onChanged: _busy ? null : (enabled) => setState(() => _enabled = enabled),
                        ),
                      ],
                      const SizedBox(height: Spacing.formFieldSpacing),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          key: const Key('acquisition-test-connection'),
                          onPressed: _busy ? null : _testConnection,
                          icon: _testing
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.cable_outlined),
                          label: const Text('Test connection'),
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: Spacing.sm),
                        Text(
                          _message!,
                          style: TextStyle(color: _messageIsError ? Theme.of(context).colorScheme.error : null),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              key: const Key('acquisition-editor-footer'),
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilledButton(
                    key: const Key('acquisition-save'),
                    onPressed: _busy ? null : _save,
                    child: _saving
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!(_urlFieldKey.currentState?.validate() ?? false)) return;

    final baseUrl = Uri.parse(_urlController.text.trim());
    setState(() {
      _testing = true;
      _message = null;
    });

    try {
      await widget.onTest(
        kind: _kind,
        baseUrl: baseUrl,
        apiKey: _usesApiKey ? _optional(_apiKeyController.text) : null,
        username: _usesUsername ? _optional(_usernameController.text) : null,
        password: _usesPassword ? _optional(_passwordController.text) : null,
      );
      if (!mounted) return;

      setState(() {
        _message = 'Connection successful.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = error is AuthApiException ? error.message : 'Could not connect to this integration.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await widget.onSave(
        name: _nameController.text.trim(),
        kind: _kind,
        baseUrl: Uri.parse(_urlController.text.trim()),
        enabled: _enabled,
        apiKey: _usesApiKey ? _optional(_apiKeyController.text) : null,
        username: _usesUsername ? _optional(_usernameController.text) : null,
        password: _usesPassword ? _optional(_passwordController.text) : null,
      );
      if (!mounted) return;

      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = error is AuthApiException ? error.message : 'Could not save this integration.';
        _messageIsError = true;
      });
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      return 'Enter a valid server URL';
    }
    return null;
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
