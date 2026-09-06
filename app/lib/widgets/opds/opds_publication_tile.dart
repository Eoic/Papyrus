import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/themes/design_tokens.dart';
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
  });
  final OpdsCatalog catalog;
  final OpdsPublication publication;
  final ValueChanged<Uri> onNavigate;
  final ValueChanged<OpdsLink> onDownload;
  final OpdsHttpClient httpClient;
  final OpdsCredentials? credentials;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
    child: ListTile(
      contentPadding: const EdgeInsets.all(Spacing.md),
      leading: OpdsCover(
        catalog: catalog,
        uri: publication.images.isEmpty ? null : publication.images.first.uri,
        credentials: credentials,
        httpClient: httpClient,
      ),
      title: Text(publication.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        publication.authors.isEmpty ? 'Unknown author' : publication.authors.join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDetails(context),
    ),
  );

  void _showDetails(BuildContext context) {
    final downloads = context.read<OpdsDownloads>();
    showDialog<void>(
      context: context,
      animationStyle: AppMotion.animationStyle(context),
      builder: (dialogContext) => AnimatedBuilder(
        animation: downloads,
        builder: (_, _) => AlertDialog(
          title: Text(publication.title),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (publication.authors.isNotEmpty) Text(publication.authors.join(', ')),
                  if (publication.publisher != null) Text(publication.publisher!),
                  if (publication.language != null) Text('Language: ${publication.language}'),
                  if (publication.isbn != null) Text('ISBN: ${publication.isbn}'),
                  if (publication.description != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      child: Text(publication.description!),
                    ),
                  if (publication.detailLink != null)
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onNavigate(publication.detailLink!.uri);
                      },
                      child: const Text('Full catalog details'),
                    ),
                  for (final link in publication.links.where((link) => link.isAcquisition))
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: _downloadButton(downloads, link),
                    ),
                  if (!publication.links.any((link) => link.isAcquisition))
                    const Text('No direct downloads are available for this publication.'),
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))],
        ),
      ),
    );
  }

  Widget _downloadButton(OpdsDownloads downloads, OpdsLink link) {
    final key = OpdsDownloads.jobKey(catalog, publication, link);
    final matches = downloads.jobs.where((job) => job.key == key);
    final job = matches.isEmpty ? null : matches.first;
    final supported = OpdsDownloads.supports(link);
    final label = link.title ?? link.supportedExtension?.toUpperCase() ?? link.type ?? 'Acquisition';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: supported && !(job?.isActive ?? false) && job?.status != OpdsDownloadStatus.complete
              ? () => onDownload(link)
              : null,
          icon: const Icon(Icons.download_outlined),
          label: Text(job?.status == OpdsDownloadStatus.complete ? 'Added to library' : 'Download $label'),
        ),
        if (!supported) const Text('This format or acquisition method is not supported on this device.'),
        if (job?.isActive ?? false)
          Text(switch (job!.status) {
            OpdsDownloadStatus.committing => 'Adding to library…',
            OpdsDownloadStatus.importing => 'Importing…',
            _ => 'Downloading…',
          }),
        if (job?.error != null) Text(job!.error!),
      ],
    );
  }
}

class OpdsCover extends StatefulWidget {
  const OpdsCover({super.key, required this.catalog, required this.uri, required this.httpClient, this.credentials});
  final OpdsCatalog catalog;
  final Uri? uri;
  final OpdsHttpClient httpClient;
  final OpdsCredentials? credentials;
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
    if (widget.uri == null) return;
    try {
      final response = await widget.httpClient.get(
        widget.catalog,
        widget.uri!,
        credentials: widget.credentials,
        cancellation: token,
      );
      if (mounted && !token.isCancelled) setState(() => _bytes = response.bytes);
    } catch (_) {
      /* Use the book icon for missing or inaccessible artwork. */
    }
  }

  @override
  void dispose() {
    _token.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 56,
    child: _bytes == null
        ? const Icon(Icons.menu_book_outlined)
        : Image.memory(_bytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.menu_book_outlined)),
  );
}
