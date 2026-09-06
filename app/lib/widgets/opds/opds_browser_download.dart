import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/opds/opds_downloads.dart';
import 'package:papyrus/platform/opds_browser_download.dart';
import 'package:papyrus/themes/app_motion.dart';

/// Manual recovery for unreadable web responses; this never marks a job imported.
class OpdsBrowserDownload extends StatelessWidget {
  const OpdsBrowserDownload({super.key, required this.job, this.onOpen});
  final OpdsDownloadJob job;
  final ValueChanged<Uri>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb ||
        !job.networkFailure ||
        job.status != OpdsDownloadStatus.failed ||
        !OpdsDownloads.supports(job.link)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('Download in browser'),
          onPressed: () {
            try {
              (onOpen ?? openOpdsDownload)(job.link.uri);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                snackBarAnimationStyle: AppMotion.animationStyle(context),
                const SnackBar(content: Text('Could not open the download. Check your browser settings and retry.')),
              );
            }
          },
        ),
        Text(
          'Save the file, then use Library → Add book to import it. '
          'You may need to sign in on the catalog website.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
