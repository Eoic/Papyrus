import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/widgets/shared/bottom_sheet_handle.dart';
import 'package:papyrus/widgets/shared/view_mode_toggle.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:papyrus/widgets/shelves/shelf_card.dart';
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LibraryDrawer(currentPath: '/library/shelves'),
      body: SafeArea(
        child: Column(
          children: [
            // Row 1: Menu + Search + Sort
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.md,
                left: Spacing.md,
                right: Spacing.md,
              ),
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
                  const SizedBox(width: Spacing.sm),
                  _buildSortButton(provider),
                ],
              ),
            ),
            SizedBox(height: Spacing.md),
            // Row 2: Count + View toggle
            Padding(
              padding: const EdgeInsets.only(
                left: Spacing.md,
                right: Spacing.md,
                bottom: Spacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${provider.shelves.length} ${provider.shelves.length == 1 ? 'shelf' : 'shelves'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _buildViewToggle(provider),
                ],
              ),
            ),
            // Shelves grid or list
            Expanded(
              child: provider.hasShelves
                  ? provider.isListView
                        ? _buildShelfList(context, provider)
                        : _buildShelfGrid(context, provider)
                  : _buildEmptyState(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShelfSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context, ShelvesProvider provider) {
    const double controlHeight = 40.0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.only(
              top: Spacing.lg,
              left: Spacing.lg,
              right: Spacing.lg,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useCompactLayout = constraints.maxWidth < 800;

                if (useCompactLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSearchField(provider)),
                          const SizedBox(width: Spacing.sm),
                          _buildSortButton(provider),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          const Spacer(),
                          _buildViewToggle(provider),
                          const SizedBox(width: Spacing.sm),
                          _buildNewShelfButton(controlHeight),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _buildSearchField(provider)),
                    const SizedBox(width: Spacing.md),
                    _buildSortButton(provider),
                    const SizedBox(width: Spacing.md),
                    _buildViewToggle(provider),
                    const SizedBox(width: Spacing.md),
                    _buildNewShelfButton(controlHeight),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Shelves grid or list
          Expanded(
            child: provider.hasShelves
                ? provider.isListView
                      ? _buildShelfList(context, provider)
                      : _buildShelfGrid(context, provider)
                : _buildEmptyState(context),
          ),
        ],
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

  Widget _buildSortButton(ShelvesProvider provider) {
    return PopupMenuButton<ShelfSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort shelves',
      onSelected: (option) => provider.setShelfSortOption(option),
      itemBuilder: (context) => [
        _buildSortMenuItem(ShelfSortOption.name, 'Name', provider),
        _buildSortMenuItem(ShelfSortOption.bookCount, 'Book count', provider),
        _buildSortMenuItem(
          ShelfSortOption.dateCreated,
          'Date created',
          provider,
        ),
        _buildSortMenuItem(
          ShelfSortOption.dateModified,
          'Date modified',
          provider,
        ),
      ],
    );
  }

  PopupMenuItem<ShelfSortOption> _buildSortMenuItem(
    ShelfSortOption option,
    String label,
    ShelvesProvider provider,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            Icons.check,
            size: IconSizes.small,
            color: option == provider.shelfSortOption
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ShelvesProvider provider) {
    return ViewModeToggle(
      isGridView: provider.isGridView,
      onChanged: (isGrid) => provider.setViewMode(
        isGrid ? ShelvesViewMode.grid : ShelvesViewMode.list,
      ),
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

  Widget _buildShelfGrid(BuildContext context, ShelvesProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Match book-card proportions for visual consistency
    int crossAxisCount;
    double spacing;
    double childAspectRatio;

    if (screenWidth >= Breakpoints.desktopLarge) {
      crossAxisCount = 6;
      spacing = Spacing.md;
      childAspectRatio = 0.55;
    } else if (screenWidth >= Breakpoints.desktopSmall) {
      crossAxisCount = 5;
      spacing = Spacing.md;
      childAspectRatio = 0.55;
    } else if (screenWidth >= Breakpoints.tablet) {
      crossAxisCount = 4;
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
      itemCount: provider.shelves.length,
      itemBuilder: (context, index) {
        final shelf = provider.shelves[index];
        return ShelfCard(
          shelf: shelf,
          onTap: () => _showShelfDetail(context, shelf),
          onMoreTap: () => _showShelfOptions(context, shelf),
          onLongPress: () => _showShelfOptions(context, shelf),
        );
      },
    );
  }

  Widget _buildShelfList(BuildContext context, ShelvesProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: provider.shelves.length,
      itemBuilder: (context, index) {
        final shelf = provider.shelves[index];
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
        _provider.createShelf(
          name: name,
          description: description,
          colorHex: colorHex,
          icon: icon,
        );
      },
    );
  }

  void _showEditShelfSheet(BuildContext context, ShelfData shelf) {
    AddShelfSheet.show(
      context,
      shelf: shelf,
      onSave: (name, description, colorHex, icon) {
        _provider.updateShelf(
          shelfId: shelf.id,
          name: name,
          description: description,
          colorHex: colorHex,
          icon: icon,
        );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                title: Text(
                  'Delete shelf',
                  style: TextStyle(color: colorScheme.error),
                ),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
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
