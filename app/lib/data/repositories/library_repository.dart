import 'package:papyrus/data/repositories/book_repository.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/book_shelf_relation.dart';
import 'package:papyrus/models/book_tag_relation.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';

abstract interface class EntityRepository<T> {
  Future<T?> getById(String id);
  Future<void> upsert(T value, {T? previous});
  Future<void> delete(String id);
}

abstract interface class EditableBookRepository implements BookRepository {
  bool get isCurrent;
  Future<void> update(Book book, {required Book previous});
}

abstract interface class LibraryRepository {
  Stream<LibrarySnapshot> watchLibrary();
  EditableBookRepository get scopedBooks;
  EntityRepository<Shelf> get shelves;
  EntityRepository<Tag> get tags;
  EntityRepository<Note> get notes;
  EntityRepository<Annotation> get annotations;
  EntityRepository<BookShelfRelation> get bookShelves;
  EntityRepository<BookTagRelation> get bookTags;
  LibraryMembershipWriter get memberships;
}

abstract interface class LibraryMembershipWriter {
  Future<void> updateMemberships({
    required Set<String> bookIds,
    List<String>? shelfIds,
    List<String>? tagIds,
    Set<String>? previousShelfIds,
    Set<String>? previousTagIds,
    bool additive = false,
  });
}

class LibrarySnapshot {
  final List<Book> books;
  final List<Shelf> shelves;
  final List<Tag> tags;
  final List<Note> notes;
  final List<Annotation> annotations;
  final List<BookShelfRelation> bookShelves;
  final List<BookTagRelation> bookTags;

  const LibrarySnapshot({
    this.books = const [],
    this.shelves = const [],
    this.tags = const [],
    this.notes = const [],
    this.annotations = const [],
    this.bookShelves = const [],
    this.bookTags = const [],
  });
}
