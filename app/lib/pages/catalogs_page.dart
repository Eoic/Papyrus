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
import 'package:papyrus/widgets/opds/opds_publication_tile.dart';
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (MediaQuery.sizeOf(context).width < Breakpoints.desktopSmall)
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
                  child: Text(
                    catalog?.name ?? 'Catalogs',
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (catalog == null && widget.catalogId == null)
                  IconButton(
                    tooltip: 'Add catalog',
                    onPressed: catalogs.scope == null ? null : () => _edit(catalogs),
                    icon: const Icon(Icons.add),
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
            ),
            const SizedBox(height: Spacing.md),
            if (downloads.jobs.isNotEmpty) _downloadsPanel(downloads),
            if (catalog != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _submitSearch(catalog),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search this catalog',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Search catalog',
                      onPressed: _searching ? null : () => _submitSearch(catalog),
                      icon: const Icon(Icons.arrow_forward),
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
    );
  }

  Widget _catalogList(OpdsCatalogs catalogs) {
    if (catalogs.error != null) return _empty(catalogs.error!, action: 'Retry', onAction: catalogs.reload);
    if (catalogs.scope == null) return const Center(child: Text('Waiting for your library…'));
    if (widget.catalogId != null) {
      return _empty(
        'This catalog is not saved for the active account.',
        action: 'All catalogs',
        onAction: () => context.go('/library/catalogs'),
      );
    }
    if (catalogs.catalogs.isEmpty) {
      return _empty(
        'No catalogs yet',
        detail: 'Add an OPDS catalog to browse and download books.',
        action: 'Add catalog',
        onAction: () => _edit(catalogs),
      );
    }
    return ListView.builder(
      itemCount: catalogs.catalogs.length,
      itemBuilder: (_, index) {
        final catalog = catalogs.catalogs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.public),
            title: Text(catalog.name),
            subtitle: Text(catalog.uri.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => context.go('/library/catalogs/${Uri.encodeComponent(catalog.id)}'),
            trailing: PopupMenuButton<String>(
              tooltip: 'Catalog options',
              onSelected: (value) => value == 'edit' ? _edit(catalogs, catalog) : _remove(catalogs, catalog),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _feedView(OpdsCatalog catalog) {
    if (_browser.loading) return const Center(child: AppCircularProgressIndicator());
    if (_browser.error != null) {
      return _empty(_browser.error!, action: 'Retry', onAction: () => setState(() => _loadKey = null));
    }
    final feed = _browser.feed;
    if (feed == null) return const SizedBox.shrink();
    final items = <Widget>[
      Row(
        children: [
          Expanded(child: Text(feed.title, style: Theme.of(context).textTheme.titleLarge)),
          IconButton(
            tooltip: 'Refresh catalog',
            onPressed: () => setState(() => _loadKey = null),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      for (final facet in feed.facets)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: [
              Text('${facet.title}:'),
              for (final link in facet.links)
                ActionChip(label: Text(link.title ?? 'Filter'), onPressed: () => _navigate(catalog, link.uri)),
            ],
          ),
        ),
      ..._entries(catalog, feed.navigation, feed.publications),
      for (final group in feed.groups) ...[
        Padding(
          padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.sm),
          child: Text(group.title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ..._entries(catalog, group.navigation, group.publications),
        for (final link in group.links.where((link) => link.hasRel('self') || link.hasRel('collection')))
          TextButton(onPressed: () => _navigate(catalog, link.uri), child: const Text('View all')),
      ],
      if (feed.navigation.isEmpty && feed.publications.isEmpty && feed.groups.isEmpty)
        const Padding(padding: EdgeInsets.all(Spacing.lg), child: Text('No books or sections found.')),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Wrap(
          spacing: Spacing.md,
          children: [
            if (feed.previousLink != null)
              OutlinedButton.icon(
                onPressed: () => _navigate(catalog, feed.previousLink!.uri, query: widget.query),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
            if (feed.nextLink != null)
              OutlinedButton.icon(
                onPressed: () => _navigate(catalog, feed.nextLink!.uri, query: widget.query),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
          ],
        ),
      ),
    ];
    return ListView.builder(key: ValueKey(feed.uri), itemCount: items.length, itemBuilder: (_, index) => items[index]);
  }

  List<Widget> _entries(OpdsCatalog catalog, List<OpdsLink> navigation, List<OpdsPublication> publications) => [
    for (final link in navigation)
      ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(link.title ?? 'Browse section'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigate(catalog, link.uri),
      ),
    for (final publication in publications)
      OpdsPublicationTile(
        catalog: catalog,
        publication: publication,
        credentials: _credentials,
        httpClient: _browser.httpClient,
        onNavigate: (uri) => _navigate(catalog, uri),
        onDownload: (link) => unawaited(_download(catalog, publication, link)),
      ),
  ];

  Widget _downloadsPanel(OpdsDownloads downloads) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 180),
    child: SingleChildScrollView(
      child: Column(
        children: [
          for (final job in downloads.jobs)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(job.publication.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                job.error ??
                    switch (job.status) {
                      OpdsDownloadStatus.downloading =>
                        job.total == null
                            ? 'Downloading · ${job.received ~/ 1024} KB'
                            : 'Downloading · ${(100 * (job.progress ?? 0)).round()}%',
                      OpdsDownloadStatus.importing => 'Importing…',
                      OpdsDownloadStatus.committing => 'Adding to library…',
                      OpdsDownloadStatus.complete => 'Added to library',
                      OpdsDownloadStatus.failed => 'Download failed',
                      OpdsDownloadStatus.cancelled => 'Cancelled',
                    },
              ),
              trailing: job.isCancellable
                  ? IconButton(
                      tooltip: 'Cancel download',
                      onPressed: () => downloads.cancel(job.key),
                      icon: const Icon(Icons.close),
                    )
                  : job.status == OpdsDownloadStatus.committing
                  ? const SizedBox.shrink()
                  : job.status == OpdsDownloadStatus.complete
                  ? IconButton(
                      tooltip: 'Open book',
                      onPressed: () => context.go('/library/details/${job.bookId}'),
                      icon: const Icon(Icons.menu_book),
                    )
                  : TextButton(
                      onPressed: () => _download(job.catalog, job.publication, job.link),
                      child: const Text('Retry'),
                    ),
            ),
        ],
      ),
    ),
  );

  Widget _empty(String title, {String? detail, required String action, required VoidCallback onAction}) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public, size: 48),
            const SizedBox(height: Spacing.md),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(detail, textAlign: TextAlign.center),
              ),
            const SizedBox(height: Spacing.md),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    ),
  );
}
