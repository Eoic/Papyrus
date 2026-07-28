enum LibraryViewMode { smallGrid, largeGrid, list }

extension LibraryViewModeExtension on LibraryViewMode {
  String get label {
    switch (this) {
      case LibraryViewMode.smallGrid:
        return 'Small grid';
      case LibraryViewMode.largeGrid:
        return 'Large grid';
      case LibraryViewMode.list:
        return 'List';
    }
  }
}
