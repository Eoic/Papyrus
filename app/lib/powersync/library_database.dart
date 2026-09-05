import 'dart:convert';

import 'package:papyrus/data/repositories/library_repository.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/powersync/library_row_mapper.dart';
import 'package:papyrus/powersync/powersync_book_mapper.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// A handle bound to one opened library, invalidated before a profile switch.
class LibraryDatabase implements LibraryMembershipWriter {
  final PowerSyncDatabase database;
  final Future<void> Function() onWrite;
  bool active = true;

  LibraryDatabase(this.database, this.onWrite);

  late final shelves = SqlEntityRepository(this, shelfRowMapper);
  late final tags = SqlEntityRepository(this, tagRowMapper);
  late final notes = SqlEntityRepository(this, noteRowMapper);
  late final annotations = SqlEntityRepository(this, annotationRowMapper);
  late final bookShelves = SqlEntityRepository(this, bookShelfRowMapper);
  late final bookTags = SqlEntityRepository(this, bookTagRowMapper);
  late final books = ScopedBooks(this);

  void checkActive() {
    if (!active) throw StateError('The library changed. Reopen this item before saving.');
  }

  Future<void> write(Future<void> Function(SqliteWriteContext) action) async {
    checkActive();
    await database.writeTransaction((tx) async {
      checkActive();
      await action(tx);
    });
    if (active) await onWrite();
  }

  Future<void> upsert(String table, Map<String, Object?> row, {Map<String, Object?>? previous}) =>
      write((tx) => upsertRow(tx, table, row, previous: previous));

  Future<void> upsertRow(
    SqliteWriteContext tx,
    String table,
    Map<String, Object?> row, {
    Map<String, Object?>? previous,
  }) async {
    final id = row['id'];
    final existing = await tx.getOptional('SELECT * FROM $table WHERE id = ?', [id]);
    if (existing == null) {
      if (previous != null) return;
      await _validateReferences(tx, table, row);
      await tx.execute(
        'INSERT INTO $table (${row.keys.join(', ')}) VALUES (${List.filled(row.length, '?').join(', ')})',
        row.values.toList(),
      );
      return;
    }

    final baseline = previous ?? Map<String, Object?>.from(existing);
    final changes = Map<String, Object?>.fromEntries(
      row.entries.where(
        (entry) =>
            !['id', 'updated_at', 'created_at', 'added_at'].contains(entry.key) &&
            !_sameValue(entry.key, entry.value, baseline[entry.key]),
      ),
    );
    if (changes.isEmpty) return;
    if (row.containsKey('updated_at')) changes['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _validateReferences(tx, table, {...existing, ...changes});
    await tx.execute('UPDATE $table SET ${changes.keys.map((key) => '$key = ?').join(', ')} WHERE id = ?', [
      ...changes.values,
      id,
    ]);
  }

  Future<void> _validateReferences(SqliteReadContext tx, String table, Map<String, Object?> row) async {
    for (final reference in {'book_id': 'books', 'shelf_id': 'shelves', 'tag_id': 'tags'}.entries) {
      final id = row[reference.key];
      if (id != null && await tx.getOptional('SELECT id FROM ${reference.value} WHERE id = ?', [id]) == null) {
        throw StateError('The referenced ${reference.value} record no longer exists.');
      }
    }
    if (table != 'shelves') return;
    final visited = <Object?>{row['id']};
    var parent = row['parent_shelf_id'];
    while (parent != null) {
      if (!visited.add(parent)) throw StateError('A shelf cannot contain itself.');
      final ancestor = await tx.getOptional('SELECT parent_shelf_id FROM shelves WHERE id = ?', [parent]);
      if (ancestor == null) throw StateError('The parent shelf no longer exists.');
      parent = ancestor['parent_shelf_id'];
    }
  }

  Future<void> delete(String table, String id) => write((tx) async {
    if (table == 'books') {
      for (final dependent in ['notes', 'annotations', 'book_shelves', 'book_tags']) {
        await tx.execute('DELETE FROM $dependent WHERE book_id = ?', [id]);
      }
    } else if (table == 'shelves') {
      await tx.execute('DELETE FROM book_shelves WHERE shelf_id = ?', [id]);
      await tx.execute('UPDATE shelves SET parent_shelf_id = NULL, updated_at = ? WHERE parent_shelf_id = ?', [
        DateTime.now().toUtc().toIso8601String(),
        id,
      ]);
    } else if (table == 'tags') {
      await tx.execute('DELETE FROM book_tags WHERE tag_id = ?', [id]);
    }
    await tx.execute('DELETE FROM $table WHERE id = ?', [id]);
  });

  @override
  Future<void> updateMemberships({
    required Set<String> bookIds,
    List<String>? shelfIds,
    List<String>? tagIds,
    Set<String>? previousShelfIds,
    Set<String>? previousTagIds,
    bool additive = false,
  }) => write((tx) async {
    Future<void> update(String table, String field, List<String>? selected, Set<String>? baseline) async {
      if (selected == null) return;
      final wanted = selected.toSet();
      for (final bookId in bookIds) {
        final rows = await tx.getAll('SELECT $field FROM $table WHERE book_id = ?', [bookId]);
        final current = rows.map((row) => row[field] as String).toSet();
        final original = baseline ?? current;
        if (!additive) {
          for (final removed in original.difference(wanted)) {
            await tx.execute('DELETE FROM $table WHERE id = ?', ['$bookId:$removed']);
          }
        }
        final additions = additive ? wanted : wanted.difference(original);
        for (final added in additions.difference(current)) {
          await upsertRow(tx, table, {
            'id': '$bookId:$added',
            'book_id': bookId,
            field: added,
            table == 'book_shelves' ? 'added_at' : 'created_at': DateTime.now().toUtc().toIso8601String(),
            if (table == 'book_shelves') 'sort_order': 0,
          });
        }
      }
    }

    await update('book_shelves', 'shelf_id', shelfIds, previousShelfIds);
    await update('book_tags', 'tag_id', tagIds, previousTagIds);
  });

  Future<LibrarySnapshot> snapshot() => database.readTransaction((tx) async {
    Future<List<T>> rows<T>(LibraryRowMapper<T> mapper) async => (await tx.getAll(
      'SELECT * FROM ${mapper.table}',
    )).map((row) => mapper.fromRow(Map<String, dynamic>.from(row))).toList();
    return LibrarySnapshot(
      books: (await tx.getAll(
        'SELECT * FROM books ORDER BY added_at DESC',
      )).map((row) => PowerSyncBookMapper.fromRow(Map<String, Object?>.from(row))).toList(),
      shelves: await rows(shelfRowMapper),
      tags: await rows(tagRowMapper),
      notes: await rows(noteRowMapper),
      annotations: await rows(annotationRowMapper),
      bookShelves: await rows(bookShelfRowMapper),
      bookTags: await rows(bookTagRowMapper),
    );
  });

  /// Expands legacy local metadata once without clearing data or the CRUD queue.
  Future<void> migrateLegacyBooks() async {
    await database.writeTransaction((tx) async {
      if (await tx.getOptional("SELECT id FROM library_migrations WHERE id = 'book-fields-v1'") != null) return;
      final storageTable = database.schema.tables.singleWhere((table) => table.name == 'books').internalName;
      for (final raw in await tx.getAll('SELECT id, data FROM $storageTable')) {
        final row = Map<String, Object?>.from(jsonDecode(raw['data'] as String) as Map);
        final encoded = row['custom_metadata'];
        if (encoded is! String) continue;
        final metadata = jsonDecode(encoded);
        if (metadata is! Map<String, dynamic>) continue;
        final changes = <String, Object?>{};
        for (final entry in metadata.entries) {
          if (row.containsKey(entry.key)) continue;
          final value = _legacyPromotedValue(entry.key, entry.value);
          if (value != null) changes[entry.key] = value;
        }
        if (changes.isNotEmpty) {
          await tx.execute('UPDATE books SET ${changes.keys.map((key) => '$key = ?').join(', ')} WHERE id = ?', [
            ...changes.values,
            raw['id'],
          ]);
        }
      }
      await tx.execute("INSERT INTO library_migrations (id, version) VALUES ('book-fields-v1', 1)");
    });
  }
}

Object? _legacyPromotedValue(String key, Object? value) {
  if (value == null) return null;
  if (['publication_date', 'lent_at', 'started_at', 'completed_at', 'last_read_at'].contains(key)) {
    final date = value is String ? DateTime.tryParse(value)?.toUtc() : null;
    return date != null && date.year >= 1 && date.year <= 9999 ? date.toIso8601String() : null;
  }
  if (['file_format', 'file_hash', 'physical_location', 'lent_to', 'series_id', 'series_name'].contains(key)) {
    return value is String ? value : null;
  }
  if (key == 'file_size') return value is int && value >= 0 && value.bitLength <= 63 ? value : null;
  if (key == 'series_number') return value is num && value.isFinite ? value.toDouble() : null;
  if (key == 'is_physical') {
    if (value is bool) return value ? 1 : 0;
    if (value == 0 || value == 1) return value;
  }
  return null;
}

bool _sameValue(String key, Object? a, Object? b) {
  if (a == b) return true;
  if ((key.endsWith('_at') || key == 'publication_date') && a is String && b is String) {
    final first = DateTime.tryParse(a);
    final second = DateTime.tryParse(b);
    if (first != null && second != null) return first.isAtSameMomentAs(second);
  }
  return false;
}

class SqlEntityRepository<T> implements EntityRepository<T> {
  final LibraryDatabase library;
  final LibraryRowMapper<T> mapper;
  SqlEntityRepository(this.library, this.mapper);

  @override
  Future<T?> getById(String id) async {
    library.checkActive();
    final row = await library.database.getOptional('SELECT * FROM ${mapper.table} WHERE id = ?', [id]);
    return row == null ? null : mapper.fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> upsert(T value, {T? previous}) =>
      library.upsert(mapper.table, mapper.toRow(value), previous: previous == null ? null : mapper.toRow(previous));

  @override
  Future<void> delete(String id) => library.delete(mapper.table, id);
}

class ScopedBooks implements EditableBookRepository {
  final LibraryDatabase library;
  ScopedBooks(this.library);
  @override
  bool get isCurrent => library.active;
  @override
  Future<Book?> getById(String id) async {
    library.checkActive();
    final row = await library.database.getOptional('SELECT * FROM books WHERE id = ?', [id]);
    return row == null ? null : PowerSyncBookMapper.fromRow(Map<String, Object?>.from(row));
  }

  @override
  Stream<List<Book>> watchAll() => library.database
      .watch('SELECT * FROM books ORDER BY added_at DESC')
      .map((rows) => rows.map((row) => PowerSyncBookMapper.fromRow(Map<String, Object?>.from(row))).toList());
  @override
  Future<void> upsert(Book book) => library.upsert('books', PowerSyncBookMapper.toRow(book));
  @override
  Future<void> update(Book book, {required Book previous}) =>
      library.upsert('books', PowerSyncBookMapper.toRow(book), previous: PowerSyncBookMapper.toRow(previous));
  @override
  Future<void> delete(String id) => library.delete('books', id);
}
