import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/media/media_cache_service.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/reader/reader_book_adapter.dart';
import 'package:papyrus/reader/reader_session.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:papyrus_reader/papyrus_reader.dart';
import 'package:provider/provider.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.bookId});

  final String bookId;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  Book? _book;
  Uint8List? _bytes;
  ReaderFormat? _format;
  ReaderLocator? _initialLocator;
  ReaderPreferences? _initialPreferences;
  ReaderSession? _session;
  String? _error;
  bool _startedLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedLoading) return;

    _startedLoading = true;
    _load();
  }

  Future<void> _load() async {
    final dataStore = context.read<DataStore>();
    var book = dataStore.getBook(widget.bookId);

    book ??= await dataStore.requireBookRepository().getById(widget.bookId);
    if (book == null && !dataStore.isLoaded) {
      await dataStore.waitUntilLoaded();
      book = dataStore.getBook(widget.bookId);
    }
    if (!mounted) return;

    if (book == null) {
      setState(() => _error = 'Book not found.');
      return;
    }

    final format = ReaderBookAdapter.formatFor(book.fileFormat);
    if (format == null) {
      setState(() {
        _book = book;
        _error = 'This book format is not supported yet.';
      });
      return;
    }

    try {
      final importService = context.read<BookImportService>();
      final bytes = await context.read<MediaCacheService>().ensureBookFileCached(
        book,
        readLocalBookFile: importService.getBookFile,
        writeLocalBookFile: importService.storeBookFile,
        downloadMedia: context.read<AuthProvider>().downloadMedia,
      );
      if (!mounted) return;

      final session = ReaderSession(book: book, saveBook: dataStore.updateBook);
      final preferences = ReaderBookAdapter.preferencesFor(
        context.read<PreferencesProvider>(),
        Theme.of(context).colorScheme,
      );

      setState(() {
        _book = book;
        _bytes = bytes;
        _format = format;
        _initialLocator = ReaderBookAdapter.restoreLocator(book!);
        _initialPreferences = preferences;
        _session = session;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not open this book file.');
    }
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final book = _book;
    final bytes = _bytes;
    final format = _format;
    final preferences = _initialPreferences;
    if (book == null || bytes == null || format == null || preferences == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PapyrusReader(
      document: ReaderDocument(
        id: book.id,
        format: format,
        title: book.title,
        author: book.author,
        loadBytes: () async => bytes,
      ),
      initialLocator: _initialLocator,
      initialPreferences: preferences,
      onLocatorChanged: _session!.updateLocator,
      onPreferencesChanged: (updated) {
        ReaderBookAdapter.persistPreferences(context.read<PreferencesProvider>(), updated);
      },
      onBack: _close,
    );
  }

  void _close() {
    _session?.flush();
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed('BOOK_DETAILS', pathParameters: {'bookId': widget.bookId});
  }
}
