import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/media/cover_storage_bucket.dart';
import 'package:papyrus/media/local_cover_image_provider.dart';
import 'package:papyrus/media/media_cache_service.dart';
import 'package:papyrus/media/media_storage_scope.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/providers/sync_settings_provider.dart';
import 'package:papyrus/services/book_import_service_stub.dart'
    if (dart.library.js_interop) 'package:papyrus/services/book_import_service.dart';
import 'package:provider/provider.dart';

typedef PrivateCoverLoader = Future<Uint8List?> Function(String mediaId);
typedef LocalBookCoverLoader = Future<Uint8List?> Function(String bookId);
typedef PendingBookCoverLoader = Future<Uint8List?> Function(MediaStorageScope scope, String bookId);
typedef GuestBookCoverLoader = Future<Uint8List?> Function(String bookId);

/// Renders a public cover URL or a lazily persisted authenticated cover.
class CoverImage extends StatefulWidget {
  const CoverImage({
    super.key,
    this.bookId,
    this.imageUrl,
    this.mediaId,
    this.fit = BoxFit.cover,
    required this.placeholder,
    this.loadPrivateCover,
    this.loadLocalBookCover,
    this.loadPendingBookCover,
    this.loadGuestBookCover,
  });

  final String? bookId;
  final String? imageUrl;
  final String? mediaId;
  final BoxFit fit;
  final Widget placeholder;
  final PrivateCoverLoader? loadPrivateCover;
  final LocalBookCoverLoader? loadLocalBookCover;
  final PendingBookCoverLoader? loadPendingBookCover;
  final GuestBookCoverLoader? loadGuestBookCover;

  @override
  State<CoverImage> createState() => _PrivateBookCoverState();
}

class _PrivateBookCoverState extends State<CoverImage> {
  Future<Uint8List?>? _coverFuture;
  LocalCoverImageProvider? _localCoverProvider;
  String? _loadKey;

  @override
  void initState() {
    super.initState();
    _configureInjectedLoader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInjectedLoaderForCurrentSource) {
      _configureProviderLoader(subscribe: true);
    }
  }

  @override
  void didUpdateWidget(covariant CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.mediaId != widget.mediaId ||
        oldWidget.bookId != widget.bookId ||
        !identical(oldWidget.loadPrivateCover, widget.loadPrivateCover) ||
        !identical(oldWidget.loadLocalBookCover, widget.loadLocalBookCover) ||
        !identical(oldWidget.loadPendingBookCover, widget.loadPendingBookCover) ||
        !identical(oldWidget.loadGuestBookCover, widget.loadGuestBookCover)) {
      _coverFuture = null;
      _localCoverProvider = null;
      _loadKey = null;
      _configureInjectedLoader();
      if (!_hasInjectedLoaderForCurrentSource) {
        _configureProviderLoader();
      }
    }
  }

  void _configureInjectedLoader() {
    if (_hasPublicUrl) return;

    final mediaId = _usableMediaId;
    if (mediaId != null) {
      final loader = widget.loadPrivateCover;
      if (loader == null) return;
      final key = 'injected-media:$mediaId';
      if (_loadKey == key) return;
      _loadKey = key;
      _coverFuture = loader(mediaId);
      return;
    }

    final bookId = _usableBookId;
    final loader = widget.loadLocalBookCover;
    if (bookId == null || loader == null) return;
    final key = 'injected-local:$bookId';
    if (_loadKey == key) return;
    _loadKey = key;
    _coverFuture = loader(bookId);
  }

  void _configureProviderLoader({bool subscribe = false}) {
    try {
      final authProvider = subscribe ? context.watch<AuthProvider>() : context.read<AuthProvider>();
      final user = authProvider.user;
      final needsAccountScope =
          user != null && !authProvider.isOfflineMode && (_usableMediaId == null || authProvider.isSignedIn);
      final syncSettings = needsAccountScope
          ? (subscribe ? context.watch<SyncSettingsProvider>() : context.read<SyncSettingsProvider>())
          : null;
      _configureProviderLoaderFromContext(authProvider, syncSettings);
    } on ProviderNotFoundException {
      // Standalone cover surfaces can still render their placeholder.
    }
  }

  void _configureProviderLoaderFromContext(AuthProvider authProvider, SyncSettingsProvider? syncSettings) {
    if (_hasPublicUrl) return;

    final mediaId = _usableMediaId;
    final user = authProvider.user;
    if (mediaId != null) {
      if (!authProvider.isSignedIn || authProvider.isOfflineMode || user == null) {
        _clearProviderLoader();
        return;
      }

      if (syncSettings == null) {
        _clearProviderLoader();
        return;
      }
      final scope = MediaStorageScope(profileKey: syncSettings.activeProfileKey, userId: user.userId);
      final bookId = _usableBookId;
      if (bookId != null) {
        final key = '${scope.persistenceKey}:${CoverStorageBucket.pending.name}:$bookId';
        if (_loadKey == key) return;

        final importService = context.read<BookImportService>();
        final cacheService = context.read<MediaCacheService>();
        final pendingLoader = widget.loadPendingBookCover ?? importService.getPendingCoverFile;
        _loadKey = key;
        _coverFuture = null;
        _localCoverProvider = LocalCoverImageProvider(
          scopeKey: scope.persistenceKey,
          bucket: CoverStorageBucket.pending,
          fileId: bookId,
          loadBytes: () async {
            final pending = await pendingLoader(scope, bookId);
            if (pending != null && pending.isNotEmpty) return pending;
            return cacheService.ensureCoverCached(
              scope: scope,
              mediaId: mediaId,
              readLocalCover: importService.getCoverFile,
              writeLocalCover: importService.storeCoverFile,
              downloadMedia: authProvider.downloadMedia,
            );
          },
        );
        return;
      }

      final key = '${scope.persistenceKey}:${CoverStorageBucket.cached.name}:$mediaId';
      if (_loadKey == key) return;

      final importService = context.read<BookImportService>();
      final cacheService = context.read<MediaCacheService>();
      _loadKey = key;
      _coverFuture = null;
      _localCoverProvider = LocalCoverImageProvider(
        scopeKey: scope.persistenceKey,
        bucket: CoverStorageBucket.cached,
        fileId: mediaId,
        loadBytes: () => cacheService.ensureCoverCached(
          scope: scope,
          mediaId: mediaId,
          readLocalCover: importService.getCoverFile,
          writeLocalCover: importService.storeCoverFile,
          downloadMedia: authProvider.downloadMedia,
        ),
      );
      return;
    }

    final bookId = _usableBookId;
    if (bookId == null) return;

    if (!authProvider.isOfflineMode && user != null) {
      if (syncSettings == null) {
        _clearProviderLoader();
        return;
      }
      final scope = MediaStorageScope(profileKey: syncSettings.activeProfileKey, userId: user.userId);
      final key = '${scope.persistenceKey}:${CoverStorageBucket.pending.name}:$bookId';
      if (_loadKey == key) return;
      _loadKey = key;
      final loader = widget.loadPendingBookCover ?? context.read<BookImportService>().getPendingCoverFile;
      _coverFuture = null;
      _localCoverProvider = LocalCoverImageProvider(
        scopeKey: scope.persistenceKey,
        bucket: CoverStorageBucket.pending,
        fileId: bookId,
        loadBytes: () => loader(scope, bookId),
      );
      return;
    }

    final guestScopeKey = MediaStorageScope.localGuest.persistenceKey;
    final key = '$guestScopeKey:${CoverStorageBucket.guestBooks.name}:$bookId';
    if (_loadKey == key) return;
    _loadKey = key;
    final loader = widget.loadGuestBookCover ?? context.read<BookImportService>().getGuestCoverFile;
    _coverFuture = null;
    _localCoverProvider = LocalCoverImageProvider(
      scopeKey: guestScopeKey,
      bucket: CoverStorageBucket.guestBooks,
      fileId: bookId,
      loadBytes: () => loader(bookId),
    );
  }

  void _clearProviderLoader() {
    _loadKey = null;
    _coverFuture = null;
    _localCoverProvider = null;
  }

  bool get _hasPublicUrl => widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
  bool get _hasInlineDataUri => widget.imageUrl?.startsWith('data:') ?? false;
  String? get _usableMediaId => widget.mediaId == null || widget.mediaId!.isEmpty ? null : widget.mediaId;
  String? get _usableBookId => widget.bookId == null || widget.bookId!.isEmpty ? null : widget.bookId;

  bool get _hasInjectedLoaderForCurrentSource {
    if (_hasPublicUrl) return true;
    if (_usableMediaId != null) return widget.loadPrivateCover != null;
    if (_usableBookId != null) return widget.loadLocalBookCover != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInjectedLoaderForCurrentSource) {
      _configureProviderLoader(subscribe: true);
    }

    if (_hasInlineDataUri) {
      try {
        final data = Uri.parse(widget.imageUrl!).data;
        if (data != null && data.mimeType.startsWith('image/')) {
          final bytes = data.contentAsBytes();
          return Image.memory(bytes, fit: widget.fit, errorBuilder: (_, _, _) => widget.placeholder);
        }
      } on FormatException {
        return widget.placeholder;
      }
      return widget.placeholder;
    }

    if (_hasPublicUrl) {
      return CachedNetworkImage(
        fadeInDuration: AppMotion.duration(context, const Duration(milliseconds: 500)),
        fadeOutDuration: AppMotion.duration(context, const Duration(milliseconds: 1000)),
        imageUrl: widget.imageUrl!,
        fit: widget.fit,
        placeholder: (_, _) => _buildLoadingPlaceholder(context),
        errorWidget: (_, _, _) => widget.placeholder,
      );
    }

    final localCoverProvider = _localCoverProvider;
    if (localCoverProvider != null) {
      return Image(
        image: localCoverProvider,
        fit: widget.fit,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _buildLoadingPlaceholder(context);
        },
        errorBuilder: (_, _, _) => widget.placeholder,
      );
    }

    final coverFuture = _coverFuture;
    if (coverFuture == null) return widget.placeholder;

    return FutureBuilder<Uint8List?>(
      future: coverFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingPlaceholder(context);
        }
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(bytes, fit: widget.fit, errorBuilder: (_, _, _) => widget.placeholder);
        }
        if (snapshot.hasError) return widget.placeholder;
        return widget.placeholder;
      },
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Loading book cover',
      child: Container(
        key: const Key('cover-image-loading'),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 72 || constraints.maxHeight < 96;
            final icon = Icon(
              Icons.auto_stories_rounded,
              size: compact ? 22 : 36,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            );
            if (compact) return Center(child: icon);

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(height: 8),
                  Text(
                    'Loading…',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
