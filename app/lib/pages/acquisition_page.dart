import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/acquisition/acquisition_api_client.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/auth/papyrus_api_config.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/acquisition_downloads_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/acquisition/acquisition_action_sheets.dart';
import 'package:papyrus/widgets/acquisition/acquisition_endpoint_editor.dart';
import 'package:papyrus/widgets/acquisition/acquisition_settings_section.dart';
import 'package:papyrus/widgets/settings/settings_row.dart';
import 'package:provider/provider.dart';

typedef AcquisitionApiClientFactory = AcquisitionApiClient Function(PapyrusApiConfig config);

class AcquisitionPage extends StatefulWidget {
  final AcquisitionApiClientFactory? clientFactory;

  const AcquisitionPage({super.key, this.clientFactory});

  @override
  State<AcquisitionPage> createState() => _AcquisitionPageState();
}

class _AcquisitionPageState extends State<AcquisitionPage> {
  AcquisitionApiClient? _client;
  Uri? _clientBaseUri;
  AcquisitionCapabilities? _capabilities;
  List<AcquisitionEndpoint> _endpoints = [];
  final Set<String> _submittingKeys = {};
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final config = context.read<SyncSettingsProvider>().activeApiConfig;
    if (_clientBaseUri == config.serverBaseUri) return;
    _client?.close();
    _client = widget.clientFactory?.call(config) ?? AcquisitionApiClient(config: config);
    _clientBaseUri = config.serverBaseUri;
    _load();
  }

  @override
  void dispose() {
    _client?.close();
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
      setState(() {
        _capabilities = capabilities;
        _endpoints = endpoints;
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
    return showAcquisitionCommandSheet(
      context: context,
      endpointName: endpoint.name,
      endpointKindLabel: endpoint.kind.label,
      commands: commands,
      commandLabel: _arrCommandLabel,
    );
  }

  Future<List<int>?> _askForIds(String command) {
    return showAcquisitionIdsSheet(context: context, title: _arrCommandLabel(command));
  }

  Future<void> _showEndpointSheet({AcquisitionEndpoint? endpoint, List<AcquisitionEndpointKind>? allowedKinds}) async {
    final capabilities = _capabilities;
    if (capabilities == null || capabilities.endpointKinds.isEmpty) return;
    final endpointKinds = allowedKinds ?? capabilities.endpointKinds;
    if (endpointKinds.isEmpty) return;
    final downloadsProvider = context.read<AcquisitionDownloadsProvider?>();

    final saved = await showAcquisitionEndpointEditor(
      context: context,
      endpoint: endpoint,
      endpointKinds: endpointKinds,
      initialKind: endpoint == null ? endpointKinds.first : null,
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
      onSave:
          ({
            required name,
            required kind,
            required baseUrl,
            required enabled,
            downloadRoot,
            apiKey,
            username,
            password,
          }) async {
            await _authenticated((token) async {
              if (endpoint == null) {
                await _apiClient.createEndpoint(
                  accessToken: token,
                  name: name,
                  kind: kind,
                  baseUrl: baseUrl,
                  downloadRoot: downloadRoot,
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
                downloadRoot: downloadRoot,
                apiKey: apiKey,
                username: username,
                password: password,
                enabled: enabled,
              );
            });
          },
    );

    if (saved == true) {
      await _load();
      await downloadsProvider?.refreshConfiguration();
    }
  }

  Future<void> _deleteEndpoint(AcquisitionEndpoint endpoint) async {
    final downloadsProvider = context.read<AcquisitionDownloadsProvider?>();
    final confirmed = await showAcquisitionRemoveDialog(context: context, endpointName: endpoint.name);
    if (confirmed != true) return;

    try {
      await _authenticated((token) {
        return _apiClient.deleteEndpoint(accessToken: token, endpointId: endpoint.id);
      });
      await _load();
      await downloadsProvider?.refreshConfiguration();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not remove this integration.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _capabilities;
    final indexers = _endpoints.where((endpoint) => endpoint.kind.isIndexer).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Acquisition')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loading) const LinearProgressIndicator(),
                    if (_submittingKeys.isNotEmpty) const LinearProgressIndicator(),
                    if (_error != null) _ErrorBanner(message: _error!, onRetry: _load),
                    if (!_loading && _error == null && capabilities != null)
                      ..._buildSettingsSections(capabilities: capabilities, indexers: indexers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSettingsSections({
    required AcquisitionCapabilities capabilities,
    required List<AcquisitionEndpoint> indexers,
  }) {
    final downloadClients = _endpoints.where((endpoint) => endpoint.kind.isDownloadClient).toList();
    final arrApps = _endpoints.where((endpoint) => endpoint.kind.isArr).toList();

    return [
      _buildIntegrationSettingsSection(
        key: const Key('acquisition-sources-section'),
        title: 'Sources',
        emptyMessage: 'No sources configured',
        endpoints: indexers,
        addKinds: capabilities.indexerKinds,
      ),
      const SizedBox(height: Spacing.md),
      _buildIntegrationSettingsSection(
        key: const Key('acquisition-clients-section'),
        title: 'Download clients',
        emptyMessage: 'No download clients configured',
        endpoints: downloadClients,
        addKinds: capabilities.downloadClientKinds,
      ),
      const SizedBox(height: Spacing.md),
      _buildIntegrationSettingsSection(
        key: const Key('acquisition-apps-section'),
        title: 'Connected apps',
        emptyMessage: 'No connected apps configured',
        endpoints: arrApps,
        addKinds: capabilities.arrKinds,
        allowRun: true,
      ),
    ];
  }

  Widget _buildIntegrationSettingsSection({
    required Key key,
    required String title,
    required String emptyMessage,
    required List<AcquisitionEndpoint> endpoints,
    required List<AcquisitionEndpointKind> addKinds,
    bool allowRun = false,
  }) {
    return AcquisitionSettingsSection(
      key: key,
      title: title,
      emptyMessage: emptyMessage,
      onAdd: addKinds.isEmpty ? null : () => _showEndpointSheet(allowedKinds: addKinds),
      children: endpoints
          .map(
            (endpoint) => SettingsRow(
              key: Key('acquisition-endpoint-${endpoint.id}'),
              label: endpoint.name,
              value: '${endpoint.kind.label} • ${endpoint.baseUrl.host} • ${endpoint.enabled ? 'Enabled' : 'Paused'}',
              leading: Icon(_iconFor(endpoint.kind)),
              onTap: () => _showEndpointSheet(endpoint: endpoint),
              trailing: _buildEndpointMenu(endpoint, allowRun: allowRun),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEndpointMenu(AcquisitionEndpoint endpoint, {required bool allowRun}) {
    final runEnabled = endpoint.enabled && !_submittingKeys.contains('arr:${endpoint.id}');

    return PopupMenuButton<String>(
      tooltip: 'Actions for ${endpoint.name}',
      onSelected: (value) {
        if (value == 'edit') _showEndpointSheet(endpoint: endpoint);
        if (value == 'run' && runEnabled) _runArrCommand(endpoint);
        if (value == 'delete') _deleteEndpoint(endpoint);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (allowRun) PopupMenuItem(value: 'run', enabled: runEnabled, child: const Text('Run action')),
        const PopupMenuItem(value: 'delete', child: Text('Remove')),
      ],
    );
  }

  String _messageFor(AuthApiException error) {
    if (error.statusCode == 404) {
      return 'This Papyrus server does not expose the torrent acquisition API.';
    }
    return error.message;
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

  IconData _iconFor(AcquisitionEndpointKind kind) => switch (kind) {
    AcquisitionEndpointKind.qbittorrent ||
    AcquisitionEndpointKind.transmission ||
    AcquisitionEndpointKind.deluge => Icons.downloading_outlined,
    AcquisitionEndpointKind.prowlarr || AcquisitionEndpointKind.torznab => Icons.travel_explore,
    _ => Icons.auto_awesome_motion_outlined,
  };
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
