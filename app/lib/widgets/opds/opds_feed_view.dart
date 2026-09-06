import 'package:flutter/material.dart';
import 'package:papyrus/opds/opds_http_client.dart';
import 'package:papyrus/opds/opds_models.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/opds/opds_publication_tile.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';

class OpdsFeedView extends StatelessWidget {
  const OpdsFeedView({
    super.key,
    required this.catalog,
    required this.feed,
    required this.httpClient,
    required this.onNavigate,
    required this.onDownload,
    required this.onRefresh,
    required this.isGridView,
    required this.onViewChanged,
    required this.onPage,
    this.credentials,
    this.query = '',
  });
  final OpdsCatalog catalog;
  final OpdsFeed feed;
  final OpdsHttpClient httpClient;
  final OpdsCredentials? credentials;
  final ValueChanged<Uri> onNavigate;
  final ValueChanged<Uri> onPage;
  final void Function(OpdsPublication, OpdsLink) onDownload;
  final VoidCallback onRefresh;
  final bool isGridView;
  final ValueChanged<bool> onViewChanged;
  final String query;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final hasBooks = feed.publications.isNotEmpty || feed.groups.any((group) => group.publications.isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 190).floor().clamp(2, 6);
        return CustomScrollView(
          key: PageStorageKey(feed.uri),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(feed.title, style: text.titleLarge)),
                        IconButton(tooltip: 'Refresh catalog', onPressed: onRefresh, icon: const Icon(Icons.refresh)),
                      ],
                    ),
                    if (query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.xs),
                        child: Text(
                          'Results for “$query”',
                          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    if (hasBooks)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Browse books',
                                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                            ViewModeToggle(isGridView: isGridView, onChanged: onViewChanged),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (feed.facets.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final facet in feed.facets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: Spacing.sm,
                            runSpacing: Spacing.xs,
                            children: [
                              Text('${facet.title}:', style: text.labelLarge),
                              for (final link in facet.links)
                                ActionChip(label: Text(link.title ?? 'Filter'), onPressed: () => onNavigate(link.uri)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ..._entries(context, feed.navigation, feed.publications, columns, constraints.maxWidth),
            for (final group in feed.groups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.md),
                  child: Row(
                    children: [
                      Expanded(child: Text(group.title, style: text.titleMedium)),
                      for (final link
                          in group.links.where((link) => link.hasRel('self') || link.hasRel('collection')).take(1))
                        TextButton(onPressed: () => onNavigate(link.uri), child: const Text('View all')),
                    ],
                  ),
                ),
              ),
              ..._entries(context, group.navigation, group.publications, columns, constraints.maxWidth),
            ],
            if (feed.navigation.isEmpty && feed.publications.isEmpty && feed.groups.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: colors.onSurfaceVariant),
                      const SizedBox(height: Spacing.md),
                      Text('No books or sections found.', style: text.titleMedium),
                      if (query.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: Spacing.sm),
                          child: Text('Try another title, author, or keyword.'),
                        ),
                    ],
                  ),
                ),
              ),
            if (feed.previousLink != null || feed.nextLink != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          if (feed.previousLink != null)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                              onPressed: () => onPage(feed.previousLink!.uri),
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Previous'),
                            ),
                          if (feed.nextLink != null)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                              onPressed: () => onPage(feed.nextLink!.uri),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Next'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
          ],
        );
      },
    );
  }

  List<Widget> _entries(
    BuildContext context,
    List<OpdsLink> navigation,
    List<OpdsPublication> publications,
    int columns,
    double width,
  ) => [
    if (navigation.isNotEmpty)
      SliverPadding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (width / 340).floor().clamp(1, 3),
            mainAxisExtent:
                (navigation.any((link) => link.description != null) ? 112 : 88) *
                MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
          ),
          itemCount: navigation.length,
          itemBuilder: (_, index) {
            final link = navigation[index];
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onNavigate(link.uri),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Row(
                    children: [
                      if (link.imageUri != null && ['http', 'https'].contains(link.imageUri!.scheme))
                        OpdsCover(
                          catalog: catalog,
                          uri: link.imageUri,
                          httpClient: httpClient,
                          credentials: credentials,
                          width: 36,
                          height: 52,
                        )
                      else
                        Icon(Icons.local_library_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.title ?? 'Browse section',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (link.description?.isNotEmpty ?? false) ...[
                              const SizedBox(height: Spacing.xs),
                              Text(
                                link.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      const Icon(Icons.chevron_right, size: IconSizes.small),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    if (publications.isNotEmpty)
      if (isGridView)
        SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: Spacing.md,
            mainAxisSpacing: Spacing.md,
            mainAxisExtent:
                ((width - (columns - 1) * Spacing.md) / columns) * 1.3 +
                106 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
          ),
          itemCount: publications.length,
          itemBuilder: (_, index) => _publication(publications[index]),
        )
      else
        SliverList.separated(
          itemCount: publications.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (_, index) => _publication(publications[index]),
        ),
  ];

  Widget _publication(OpdsPublication publication) => OpdsPublicationTile(
    key: ValueKey(publication.id),
    catalog: catalog,
    publication: publication,
    credentials: credentials,
    httpClient: httpClient,
    isGridView: isGridView,
    onNavigate: onNavigate,
    onDownload: (link) => onDownload(publication, link),
  );
}
