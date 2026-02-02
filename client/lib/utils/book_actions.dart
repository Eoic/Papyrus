import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/context_menu/book_context_menu.dart';
import 'package:papyrus/widgets/shelves/move_to_shelf_sheet.dart';
import 'package:provider/provider.dart';

/// Show the book context menu with standard actions.
///
/// This helper centralizes the context menu logic used by book cards and list items.
/// The [position] parameter determines where the menu appears; if null, it will
/// be positioned at the center of the screen.
void showBookContextMenu({
  required BuildContext context,
  required BookData book,
  Offset? position,
}) {
  final libraryProvider = context.read<LibraryProvider>();
  final isFavorite = libraryProvider.isBookFavorite(book.id, book.isFavorite);

  BookContextMenu.show(
    context: context,
    book: book,
    isFavorite: isFavorite,
    tapPosition: position,
    onFavoriteToggle: () {
      libraryProvider.toggleFavorite(book.id, isFavorite);
    },
    onEdit: () {
      // TODO: Implement edit
    },
    onMoveToShelf: () {
      _showMoveToShelfSheet(context, book);
    },
    onManageTopics: () {
      // TODO: Implement manage topics
    },
    onStatusChange: (status) {
      // TODO: Implement status change
    },
    onDelete: () {
      // TODO: Implement delete
    },
  );
}

/// Shows the move to shelf sheet and handles shelf assignments.
void _showMoveToShelfSheet(BuildContext context, BookData book) {
  final dataStore = context.read<DataStore>();
  final currentShelfIds = dataStore.getShelfIdsForBook(book.id).toSet();

  MoveToShelfSheet.show(
    context,
    book: book,
    onSave: (newShelfIds) {
      final newShelfSet = newShelfIds.toSet();

      // Remove book from shelves it was removed from
      for (final shelfId in currentShelfIds) {
        if (!newShelfSet.contains(shelfId)) {
          dataStore.removeBookFromShelf(book.id, shelfId);
        }
      }

      // Add book to new shelves
      for (final shelfId in newShelfIds) {
        if (!currentShelfIds.contains(shelfId)) {
          dataStore.addBookToShelf(book.id, shelfId);
        }
      }
    },
  );
}
