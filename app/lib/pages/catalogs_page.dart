import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/opds/opds_browser.dart';
import 'package:papyrus/opds/opds_catalogs.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/opds/catalog_editor.dart';
import 'package:papyrus/widgets/opds/opds_feed_view.dart';
import 'package:papyrus/widgets/opds/opds_download_panel.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';
import 'package:provider/provider.dart';

class CatalogsPage extends StatefulWidget {
  const CatalogsPage({super.key, this.catalogId, this.feedUri, this.query = '', this.httpClient});
  final String? catalogId;
  final Uri? feedUri;
  final String query;
  final OpdsHttpClient? httpClient;
  @override
  State<CatalogsPage> createState() => _CatalogsPageState();
}

class _CatalogsPageState extends State<CatalogsPage> {
  late final _browser = OpdsBrowser(httpClient: widget.httpClient);
  late final _search = TextEditingController(text: widget.query);
  OpdsCredentials? _credentials;
  String? _loadKey;
  bool _searching = false;
  bool _isGridView = true;

  @override
  void didUpdateWidget(covariant CatalogsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _search.text = widget.query;
  }

  void _scheduleLoad(OpdsCatalogs catalogs) {
    final key = '${catalogs.scope}/${catalogs.revision}/${widget.catalogId}/${widget.feedUri}';
    if (_loadKey == key) return;
    _loadKey = key;
    _credentials = null;
    _browser.clear();
    final catalog = widget.catalogId == null ? null : catalogs.find(widget.catalogId!);
    if (catalog == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _loadKey != key) return;
      try {
        final credentials = await catalogs.credentials(catalog.id);
        if (!mounted || _loadKey != key) return;
        _credentials = credentials;
        await _browser.load(catalog, widget.feedUri ?? catalog.uri, credentials: credentials);
      } catch (error) {
        if (mounted && _loadKey == key) setState(() => _browser.error = opdsErrorMessage(error));
      }
    });
  }

  Future<void> _edit(OpdsCatalogs catalogs, [OpdsCatalog? catalog]) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    animationStyle: AppMotion.animationStyle(context),
    builder: (_) => CatalogEditor(catalogs: catalogs, catalog: catalog),
  );

  Future<void> _remove(OpdsCatalogs catalogs, OpdsCatalog catalog) async {
    final scope = catalogs.scope;
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.animationStyle(context),
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${catalog.name}?'),
        content: const Text(
          'The saved catalog and its credentials will be removed. Downloaded books stay in your library.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted || catalogs.scope != scope) return;
    try {
      await catalogs.remove(catalog.id);
    } catch (error) {
      if (mounted) _message(opdsErrorMessage(error));
    }
  }

  void _navigate(OpdsCatalog catalog, Uri uri, {String query = ''}) {
    try {
      OpdsHttpClient.validateUri(uri);
      context.go(
        Uri(
          path: '/library/catalogs/${Uri.encodeComponent(catalog.id)}',
          queryParameters: {'feed': uri.toString(), if (query.isNotEmpty) 'q': query},
        ).toString(),
      );
    } catch (error) {
      _message(opdsErrorMessage(error));
    }
  }

  Future<void> _submitSearch(OpdsCatalog catalog) async {
    if (_searching || _search.text.trim().isEmpty) return;
    final key = _loadKey;
    final query = _search.text.trim();
    setState(() => _searching = true);
    try {
      final uri = await _browser.search(query);
      if (mounted && key == _loadKey) _navigate(catalog, uri, query: query);
    } catch (error) {
      if (mounted && key == _loadKey) _message(opdsErrorMessage(error));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _download(OpdsCatalog catalog, OpdsPublication publication, OpdsLink link) async {
    final catalogs = context.read<OpdsCatalogs>();
    final downloads = context.read<OpdsDownloads>();
    final scope = catalogs.scope;
    final revision = catalogs.revision;
    if (!identical(catalogs.find(catalog.id), catalog)) {
      _message('The catalog or account changed. Close these details and reopen the book.');
      return;
    }
    try {
      final credentials = await catalogs.credentials(catalog.id);
      if (!mounted || catalogs.scope != scope || catalogs.revision != revision) return;
      await downloads.start(catalog, publication, link, credentials: credentials);
    } catch (error) {
      if (mounted) _message(opdsErrorMessage(error));
    }
  }

  void _message(String text) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(snackBarAnimationStyle: AppMotion.animationStyle(context), SnackBar(content: Text(text)));

  @override
  void dispose() {
    _browser.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogs = context.watch<OpdsCatalogs>();
    final downloads = context.watch<OpdsDownloads>();
    _scheduleLoad(catalogs);
    final catalog = widget.catalogId == null ? null : catalogs.find(widget.catalogId!);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1344),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? Spacing.md : Spacing.xl,
                      compact ? Spacing.md : Spacing.lg,
                      compact ? Spacing.md : Spacing.xl,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(catalogs, catalog),
                        const SizedBox(height: Spacing.lg),
                        if (catalog != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: TextField(
                                controller: _search,
                                onSubmitted: (_) => _submitSearch(catalog),
                                onChanged: (_) => setState(() {}),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Search this catalog',
                                  prefixIcon: const Icon(Icons.search),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.md,
                                    vertical: Spacing.sm,
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_search.text.isNotEmpty)
                                        IconButton(
                                          tooltip: 'Clear search',
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() => _search.clear());
                                            if (widget.query.isNotEmpty) _navigate(catalog, catalog.uri);
                                          },
                                        ),
                                      IconButton(
                                        tooltip: 'Search catalog',
                                        onPressed: _searching ? null : () => _submitSearch(catalog),
                                        icon: _searching
                                            ? const SizedBox.square(
                                                dimension: 20,
                                                child: AppCircularProgressIndicator(),
                                              )
                                            : const Icon(Icons.arrow_forward),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: catalog == null
                              ? _catalogList(catalogs)
                              : AnimatedBuilder(animation: _browser, builder: (_, _) => _feedView(catalog)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            OpdsDownloadPanel(
              downloads: downloads,
              allowExpansion: constraints.maxHeight >= 480,
              maxExpandedHeight: constraints.maxHeight * 0.28,
              onRetry: (job) => unawaited(_download(job.catalog, job.publication, job.link)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(OpdsCatalogs catalogs, OpdsCatalog? catalog) {
    final theme = Theme.of(context);
    final mobile = MediaQuery.sizeOf(context).width < Breakpoints.desktopSmall;
    return Row(
      children: [
        if (mobile)
          IconButton(
            tooltip: 'Library sections',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
          ),
        if (widget.catalogId != null)
          IconButton(
            tooltip: 'All catalogs',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/library/catalogs'),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                catalog?.name ?? 'Catalogs',
                style: theme.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                catalog?.uri.host ?? 'Discover books from your favorite libraries.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.sm),
        if (catalog == null && widget.catalogId == null)
          if (mobile)
            IconButton(
              tooltip: 'Add catalog',
              onPressed: catalogs.scope == null ? null : () => _edit(catalogs),
              icon: const Icon(Icons.add),
            )
          else
            FilledButton.icon(
              onPressed: catalogs.scope == null ? null : () => _edit(catalogs),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              icon: const Icon(Icons.add),
              label: const Text('Add catalog'),
            ),
        if (catalog != null) ...[
          IconButton(
            tooltip: 'Catalog home',
            onPressed: () => _navigate(catalog, catalog.uri),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Edit catalog',
            onPressed: () => _edit(catalogs, catalog),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ],
    );
  }

  Widget _catalogList(OpdsCatalogs catalogs) {
    if (catalogs.error != null) {
      return _empty(
        'Could not load catalogs',
        detail: catalogs.error,
        action: 'Retry',
        onAction: catalogs.reload,
        icon: Icons.cloud_off_outlined,
      );
    }
    if (catalogs.scope == null) return const Center(child: Text('Waiting for your library…'));
    if (widget.catalogId != null) {
      return _empty(
        'Catalog unavailable',
        detail: 'This catalog is not saved for the active account.',
        action: 'All catalogs',
        onAction: () => context.go('/library/catalogs'),
      );
    }
    if (catalogs.catalogs.isEmpty) {
      return _empty(
        'No catalogs yet',
        detail: 'Connect an OPDS catalog to explore its collection and add books to your library.',
        action: 'Add catalog',
        onAction: () => _edit(catalogs),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (constraints.maxWidth / 360).floor().clamp(1, 3),
          mainAxisExtent: 176 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
          crossAxisSpacing: Spacing.md,
          mainAxisSpacing: Spacing.md,
        ),
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        itemCount: catalogs.catalogs.length,
        itemBuilder: (_, index) {
          final catalog = catalogs.catalogs[index];
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/library/catalogs/${Uri.encodeComponent(catalog.id)}'),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.public, color: Theme.of(context).colorScheme.primary, size: 28),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: 'Catalog options',
                          onSelected: (value) =>
                              value == 'edit' ? _edit(catalogs, catalog) : _remove(catalogs, catalog),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'remove', child: Text('Remove')),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      catalog.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            catalog.uri.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: IconSizes.small),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _feedView(OpdsCatalog catalog) {
    if (_browser.loading) return const Center(child: AppCircularProgressIndicator());
    if (_browser.error != null) {
      return _empty(
        'Could not open this catalog',
        detail: _browser.error,
        action: 'Retry',
        onAction: () => setState(() => _loadKey = null),
        icon: Icons.cloud_off_outlined,
      );
    }
    final feed = _browser.feed;
    if (feed == null) return const SizedBox.shrink();
    return OpdsFeedView(
      catalog: catalog,
      feed: feed,
      credentials: _credentials,
      httpClient: _browser.httpClient,
      query: widget.query,
      isGridView: _isGridView,
      onViewChanged: (value) => setState(() => _isGridView = value),
      onNavigate: (uri) => _navigate(catalog, uri),
      onPage: (uri) => _navigate(catalog, uri, query: widget.query),
      onRefresh: () => setState(() => _loadKey = null),
      onDownload: (publication, link) => unawaited(_download(catalog, publication, link)),
    );
  }

  Widget _empty(
    String title, {
    String? detail,
    required String action,
    required VoidCallback onAction,
    IconData icon = Icons.local_library_outlined,
  }) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: Spacing.lg),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: Spacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                child: Text(action),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
