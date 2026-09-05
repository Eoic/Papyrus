import 'package:powersync/powersync.dart';

const _bookColumns = [
  Column.text('owner_user_id'),
  Column.text('title'),
  Column.text('subtitle'),
  Column.text('author'),
  Column.text('co_authors'),
  Column.text('isbn'),
  Column.text('isbn13'),
  Column.text('publisher'),
  Column.text('language'),
  Column.integer('page_count'),
  Column.text('description'),
  Column.text('cover_image_url'),
  Column.text('file_media_id'),
  Column.text('cover_media_id'),
  Column.text('reading_status'),
  Column.integer('current_page'),
  Column.real('current_position'),
  Column.text('current_cfi'),
  Column.integer('is_favorite'),
  Column.integer('rating'),
  Column.text('custom_metadata'),
  Column.text('added_at'),
  Column.text('updated_at'),
  Column.text('publication_date'),
  Column.text('file_format'),
  Column.integer('file_size'),
  Column.text('file_hash'),
  Column.integer('is_physical'),
  Column.text('physical_location'),
  Column.text('lent_to'),
  Column.text('lent_at'),
  Column.text('series_id'),
  Column.text('series_name'),
  Column.real('series_number'),
  Column.text('started_at'),
  Column.text('completed_at'),
  Column.text('last_read_at'),
];

const _bookIndexes = [
  Index('books_added_at', [IndexedColumn('added_at')]),
  Index('books_title', [IndexedColumn('title')]),
];

const _shelvesColumns = [
  Column.text('owner_user_id'),
  Column.text('name'),
  Column.text('description'),
  Column.text('color_hex'),
  Column.integer('icon_code_point'),
  Column.text('icon_font_family'),
  Column.text('icon_font_package'),
  Column.integer('icon_match_text_direction'),
  Column.text('parent_shelf_id'),
  Column.integer('is_smart'),
  Column.text('smart_query'),
  Column.integer('sort_order'),
  Column.text('created_at'),
  Column.text('updated_at'),
];

const _tagsColumns = [
  Column.text('owner_user_id'),
  Column.text('name'),
  Column.text('color_hex'),
  Column.text('description'),
  Column.text('created_at'),
];

const _notesColumns = [
  Column.text('owner_user_id'),
  Column.text('book_id'),
  Column.text('title'),
  Column.text('content'),
  Column.text('location'),
  Column.text('tags'),
  Column.integer('is_pinned'),
  Column.text('created_at'),
  Column.text('updated_at'),
];

const _annotationsColumns = [
  Column.text('owner_user_id'),
  Column.text('book_id'),
  Column.text('selected_text'),
  Column.text('color'),
  Column.text('location'),
  Column.text('note'),
  Column.text('created_at'),
  Column.text('updated_at'),
];

const _bookShelvesColumns = [
  Column.text('owner_user_id'),
  Column.text('book_id'),
  Column.text('shelf_id'),
  Column.text('added_at'),
  Column.integer('sort_order'),
];

const _bookTagsColumns = [
  Column.text('owner_user_id'),
  Column.text('book_id'),
  Column.text('tag_id'),
  Column.text('created_at'),
];

const papyrusAccountSchema = Schema([
  Table('books', _bookColumns, indexes: _bookIndexes),
  Table('shelves', _shelvesColumns),
  Table('tags', _tagsColumns),
  Table('notes', _notesColumns),
  Table('annotations', _annotationsColumns),
  Table('book_shelves', _bookShelvesColumns),
  Table('book_tags', _bookTagsColumns),
  Table.localOnly('library_migrations', [Column.integer('version')]),
]);

const papyrusGuestSchema = Schema([
  Table.localOnly('books', _bookColumns, indexes: _bookIndexes),
  Table.localOnly('shelves', _shelvesColumns),
  Table.localOnly('tags', _tagsColumns),
  Table.localOnly('notes', _notesColumns),
  Table.localOnly('annotations', _annotationsColumns),
  Table.localOnly('book_shelves', _bookShelvesColumns),
  Table.localOnly('book_tags', _bookTagsColumns),
  Table.localOnly('library_migrations', [Column.integer('version')]),
]);

@Deprecated('Use papyrusAccountSchema')
const papyrusPowerSyncSchema = papyrusAccountSchema;
