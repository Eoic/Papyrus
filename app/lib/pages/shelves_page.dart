import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:papyrus/widgets/shelves/shelf_card.dart';
import 'package:papyrus/widgets/shelves/shelves_filter_chips.dart';
import 'package:provider/provider.dart';

/// Shelves page for managing book collections.
///
/// Features responsive layouts for mobile and desktop.
/// Allows users to view, create, edit, and delete shelves,
/// as well as manage books within shelves.
class ShelvesPage extends StatefulWidget {
  const ShelvesPage({super.key});

  @override
  State<ShelvesPage> createState() => _ShelvesPageState();
}

class _ShelvesPageState extends State<ShelvesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late ShelvesProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ShelvesProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Connect to DataStore for persistent storage
    final dataStore = context.read<DataStore>();
    _provider.attach(dataStore);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ShelvesProvider>(
        builder: (context, provider, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (isDesktop) {
            return _buildDesktopLayout(context, provider);
          }

          return _buildMobileLayout(context, provider);
        },
      ),
    );
  }

  // ============================================================================
  // LOADING STATE
  // ============================================================================

  Widget _buildLoadingState(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, ShelvesProvider provider) {
    final shelves = provider.shelves;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/shelves'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md, left: Spacing.md, right: Spacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Library sections',
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(child: _buildSearchField(provider)),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const ShelvesFilterChips(),
            Expanded(child: _buildShelfResults(context, provider, shelves)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShelfSheet(context),
        tooltip: 'New shelf',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context, ShelvesProvider provider) {
    const double controlHeight = 40.0;
    final shelves = provider.shelves;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: Spacing.lg, left: Spacing.lg, right: Spacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useCompactLayout = constraints.maxWidth < 800;

                  if (useCompactLayout) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchField(provider),
                        const SizedBox(height: Spacing.sm),
                        Align(alignment: Alignment.centerRight, child: _buildNewShelfButton(controlHeight)),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: _buildSearchField(provider)),
                      const SizedBox(width: Spacing.md),
                      _buildNewShelfButton(controlHeight),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const ShelvesFilterChips(horizontalPadding: Spacing.lg),
            Expanded(child: _buildShelfResults(context, provider, shelves)),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER CONTROLS
  // ============================================================================

  Widget _buildSearchField(ShelvesProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search shelves...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear shelf search',
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
              )
            : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        isDense: true,
      ),
      onChanged: provider.setSearchQuery,
    );
  }

  Widget _buildNewShelfButton(double height) {
    return FilledButton.icon(
      onPressed: () => _showAddShelfSheet(context),
      icon: const Icon(Icons.add),
      label: const Text('New shelf'),
      style: FilledButton.styleFrom(minimumSize: Size(0, height)),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildShelfResults(BuildContext context, ShelvesProvider provider, List<Shelf> shelves) {
    if (!provider.hasAnyShelves) {
      return _buildEmptyState(context);
    }
    if (shelves.isEmpty) {
      return _buildNoResultsState(context);
    }
    if (provider.viewMode == ShelvesViewMode.list) {
      return _buildShelfList(context, shelves);
    }
    return _buildShelfGrid(context, shelves, provider.viewMode);
  }

  Widget _buildShelfGrid(BuildContext context, List<Shelf> shelves, ShelvesViewMode viewMode) {
    final isLargeGrid = viewMode == ShelvesViewMode.largeGrid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Match book-card proportions for visual consistency.
        int crossAxisCount;
        double spacing;
        double childAspectRatio;

        if (width >= Breakpoints.desktopLarge) {
          crossAxisCount = isLargeGrid ? 4 : 6;
          spacing = Spacing.md;
          childAspectRatio = 0.55;
        } else if (width >= Breakpoints.desktopSmall) {
          crossAxisCount = isLargeGrid ? 3 : 5;
          spacing = Spacing.md;
          childAspectRatio = 0.55;
        } else if (width >= Breakpoints.tablet) {
          crossAxisCount = isLargeGrid ? 3 : 4;
          spacing = Spacing.sm + 4;
          childAspectRatio = 0.55;
        } else {
          crossAxisCount = 2;
          spacing = Spacing.sm;
          childAspectRatio = 0.58;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: shelves.length,
          itemBuilder: (context, index) {
            final shelf = shelves[index];
            return ShelfCard(
              shelf: shelf,
              onTap: () => _showShelfDetail(context, shelf),
              onMoreTap: () => _showShelfOptions(context, shelf),
              onLongPress: () => _showShelfOptions(context, shelf),
            );
          },
        );
      },
    );
  }

  Widget _buildShelfList(BuildContext context, List<Shelf> shelves) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: shelves.length,
      itemBuilder: (context, index) {
        final shelf = shelves[index];
        return ShelfCard(
          shelf: shelf,
          isListItem: true,
          onTap: () => _showShelfDetail(context, shelf),
          onMoreTap: () => _showShelfOptions(context, shelf),
          onLongPress: () => _showShelfOptions(context, shelf),
        );
      },
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_off,
      title: 'No shelves found',
      subtitle: 'Try changing your search or filters',
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.shelves,
      title: 'No shelves yet',
      subtitle: 'Create shelves to organize your books into collections',
      action: FilledButton.icon(
        onPressed: () => _showAddShelfSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Create shelf'),
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _showAddShelfSheet(BuildContext context) {
    AddShelfSheet.show(
      context,
      onSave: (name, description, colorHex, icon) {
        _provider.createShelf(name: name, description: description, colorHex: colorHex, icon: icon);
      },
    );
  }

  void _showEditShelfSheet(BuildContext context, ShelfData shelf) {
    AddShelfSheet.show(
      context,
      shelf: shelf,
      onSave: (name, description, colorHex, icon) {
        _provider.updateShelf(shelfId: shelf.id, name: name, description: description, colorHex: colorHex, icon: icon);
      },
    );
  }

  void _showShelfDetail(BuildContext context, ShelfData shelf) {
    context.go('/library/shelves/${shelf.id}');
  }

  void _showShelfOptions(BuildContext context, ShelfData shelf) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const BottomSheetHandle(),
              const SizedBox(height: Spacing.md),
              // Shelf name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Text(
                  shelf.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: Spacing.md),
              // Options
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit shelf'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditShelfSheet(context, shelf);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outlined, color: colorScheme.error),
                title: Text('Delete shelf', style: TextStyle(color: colorScheme.error)),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteShelf(context, shelf);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteShelf(BuildContext context, ShelfData shelf) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete shelf'),
        content: Text('Delete "${shelf.name}"? Books will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _provider.deleteShelf(shelf.id);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
