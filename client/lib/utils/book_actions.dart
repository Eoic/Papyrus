import 'package:flutter/material.dart';
import 'package:papyrus/models/book_data.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/widgets/context_menu/book_context_menu.dart';
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
      // TODO: Implement move to shelf
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
