enum AcquisitionEndpointKind {
  qbittorrent,
  transmission,
  deluge,
  prowlarr,
  torznab,
  readarr,
  sonarr,
  radarr,
  lidarr,
  whisparr;

  String get apiValue => name;

  String get label => switch (this) {
    AcquisitionEndpointKind.qbittorrent => 'qBittorrent',
    AcquisitionEndpointKind.transmission => 'Transmission',
    AcquisitionEndpointKind.deluge => 'Deluge',
    AcquisitionEndpointKind.prowlarr => 'Prowlarr',
    AcquisitionEndpointKind.torznab => 'Torznab',
    AcquisitionEndpointKind.readarr => 'Readarr',
    AcquisitionEndpointKind.sonarr => 'Sonarr',
    AcquisitionEndpointKind.radarr => 'Radarr',
    AcquisitionEndpointKind.lidarr => 'Lidarr',
    AcquisitionEndpointKind.whisparr => 'Whisparr',
  };

  bool get isDownloadClient => switch (this) {
    AcquisitionEndpointKind.qbittorrent ||
    AcquisitionEndpointKind.transmission ||
    AcquisitionEndpointKind.deluge => true,
    _ => false,
  };

  bool get isIndexer => switch (this) {
    AcquisitionEndpointKind.prowlarr || AcquisitionEndpointKind.torznab => true,
    _ => false,
  };

  bool get isArr => switch (this) {
    AcquisitionEndpointKind.readarr ||
    AcquisitionEndpointKind.sonarr ||
    AcquisitionEndpointKind.radarr ||
    AcquisitionEndpointKind.lidarr ||
    AcquisitionEndpointKind.whisparr => true,
    _ => false,
  };
}

class AcquisitionCapabilities {
  final bool enabled;
  final bool managedDownloadsReady;
  final List<AcquisitionEndpointKind> endpointKinds;
  final List<AcquisitionEndpointKind> indexerKinds;
  final List<AcquisitionEndpointKind> downloadClientKinds;
  final List<AcquisitionEndpointKind> arrKinds;
  final Map<AcquisitionEndpointKind, List<String>> arrCommands;

  const AcquisitionCapabilities({
    required this.enabled,
    this.managedDownloadsReady = true,
    required this.endpointKinds,
    required this.indexerKinds,
    required this.downloadClientKinds,
    required this.arrKinds,
    required this.arrCommands,
  });

  factory AcquisitionCapabilities.fromJson(Map<String, dynamic> json) {
    return AcquisitionCapabilities(
      enabled: json['enabled'] as bool? ?? true,
      managedDownloadsReady: json['managed_downloads_ready'] as bool? ?? false,
      endpointKinds: _kinds(json['endpoint_kinds']),
      indexerKinds: _kinds(json['indexer_kinds']),
      downloadClientKinds: _kinds(json['download_client_kinds']),
      arrKinds: _kinds(json['arr_kinds']),
      arrCommands: ((json['arr_commands'] as Map<String, dynamic>?) ?? {}).map(
        (key, value) => MapEntry(AcquisitionEndpointKind.values.byName(key), (value as List<dynamic>).cast<String>()),
      ),
    );
  }

  static List<AcquisitionEndpointKind> _kinds(Object? value) {
    return ((value as List<dynamic>?) ?? []).cast<String>().map(AcquisitionEndpointKind.values.byName).toList();
  }
}

class AcquisitionEndpoint {
  final String id;
  final String name;
  final AcquisitionEndpointKind kind;
  final Uri baseUrl;
  final String? downloadRoot;
  final bool enabled;

  const AcquisitionEndpoint({
    required this.id,
    required this.name,
    required this.kind,
    required this.baseUrl,
    this.downloadRoot,
    required this.enabled,
  });

  factory AcquisitionEndpoint.fromJson(Map<String, dynamic> json) {
    return AcquisitionEndpoint(
      id: json['endpoint_id'] as String,
      name: json['name'] as String,
      kind: AcquisitionEndpointKind.values.byName(json['kind'] as String),
      baseUrl: Uri.parse(json['base_url'] as String),
      downloadRoot: json['download_root'] as String?,
      enabled: json['enabled'] as bool,
    );
  }
}

class TorrentRelease {
  final String title;
  final String releaseToken;
  final String protocol;
  final String indexer;
  final int? seeders;
  final int? sizeBytes;
  final DateTime? publishDate;
  final List<String> formatHints;

  const TorrentRelease({
    required this.title,
    required this.releaseToken,
    required this.protocol,
    required this.indexer,
    this.seeders,
    this.sizeBytes,
    this.publishDate,
    this.formatHints = const [],
  });

  String get downloadUrl => releaseToken;

  bool get isMagnet => protocol == 'torrent';

  factory TorrentRelease.fromJson(Map<String, dynamic> json) {
    return TorrentRelease(
      title: json['title'] as String,
      releaseToken: json['release_token'] as String,
      protocol: json['protocol'] as String,
      indexer: json['indexer'] as String,
      seeders: (json['seeders'] as num?)?.toInt(),
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      publishDate: _dateTime(json['publish_date']),
      formatHints: ((json['format_hints'] as List<dynamic>?) ?? []).cast<String>(),
    );
  }
}

enum AcquisitionJobStatus {
  queued('queued'),
  submitted('submitted'),
  downloading('downloading'),
  needsFileSelection('needs_file_selection'),
  importing('importing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled'),
  unknown('unknown');

  final String apiValue;

  const AcquisitionJobStatus(this.apiValue);

  factory AcquisitionJobStatus.fromApiValue(String value) {
    for (final status in values) {
      if (status.apiValue == value) {
        return status;
      }
    }

    return unknown;
  }
}

class AcquisitionJob {
  final String id;
  final String? endpointId;
  final String? ruleId;
  final String? bookId;
  final String title;
  final AcquisitionJobStatus status;
  final String? rawStatus;
  final String? clientReference;
  final String? clientHash;
  final String? clientState;
  final int? progressBasisPoints;
  final int? downloadedBytes;
  final int? totalBytes;
  final int? downloadSpeedBytesPerSecond;
  final int? etaSeconds;
  final String? selectedFilePath;
  final int retryCount;
  final String? error;
  final DateTime? nextPollAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const AcquisitionJob({
    required this.id,
    required this.endpointId,
    required this.ruleId,
    required this.bookId,
    required this.title,
    required this.status,
    this.rawStatus,
    required this.clientReference,
    required this.clientHash,
    required this.clientState,
    required this.progressBasisPoints,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.downloadSpeedBytesPerSecond,
    required this.etaSeconds,
    required this.selectedFilePath,
    required this.retryCount,
    required this.error,
    required this.nextPollAt,
    required this.createdAt,
    required this.updatedAt,
    required this.submittedAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
  });

  bool get isActive => switch (status) {
    AcquisitionJobStatus.queued ||
    AcquisitionJobStatus.submitted ||
    AcquisitionJobStatus.downloading ||
    AcquisitionJobStatus.importing ||
    AcquisitionJobStatus.unknown => true,
    _ => false,
  };

  bool get isSubmitted => status == AcquisitionJobStatus.submitted;

  bool get isTerminal => switch (status) {
    AcquisitionJobStatus.completed || AcquisitionJobStatus.failed || AcquisitionJobStatus.cancelled => true,
    _ => false,
  };

  bool get canCancel => switch (status) {
    AcquisitionJobStatus.queued ||
    AcquisitionJobStatus.submitted ||
    AcquisitionJobStatus.downloading ||
    AcquisitionJobStatus.needsFileSelection => true,
    _ => false,
  };

  bool get canRetryImport => status == AcquisitionJobStatus.failed && submittedAt != null;

  bool get requiresAttention {
    return status == AcquisitionJobStatus.needsFileSelection ||
        status == AcquisitionJobStatus.failed ||
        status == AcquisitionJobStatus.unknown;
  }

  double? get progress => progressBasisPoints == null ? null : progressBasisPoints! / 10000;

  factory AcquisitionJob.fromJson(Map<String, dynamic> json) {
    return AcquisitionJob(
      id: json['job_id'] as String,
      endpointId: json['endpoint_id'] as String?,
      ruleId: json['rule_id'] as String?,
      bookId: json['book_id'] as String?,
      title: json['title'] as String,
      status: AcquisitionJobStatus.fromApiValue(json['status'] as String),
      rawStatus: json['status'] as String,
      clientReference: json['client_reference'] as String?,
      clientHash: json['client_hash'] as String?,
      clientState: json['client_state'] as String?,
      progressBasisPoints: (json['progress_basis_points'] as num?)?.toInt(),
      downloadedBytes: (json['downloaded_bytes'] as num?)?.toInt(),
      totalBytes: (json['total_bytes'] as num?)?.toInt(),
      downloadSpeedBytesPerSecond: (json['download_speed_bytes_per_second'] as num?)?.toInt(),
      etaSeconds: (json['eta_seconds'] as num?)?.toInt(),
      selectedFilePath: json['selected_file_path'] as String?,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
      nextPollAt: _dateTime(json['next_poll_at']),
      createdAt: _dateTime(json['created_at']),
      updatedAt: _dateTime(json['updated_at']),
      submittedAt: _dateTime(json['submitted_at']),
      startedAt: _dateTime(json['started_at']),
      completedAt: _dateTime(json['completed_at']),
      cancelledAt: _dateTime(json['cancelled_at']),
    );
  }
}

class AcquisitionJobPage {
  final List<AcquisitionJob> items;
  final int total;
  final int limit;
  final int offset;

  const AcquisitionJobPage({required this.items, required this.total, required this.limit, required this.offset});

  factory AcquisitionJobPage.fromJson(Map<String, dynamic> json) {
    return AcquisitionJobPage(
      items: (json['items'] as List<dynamic>).cast<Map<String, dynamic>>().map(AcquisitionJob.fromJson).toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );
  }
}

class BatchSubmissionItem {
  final int index;
  final AcquisitionJob? job;
  final String? error;

  const BatchSubmissionItem({required this.index, required this.job, required this.error});

  factory BatchSubmissionItem.fromJson(Map<String, dynamic> json) {
    return BatchSubmissionItem(
      index: (json['index'] as num).toInt(),
      job: json['job'] == null ? null : AcquisitionJob.fromJson(json['job'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );
  }
}

class BatchSubmissionResponse {
  final List<BatchSubmissionItem> items;

  const BatchSubmissionResponse({required this.items});

  factory BatchSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return BatchSubmissionResponse(
      items: (json['items'] as List<dynamic>).cast<Map<String, dynamic>>().map(BatchSubmissionItem.fromJson).toList(),
    );
  }
}

class AcquisitionFileCandidate {
  final int index;
  final String name;
  final int sizeBytes;
  final int progressBasisPoints;
  final int priority;
  final bool supported;

  const AcquisitionFileCandidate({
    required this.index,
    required this.name,
    required this.sizeBytes,
    required this.progressBasisPoints,
    required this.priority,
    required this.supported,
  });

  double get progress => progressBasisPoints / 10000;

  factory AcquisitionFileCandidate.fromJson(Map<String, dynamic> json) {
    return AcquisitionFileCandidate(
      index: (json['index'] as num).toInt(),
      name: json['name'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      progressBasisPoints: (json['progress_basis_points'] as num).toInt(),
      priority: (json['priority'] as num).toInt(),
      supported: json['supported'] as bool,
    );
  }
}

DateTime? _dateTime(Object? value) {
  return value == null ? null : DateTime.parse(value as String);
}
