import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/shelves_provider.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/library/library_drawer.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:papyrus/widgets/shelves/shelf_card.dart';
import 'package:papyrus/widgets/shelves/shelf_detail_sheet.dart';
import 'package:provider/provider.dart';

/// Shelves page for managing book collections.
///
/// Features responsive layouts for mobile, desktop, and e-ink displays.
/// Allows users to view, create, edit, and delete shelves,
/// as well as manage books within shelves.
class ShelvesPage extends StatefulWidget {
  const ShelvesPage({super.key});

  @override
  State<ShelvesPage> createState() => _ShelvesPageState();
}

class _ShelvesPageState extends State<ShelvesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ShelvesProvider>(
        builder: (context, provider, _) {
          final displayMode = context.watch<DisplayModeProvider>();
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= Breakpoints.desktopSmall;

          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (displayMode.isEinkMode)
            return _buildEinkLayout(context, provider);
          if (isDesktop) return _buildDesktopLayout(context, provider);
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
            // Header with drawer button
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    tooltip: 'Library sections',
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Shelves',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // View toggle
                  SegmentedButton<ShelvesViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: ShelvesViewMode.grid,
                        icon: Icon(Icons.grid_view, size: IconSizes.small),
                      ),
                      ButtonSegment(
                        value: ShelvesViewMode.list,
                        icon: Icon(Icons.view_list, size: IconSizes.small),
                      ),
                    ],
                    selected: {provider.viewMode},
                    onSelectionChanged: (selection) {
                      provider.setViewMode(selection.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            // Shelf count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Row(
                children: [
                  Text(
                    '${provider.shelves.length} ${provider.shelves.length == 1 ? 'shelf' : 'shelves'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
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
    final textTheme = Theme.of(context).textTheme;
    const double controlHeight = 48.0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Text('Shelves', style: textTheme.headlineMedium),
                const SizedBox(width: Spacing.lg),
                Text(
                  '${provider.shelves.length} ${provider.shelves.length == 1 ? 'shelf' : 'shelves'}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // View toggle
                _buildViewToggle(context, provider, controlHeight),
                const SizedBox(width: Spacing.md),
                // Add button
                FilledButton.icon(
                  onPressed: () => _showAddShelfSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New shelf'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, controlHeight),
                  ),
                ),
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
    );
  }

  Widget _buildViewToggle(
    BuildContext context,
    ShelvesProvider provider,
    double height,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ToggleButtons(
          isSelected: [
            provider.viewMode == ShelvesViewMode.grid,
            provider.viewMode == ShelvesViewMode.list,
          ],
          onPressed: (index) {
            provider.setViewMode(
              index == 0 ? ShelvesViewMode.grid : ShelvesViewMode.list,
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          renderBorder: false,
          constraints: BoxConstraints(minHeight: height, minWidth: height),
          children: const [Icon(Icons.grid_view), Icon(Icons.view_list)],
        ),
      ),
    );
  }

  // ============================================================================
  // E-INK LAYOUT
  // ============================================================================

  Widget _buildEinkLayout(BuildContext context, ShelvesProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: ComponentSizes.einkHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline,
                  width: BorderWidths.einkDefault,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'SHELVES',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.shelves.length} shelves',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(width: Spacing.lg),
                GestureDetector(
                  onTap: () => _showAddShelfSheet(context),
                  child: Container(
                    width: TouchTargets.einkMin,
                    height: TouchTargets.einkMin,
                    alignment: Alignment.center,
                    child: const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Shelves list
          Expanded(
            child: provider.hasShelves
                ? ListView.builder(
                    padding: const EdgeInsets.all(Spacing.pageMarginsEink),
                    itemCount: provider.shelves.length,
                    itemBuilder: (context, index) {
                      final shelf = provider.shelves[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: ShelfCard(
                          shelf: shelf,
                          isEinkMode: true,
                          onTap: () => _showShelfDetail(context, shelf),
                        ),
                      );
                    },
                  )
                : _buildEinkEmptyState(context),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED WIDGETS
  // ============================================================================

  Widget _buildShelfGrid(BuildContext context, ShelvesProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive columns
    int crossAxisCount;
    if (screenWidth >= Breakpoints.desktopLarge) {
      crossAxisCount = 5;
    } else if (screenWidth >= Breakpoints.desktopSmall) {
      crossAxisCount = 4;
    } else if (screenWidth >= Breakpoints.tablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Spacing.md,
        crossAxisSpacing: Spacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: provider.shelves.length,
      itemBuilder: (context, index) {
        final shelf = provider.shelves[index];
        return ShelfCard(
          shelf: shelf,
          onTap: () => _showShelfDetail(context, shelf),
          onMoreTap: () => _showShelfOptions(context, shelf),
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

  Widget _buildEinkEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(Spacing.pageMarginsEink),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: BorderWidths.einkDefault,
          ),
        ),
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shelves, size: 64),
            const SizedBox(height: Spacing.lg),
            Text(
              'NO SHELVES YET',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Tap + to create your first shelf',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final books = _provider.getBooksForShelf(shelf.id);

    ShelfDetailSheet.show(
      context,
      shelf: shelf,
      books: books,
      onEdit: () => _showEditShelfSheet(context, shelf),
      onDelete: () => _provider.deleteShelf(shelf.id),
      onRemoveBook: (book) {
        _provider.removeBookFromShelf(shelfId: shelf.id, bookId: book.id);
      },
    );
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View shelf'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showShelfDetail(context, shelf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit shelf'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditShelfSheet(context, shelf);
                },
              ),
              if (!shelf.isDefault)
                ListTile(
                  leading: Icon(
                    Icons.delete_outlined,
                    color: colorScheme.error,
                  ),
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
