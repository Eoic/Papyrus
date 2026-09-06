import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/opds/opds_download_panel.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';
import 'package:provider/provider.dart';

class OpdsPublicationTile extends StatelessWidget {
  const OpdsPublicationTile({
    super.key,
    required this.catalog,
    required this.publication,
    required this.onNavigate,
    required this.onDownload,
    required this.httpClient,
    this.credentials,
    this.isGridView = false,
  });
  final OpdsCatalog catalog;
  final OpdsPublication publication;
  final ValueChanged<Uri> onNavigate;
  final ValueChanged<OpdsLink> onDownload;
  final OpdsHttpClient httpClient;
  final OpdsCredentials? credentials;
  final bool isGridView;

  Widget _cover({double width = double.infinity, double height = double.infinity}) => OpdsCover(
    catalog: catalog,
    uri: publication.images.isEmpty ? null : publication.images.first.uri,
    credentials: credentials,
    httpClient: httpClient,
    width: width,
    height: height,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acquisition = publication.links.where((link) => link.isAcquisition);
    final formats = acquisition
        .map((link) => link.supportedExtension?.toUpperCase())
        .whereType<String>()
        .toSet()
        .join(' · ');
    final edition = acquisition.isEmpty ? null : acquisition.first.title;
    final caption = edition ?? (formats.isEmpty ? 'View details' : formats);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isGridView
              ? MediaQuery.textScalerOf(context).scale(theme.textTheme.titleSmall?.fontSize ?? 14) *
                    (theme.textTheme.titleSmall?.height ?? 1.4) *
                    2
              : null,
          child: Text(
            publication.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          publication.authors.isEmpty ? 'Unknown author' : publication.authors.join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
        ),
      ],
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: isGridView
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _cover()),
                  Padding(padding: const EdgeInsets.all(Spacing.sm), child: info),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    _cover(width: 56, height: 80),
                    const SizedBox(width: Spacing.md),
                    Expanded(child: info),
                    const SizedBox(width: Spacing.sm),
                    const Icon(Icons.chevron_right, size: IconSizes.small),
                  ],
                ),
              ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final downloads = context.read<OpdsDownloads>();
    Widget details(BuildContext modalContext) => _PublicationDetails(
      catalog: catalog,
      publication: publication,
      downloads: downloads,
      cover: _cover(width: 112, height: 168),
      onDownload: onDownload,
      onNavigate: (uri) {
        Navigator.of(modalContext).pop();
        onNavigate(uri);
      },
      onClose: () => Navigator.of(modalContext).pop(),
    );
    if (MediaQuery.sizeOf(context).width < Breakpoints.tablet) {
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        sheetAnimationStyle: AppMotion.animationStyle(context),
        builder: (sheetContext) =>
            SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.9, child: details(sheetContext)),
      );
    } else {
      showDialog<void>(
        context: context,
        animationStyle: AppMotion.animationStyle(context),
        builder: (dialogContext) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840, maxHeight: 780),
            child: SizedBox(width: 840, child: details(dialogContext)),
          ),
        ),
      );
    }
  }
}

class _PublicationDetails extends StatefulWidget {
  const _PublicationDetails({
    required this.catalog,
    required this.publication,
    required this.downloads,
    required this.cover,
    required this.onDownload,
    required this.onNavigate,
    required this.onClose,
  });
  final OpdsCatalog catalog;
  final OpdsPublication publication;
  final OpdsDownloads downloads;
  final Widget cover;
  final ValueChanged<OpdsLink> onDownload;
  final ValueChanged<Uri> onNavigate;
  final VoidCallback onClose;
  @override
  State<_PublicationDetails> createState() => _PublicationDetailsState();
}

class _PublicationDetailsState extends State<_PublicationDetails> {
  bool _expandedDescription = false;
  bool _showUnsupported = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publication = widget.publication;
    final acquisitions = publication.links.where((link) => link.isAcquisition).toList();
    final supported = acquisitions.where(OpdsDownloads.supports).toList();
    final unsupported = acquisitions.where((link) => !OpdsDownloads.supports(link)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.md, Spacing.sm),
          child: Row(
            children: [
              Expanded(child: Text('Book details', style: theme.textTheme.titleMedium)),
              TextButton(onPressed: widget.onClose, child: const Text('Close')),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: widget.cover),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(publication.title, style: theme.textTheme.headlineSmall),
                          if (publication.authors.isNotEmpty) ...[
                            const SizedBox(height: Spacing.sm),
                            Text(
                              publication.authors.join(', '),
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: Spacing.md),
                          Text(
                            widget.catalog.name,
                            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                          ),
                          if (publication.language != null)
                            Padding(
                              padding: const EdgeInsets.only(top: Spacing.sm),
                              child: Text('Language: ${publication.language}', style: theme.textTheme.bodySmall),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                Text('Download options', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Add a copy to your library.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: Spacing.md),
                AnimatedBuilder(
                  animation: widget.downloads,
                  builder: (_, _) => Column(children: [for (final link in supported) _format(context, link)]),
                ),
                if (supported.isEmpty)
                  Text(
                    publication.detailLink != null
                        ? 'Open the full catalog details to see available formats.'
                        : 'No direct downloads are available for this publication.',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (publication.detailLink != null)
                  TextButton.icon(
                    onPressed: () => widget.onNavigate(publication.detailLink!.uri),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Full catalog details'),
                  ),
                if (unsupported.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => setState(() => _showUnsupported = !_showUnsupported),
                    icon: Icon(_showUnsupported ? Icons.expand_less : Icons.expand_more),
                    label: Text('Other catalog options (${unsupported.length})'),
                  ),
                  if (_showUnsupported) ...[
                    Text(
                      'These formats or acquisition methods cannot be imported on this device.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    for (final link in unsupported)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.info_outline, size: IconSizes.small),
                        title: Text(link.title ?? link.type ?? 'Catalog acquisition'),
                      ),
                  ],
                ],
                if (publication.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: Spacing.lg),
                  const Divider(),
                  const SizedBox(height: Spacing.md),
                  Text('About this book', style: theme.textTheme.titleMedium),
                  const SizedBox(height: Spacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final style = theme.textTheme.bodyMedium?.copyWith(height: 1.6);
                      final painter = TextPainter(
                        text: TextSpan(text: publication.description, style: style),
                        maxLines: 7,
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout(maxWidth: constraints.maxWidth);
                      final overflows = painter.didExceedMaxLines;
                      painter.dispose();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            publication.description!,
                            key: const Key('opds-description'),
                            maxLines: _expandedDescription ? null : 7,
                            overflow: _expandedDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: style,
                          ),
                          if (overflows)
                            TextButton(
                              onPressed: () => setState(() => _expandedDescription = !_expandedDescription),
                              child: Text(_expandedDescription ? 'Show less' : 'Read more'),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                if (publication.publisher != null || publication.isbn != null) ...[
                  const SizedBox(height: Spacing.lg),
                  if (publication.publisher != null) _metadata(context, 'Publisher', publication.publisher!),
                  if (publication.isbn != null) _metadata(context, 'ISBN', publication.isbn!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metadata(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 88, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );

  Widget _format(BuildContext context, OpdsLink link) {
    final theme = Theme.of(context);
    final key = OpdsDownloads.jobKey(widget.catalog, widget.publication, link);
    final jobs = widget.downloads.jobs.where((job) => job.key == key);
    final job = jobs.isEmpty ? null : jobs.first;
    final format = link.supportedExtension!.toUpperCase();
    final complete = job?.status == OpdsDownloadStatus.complete;
    final active = job?.isActive ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final label = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(format, style: theme.textTheme.titleSmall),
                    if (link.title != null && link.title!.toUpperCase() != format)
                      Text(
                        link.title!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                );
                final button = FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: active || complete ? null : () => widget.onDownload(link),
                  icon: Icon(complete ? Icons.check : Icons.download_outlined, size: IconSizes.small),
                  label: Text(
                    complete
                        ? 'Added to library'
                        : job?.error != null
                        ? 'Retry download'
                        : 'Download $format',
                  ),
                );
                return constraints.maxWidth < 400
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label,
                          const SizedBox(height: Spacing.sm),
                          button,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: label),
                          const SizedBox(width: Spacing.md),
                          button,
                        ],
                      );
              },
            ),
            if (active) ...[
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(child: Text(opdsDownloadStatus(job!), style: theme.textTheme.bodySmall)),
                  if (job.isCancellable)
                    TextButton(onPressed: () => widget.downloads.cancel(job.key), child: const Text('Cancel')),
                ],
              ),
              AppLinearProgressIndicator(value: job.progress),
            ],
            if (job?.error != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(job!.error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ),
          ],
        ),
      ),
    );
  }
}

class OpdsCover extends StatefulWidget {
  const OpdsCover({
    super.key,
    required this.catalog,
    required this.uri,
    required this.httpClient,
    this.credentials,
    this.width = 40,
    this.height = 56,
  });
  final OpdsCatalog catalog;
  final Uri? uri;
  final OpdsHttpClient httpClient;
  final OpdsCredentials? credentials;
  final double width;
  final double height;
  @override
  State<OpdsCover> createState() => _OpdsCoverState();
}

class _OpdsCoverState extends State<OpdsCover> {
  OpdsCancellation _token = OpdsCancellation();
  Uint8List? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OpdsCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        oldWidget.catalog != widget.catalog ||
        oldWidget.credentials != widget.credentials) {
      _load();
    }
  }

  Future<void> _load() async {
    _token.cancel();
    final token = _token = OpdsCancellation();
    _bytes = null;
    if (widget.uri == null || !['http', 'https'].contains(widget.uri!.scheme)) return;
    try {
      final response = await widget.httpClient.get(
        widget.catalog,
        widget.uri!,
        credentials: widget.credentials,
        cancellation: token,
      );
      if (mounted && !token.isCancelled) setState(() => _bytes = response.bytes);
    } catch (_) {
      // Catalog artwork is optional; keep the themed cover placeholder.
    }
  }

  @override
  void dispose() {
    _token.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.menu_book_outlined, size: widget.width <= 56 ? 24 : 48, color: colors.onSurfaceVariant),
      ),
    );
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _bytes == null
          ? placeholder
          : Image.memory(_bytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
    );
  }
}
