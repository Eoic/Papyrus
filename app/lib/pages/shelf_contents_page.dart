import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/pages/library_page.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/shared/empty_state.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:provider/provider.dart';

/// Route adapter for viewing books within a specific shelf.
class ShelfContentsPage extends StatelessWidget {
  final String? shelfId;

  const ShelfContentsPage({super.key, required this.shelfId});

  @override
  Widget build(BuildContext context) {
    final dataStore = context.watch<DataStore>();
    final shelf = dataStore.getShelf(shelfId ?? '');

    if (shelf == null) {
      return _buildNotFound(context);
    }

    final favoriteState = context.read<LibraryProvider>();

    return ChangeNotifierProvider(
      key: ValueKey('shelf-library-${shelf.id}'),
      create: (_) => LibraryProvider(favoriteDelegate: favoriteState),
      child: LibraryPage(
        shelf: shelf,
        onBack: () => context.go('/library/shelves'),
        onEditShelf: () => _editShelf(context, dataStore, shelf),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: EmptyState(
            icon: Icons.shelves,
            title: 'Shelf not found',
            subtitle: 'This shelf may have been deleted',
            action: FilledButton.icon(
              onPressed: () => context.go('/library/shelves'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to shelves'),
            ),
          ),
        ),
      ),
    );
  }

  void _editShelf(BuildContext context, DataStore dataStore, Shelf shelf) {
    final repository = dataStore.libraryRepository?.shelves;
    AddShelfSheet.show(
      context,
      shelf: shelf,
      onSave: (name, description, colorHex, icon) async {
        await dataStore.updateShelf(
          shelf.copyWith(
            name: name,
            description: description,
            clearDescription: description == null,
            colorHex: colorHex,
            icon: icon,
            updatedAt: DateTime.now(),
          ),
          previous: shelf,
          repository: repository,
        );
      },
    );
  }
}
