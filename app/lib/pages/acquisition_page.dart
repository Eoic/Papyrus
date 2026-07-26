import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/acquisition/acquisition_api_client.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:provider/provider.dart';

typedef AcquisitionApiClientFactory = AcquisitionApiClient Function(PapyrusApiConfig config);

class AcquisitionPage extends StatefulWidget {
  final AcquisitionApiClientFactory? clientFactory;

  const AcquisitionPage({super.key, this.clientFactory});

  @override
  State<AcquisitionPage> createState() => _AcquisitionPageState();
}

class _AcquisitionPageState extends State<AcquisitionPage> {
  final _queryController = TextEditingController();
  AcquisitionApiClient? _client;
  Uri? _clientBaseUri;
  AcquisitionCapabilities? _capabilities;
  List<AcquisitionEndpoint> _endpoints = [];
  List<TorrentRelease> _releases = [];
  Set<String> _selectedIndexerIds = {};
  final Set<String> _submittingKeys = {};
  bool _hasExplicitIndexerSelection = false;
  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final config = context.read<SyncSettingsProvider>().activeApiConfig;
    if (_clientBaseUri == config.serverBaseUri) return;
    _client?.close();
    _client = widget.clientFactory?.call(config) ?? AcquisitionApiClient(config: config);
    _clientBaseUri = config.serverBaseUri;
    _selectedIndexerIds = {};
    _hasExplicitIndexerSelection = false;
    _load();
  }

  @override
  void dispose() {
    _client?.close();
    _queryController.dispose();
    super.dispose();
  }

  AcquisitionApiClient get _apiClient => _client!;

  Future<T> _authenticated<T>(Future<T> Function(String accessToken) action) {
    return context.read<AuthProvider>().withFreshAccessToken(action);
  }

  Future<void> _load() async {
    if (!context.read<PreferencesProvider>().acquisitionEnabled) {
      context.go('/profile');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final capabilities = await _authenticated(_apiClient.capabilities);
      final endpoints = await _authenticated(_apiClient.listEndpoints);
      if (!mounted) return;
      final enabledIndexerIds = endpoints
          .where((endpoint) => endpoint.enabled && endpoint.kind.isIndexer)
          .map((endpoint) => endpoint.id)
          .toSet();
      setState(() {
        _capabilities = capabilities;
        _endpoints = endpoints;
        if (_hasExplicitIndexerSelection) {
          _selectedIndexerIds = _selectedIndexerIds.intersection(enabledIndexerIds);
        } else {
          _selectedIndexerIds = enabledIndexerIds;
        }
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'This Papyrus server does not expose the torrent acquisition API.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    final indexerIds = _endpoints
        .where((endpoint) => endpoint.enabled && endpoint.kind.isIndexer && _selectedIndexerIds.contains(endpoint.id))
        .map((endpoint) => endpoint.id)
        .toList();
    final hasClient = _endpoints.any((endpoint) => endpoint.enabled && endpoint.kind.isDownloadClient);
    if (query.isEmpty || _capabilities == null || indexerIds.isEmpty || !hasClient) return;

    setState(() {
      _searching = true;
      _error = null;
      _releases = [];
    });

    try {
      final releases = await _authenticated((token) {
        return _apiClient.search(accessToken: token, query: query, endpointIds: indexerIds);
      });
      if (mounted) setState(() => _releases = releases);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Search failed. Check your torrent indexers.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submitRelease(TorrentRelease release, AcquisitionEndpoint client) async {
    final submissionKey = _submissionKey(release, client);
    if (_submittingKeys.contains(submissionKey)) return;

    setState(() => _submittingKeys.add(submissionKey));
    try {
      final job = await _authenticated((token) {
        return _apiClient.submitRelease(accessToken: token, endpointId: client.id, release: release);
      });
      if (!mounted) return;

      _showMessage(job.isSubmitted ? 'Sent to ${client.name}.' : job.error ?? 'Submission failed.');
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not submit this release.');
    } finally {
      if (mounted) setState(() => _submittingKeys.remove(submissionKey));
    }
  }

  Future<void> _runArrCommand(AcquisitionEndpoint endpoint) async {
    final capabilities = _capabilities;
    final commands = capabilities?.arrCommands[endpoint.kind] ?? const [];
    if (commands.isEmpty) return;

    final command = await _pickArrCommand(endpoint, commands);
    if (command == null) return;

    final ids = await _askForIds(command);
    if (ids == null) return;

    final submissionKey = 'arr:${endpoint.id}';
    if (_submittingKeys.contains(submissionKey)) return;

    setState(() => _submittingKeys.add(submissionKey));
    try {
      final job = await _authenticated((token) {
        return _apiClient.runArrCommand(accessToken: token, endpointId: endpoint.id, command: command, ids: ids);
      });
      if (!mounted) return;

      _showMessage(job.isSubmitted ? '$command sent to ${endpoint.name}.' : job.error ?? 'Arr action failed.');
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not run this Arr action.');
    } finally {
      if (mounted) setState(() => _submittingKeys.remove(submissionKey));
    }
  }

  Future<String?> _pickArrCommand(AcquisitionEndpoint endpoint, List<String> commands) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(endpoint.name), subtitle: Text(endpoint.kind.label)),
            ...commands.map(
              (command) => ListTile(
                leading: const Icon(Icons.play_arrow_outlined),
                title: Text(_arrCommandLabel(command)),
                subtitle: Text(command),
                onTap: () => Navigator.pop(context, command),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>?> _askForIds(String command) async {
    final controller = TextEditingController();
    try {
      return showDialog<List<int>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_arrCommandLabel(command)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'IDs',
              helperText: 'Comma-separated IDs from the Arr application',
            ),
            keyboardType: TextInputType.text,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final ids = controller.text
                    .split(',')
                    .map((value) => int.tryParse(value.trim()))
                    .whereType<int>()
                    .toList();
                Navigator.pop(context, ids);
              },
              child: const Text('Run'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showEndpointDialog({AcquisitionEndpoint? endpoint}) async {
    final capabilities = _capabilities;
    if (capabilities == null || capabilities.endpointKinds.isEmpty) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _EndpointDialog(
        endpoint: endpoint,
        endpointKinds: capabilities.endpointKinds,
        onTest: ({required kind, required baseUrl, apiKey, username, password}) {
          return _authenticated((token) {
            return _apiClient.testEndpoint(
              accessToken: token,
              endpointId: endpoint?.id,
              kind: endpoint == null ? kind : null,
              baseUrl: baseUrl,
              apiKey: apiKey,
              username: username,
              password: password,
            );
          });
        },
        onSave: ({required name, required kind, required baseUrl, required enabled, apiKey, username, password}) async {
          await _authenticated((token) async {
            if (endpoint == null) {
              await _apiClient.createEndpoint(
                accessToken: token,
                name: name,
                kind: kind,
                baseUrl: baseUrl,
                apiKey: apiKey,
                username: username,
                password: password,
              );
              return;
            }

            await _apiClient.updateEndpoint(
              accessToken: token,
              endpointId: endpoint.id,
              name: name,
              baseUrl: baseUrl,
              apiKey: apiKey,
              username: username,
              password: password,
              enabled: enabled,
            );
          });
        },
      ),
    );

    if (saved == true) await _load();
  }

  Future<void> _deleteEndpoint(AcquisitionEndpoint endpoint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${endpoint.name}?'),
        content: const Text('Saved credentials for this integration will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _authenticated((token) {
        return _apiClient.deleteEndpoint(accessToken: token, endpointId: endpoint.id);
      });
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not remove this integration.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _capabilities;
    final clients = _endpoints.where((endpoint) => endpoint.enabled && endpoint.kind.isDownloadClient).toList();
    final indexers = _endpoints.where((endpoint) => endpoint.kind.isIndexer).toList();
    final enabledIndexers = indexers.where((endpoint) => endpoint.enabled).toList();
    final arrApps = _endpoints.where((endpoint) => endpoint.kind.isArr).toList();
    final canSearch =
        clients.isNotEmpty && enabledIndexers.any((endpoint) => _selectedIndexerIds.contains(endpoint.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Torrent acquisition')),
      floatingActionButton: capabilities == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEndpointDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Integration'),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_submittingKeys.isNotEmpty) const LinearProgressIndicator(),
            if (_error != null) _ErrorBanner(message: _error!, onRetry: _load),
            if (!_loading && _error == null) ...[
              _SearchCard(
                queryController: _queryController,
                searching: _searching,
                canSearch: canSearch,
                indexers: enabledIndexers,
                selectedIndexerIds: _selectedIndexerIds,
                hasEnabledClient: clients.isNotEmpty,
                onIndexerSelected: _setIndexerSelected,
                onSearch: _search,
              ),
              const SizedBox(height: Spacing.md),
              _EndpointSection(
                title: 'Torrent indexers',
                emptyLabel: 'No torrent indexers configured',
                endpoints: indexers,
                onEdit: (endpoint) => _showEndpointDialog(endpoint: endpoint),
                onDelete: _deleteEndpoint,
              ),
              _EndpointSection(
                title: 'Download clients',
                emptyLabel: 'No download clients configured',
                endpoints: _endpoints.where((endpoint) => endpoint.kind.isDownloadClient).toList(),
                onEdit: (endpoint) => _showEndpointDialog(endpoint: endpoint),
                onDelete: _deleteEndpoint,
              ),
              _ArrSection(
                endpoints: arrApps,
                submittingKeys: _submittingKeys,
                onRun: _runArrCommand,
                onEdit: (endpoint) => _showEndpointDialog(endpoint: endpoint),
                onDelete: _deleteEndpoint,
              ),
              if (_releases.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                Text('Results', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                ..._releases.map(
                  (release) => _ReleaseTile(
                    release: release,
                    clients: clients,
                    submittingKeys: _submittingKeys,
                    onSubmit: _submitRelease,
                  ),
                ),
              ] else if (!_searching && _queryController.text.trim().isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: Spacing.md),
                  child: Text('No releases found.'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _messageFor(AuthApiException error) {
    if (error.statusCode == 404) {
      return 'This Papyrus server does not expose the torrent acquisition API.';
    }
    return error.message;
  }

  void _setIndexerSelected(AcquisitionEndpoint endpoint, bool selected) {
    setState(() {
      _hasExplicitIndexerSelection = true;
      if (selected) {
        _selectedIndexerIds.add(endpoint.id);
      } else {
        _selectedIndexerIds.remove(endpoint.id);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _arrCommandLabel(String command) => switch (command) {
    'AuthorSearch' => 'Search authors',
    'BookSearch' => 'Search books',
    'SeriesSearch' => 'Search series',
    'EpisodeSearch' => 'Search episodes',
    'MissingEpisodeSearch' => 'Search missing episodes',
    'MoviesSearch' => 'Search movies',
    'MissingMoviesSearch' => 'Search missing movies',
    'ArtistSearch' => 'Search artists',
    'AlbumSearch' => 'Search albums',
    'MissingAlbumSearch' => 'Search missing albums',
    _ => command,
  };
}

typedef _EndpointTestCallback =
    Future<void> Function({
      required AcquisitionEndpointKind kind,
      required Uri baseUrl,
      String? apiKey,
      String? username,
      String? password,
    });

typedef _EndpointSaveCallback =
    Future<void> Function({
      required String name,
      required AcquisitionEndpointKind kind,
      required Uri baseUrl,
      required bool enabled,
      String? apiKey,
      String? username,
      String? password,
    });

class _EndpointDialog extends StatefulWidget {
  const _EndpointDialog({
    required this.endpoint,
    required this.endpointKinds,
    required this.onTest,
    required this.onSave,
  });

  final AcquisitionEndpoint? endpoint;
  final List<AcquisitionEndpointKind> endpointKinds;
  final _EndpointTestCallback onTest;
  final _EndpointSaveCallback onSave;

  @override
  State<_EndpointDialog> createState() => _EndpointDialogState();
}

class _EndpointDialogState extends State<_EndpointDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  final _apiKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AcquisitionEndpointKind _kind;
  late bool _enabled;
  bool _testing = false;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  bool get _busy => _testing || _saving;

  bool get _usesApiKey => _kind.isIndexer || _kind.isArr;

  bool get _usesUsername =>
      _kind == AcquisitionEndpointKind.qbittorrent || _kind == AcquisitionEndpointKind.transmission;

  bool get _usesPassword => _usesUsername || _kind == AcquisitionEndpointKind.deluge;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.endpoint?.name ?? '');
    _urlController = TextEditingController(text: widget.endpoint?.baseUrl.toString() ?? '');
    _kind = widget.endpoint?.kind ?? widget.endpointKinds.first;
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.endpoint == null ? 'Add integration' : 'Edit integration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            DropdownButtonFormField<AcquisitionEndpointKind>(
              initialValue: _kind,
              items: widget.endpointKinds
                  .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                  .toList(),
              onChanged: widget.endpoint == null && !_busy ? (value) => setState(() => _kind = value ?? _kind) : null,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            TextField(
              controller: _urlController,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Server URL'),
              keyboardType: TextInputType.url,
            ),
            if (_usesApiKey)
              TextField(
                controller: _apiKeyController,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'API key'),
              ),
            if (_usesUsername)
              TextField(
                controller: _usernameController,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            if (_usesPassword)
              TextField(
                controller: _passwordController,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: _busy ? null : (value) => setState(() => _enabled = value),
            ),
            if (_testing) const LinearProgressIndicator(),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(_message!, style: TextStyle(color: _messageIsError ? colorScheme.error : null)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        OutlinedButton(
          key: const Key('acquisition-test-connection'),
          onPressed: _busy ? null : _testConnection,
          child: const Text('Test connection'),
        ),
        FilledButton(key: const Key('acquisition-save'), onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }

  Future<void> _testConnection() async {
    final baseUrl = _baseUrl();
    if (baseUrl == null) return;

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
    final name = _nameController.text.trim();
    final baseUrl = _baseUrl();
    if (name.isEmpty || baseUrl == null) {
      if (name.isEmpty) {
        setState(() {
          _message = 'Name is required.';
          _messageIsError = true;
        });
      }
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await widget.onSave(
        name: name,
        kind: _kind,
        baseUrl: baseUrl,
        enabled: _enabled,
        apiKey: _usesApiKey ? _optional(_apiKeyController.text) : null,
        username: _usesUsername ? _optional(_usernameController.text) : null,
        password: _usesPassword ? _optional(_passwordController.text) : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is AuthApiException ? error.message : 'Could not save this integration.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Uri? _baseUrl() {
    final baseUrl = Uri.tryParse(_urlController.text.trim());
    if (baseUrl == null || !baseUrl.hasScheme || !baseUrl.hasAuthority || baseUrl.userInfo.isNotEmpty) {
      setState(() {
        _message = 'Enter a valid server URL without embedded credentials.';
        _messageIsError = true;
      });
      return null;
    }
    return baseUrl;
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.queryController,
    required this.searching,
    required this.canSearch,
    required this.indexers,
    required this.selectedIndexerIds,
    required this.hasEnabledClient,
    required this.onIndexerSelected,
    required this.onSearch,
  });

  final TextEditingController queryController;
  final bool searching;
  final bool canSearch;
  final List<AcquisitionEndpoint> indexers;
  final Set<String> selectedIndexerIds;
  final bool hasEnabledClient;
  final void Function(AcquisitionEndpoint endpoint, bool selected) onIndexerSelected;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search torrents', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            if (indexers.isNotEmpty) ...[
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.xs,
                children: indexers
                    .map(
                      (endpoint) => FilterChip(
                        label: Text(endpoint.name),
                        selected: selectedIndexerIds.contains(endpoint.id),
                        onSelected: searching ? null : (selected) => onIndexerSelected(endpoint, selected),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            TextField(
              controller: queryController,
              enabled: canSearch && !searching,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                labelText: 'Title, author, movie, album, or series',
                suffixIcon: searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(icon: const Icon(Icons.search), onPressed: canSearch ? onSearch : null),
              ),
            ),
            if (!canSearch)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(
                  indexers.isEmpty
                      ? 'Add an enabled Prowlarr or Torznab indexer first.'
                      : !hasEnabledClient
                      ? 'Add an enabled download client before searching.'
                      : 'Select at least one torrent indexer.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EndpointSection extends StatelessWidget {
  const _EndpointSection({
    required this.title,
    required this.emptyLabel,
    required this.endpoints,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String emptyLabel;
  final List<AcquisitionEndpoint> endpoints;
  final ValueChanged<AcquisitionEndpoint> onEdit;
  final ValueChanged<AcquisitionEndpoint> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          if (endpoints.isEmpty)
            Card(
              child: ListTile(leading: const Icon(Icons.info_outline), title: Text(emptyLabel)),
            )
          else
            ...endpoints.map((endpoint) => _EndpointTile(endpoint: endpoint, onEdit: onEdit, onDelete: onDelete)),
        ],
      ),
    );
  }
}

class _ArrSection extends StatelessWidget {
  const _ArrSection({
    required this.endpoints,
    required this.submittingKeys,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AcquisitionEndpoint> endpoints;
  final Set<String> submittingKeys;
  final ValueChanged<AcquisitionEndpoint> onRun;
  final ValueChanged<AcquisitionEndpoint> onEdit;
  final ValueChanged<AcquisitionEndpoint> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Arr applications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          if (endpoints.isEmpty)
            const Card(
              child: ListTile(leading: Icon(Icons.info_outline), title: Text('No Arr applications configured')),
            )
          else
            ...endpoints.map(
              (endpoint) => _EndpointTile(
                endpoint: endpoint,
                onEdit: onEdit,
                onDelete: onDelete,
                trailingAction: IconButton(
                  tooltip: 'Run action',
                  icon: const Icon(Icons.play_arrow_outlined),
                  onPressed: endpoint.enabled && !submittingKeys.contains('arr:${endpoint.id}')
                      ? () => onRun(endpoint)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.endpoint, required this.onEdit, required this.onDelete, this.trailingAction});

  final AcquisitionEndpoint endpoint;
  final ValueChanged<AcquisitionEndpoint> onEdit;
  final ValueChanged<AcquisitionEndpoint> onDelete;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_iconFor(endpoint.kind)),
        title: Text(endpoint.name),
        subtitle: Text('${endpoint.kind.label} • ${endpoint.baseUrl.host}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailingAction,
            Icon(
              endpoint.enabled ? Icons.check_circle_outline : Icons.pause_circle_outline,
              color: endpoint.enabled ? Theme.of(context).colorScheme.primary : null,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit(endpoint);
                if (value == 'delete') onDelete(endpoint);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AcquisitionEndpointKind kind) => switch (kind) {
    AcquisitionEndpointKind.qbittorrent ||
    AcquisitionEndpointKind.transmission ||
    AcquisitionEndpointKind.deluge => Icons.downloading_outlined,
    AcquisitionEndpointKind.prowlarr || AcquisitionEndpointKind.torznab => Icons.travel_explore,
    _ => Icons.auto_awesome_motion_outlined,
  };
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({
    required this.release,
    required this.clients,
    required this.submittingKeys,
    required this.onSubmit,
  });

  final TorrentRelease release;
  final List<AcquisitionEndpoint> clients;
  final Set<String> submittingKeys;
  final void Function(TorrentRelease release, AcquisitionEndpoint client) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(release.title),
        subtitle: Text(
          [
            release.indexer,
            if (release.seeders != null) '${release.seeders} seeders',
            if (release.sizeBytes != null) _formatBytes(release.sizeBytes!),
            if (release.isMagnet) 'magnet',
          ].join(' • '),
        ),
        trailing: PopupMenuButton<AcquisitionEndpoint>(
          enabled: clients.any((client) => !submittingKeys.contains(_submissionKey(release, client))),
          icon: const Icon(Icons.send_outlined),
          tooltip: 'Send to client',
          itemBuilder: (context) => clients.map((client) {
            final key = _submissionKey(release, client);
            return PopupMenuItem(
              key: Key('submission:$key'),
              value: client,
              enabled: !submittingKeys.contains(key),
              child: Text(client.name),
            );
          }).toList(),
          onSelected: (client) => onSubmit(release, client),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

String _submissionKey(TorrentRelease release, AcquisitionEndpoint client) {
  return '${release.downloadUrl}:${client.id}';
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
        title: Text(message, style: TextStyle(color: colorScheme.onErrorContainer)),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}
