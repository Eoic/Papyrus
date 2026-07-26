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
  final List<AcquisitionEndpointKind> endpointKinds;
  final List<AcquisitionEndpointKind> indexerKinds;
  final List<AcquisitionEndpointKind> downloadClientKinds;
  final List<AcquisitionEndpointKind> arrKinds;
  final Map<AcquisitionEndpointKind, List<String>> arrCommands;

  const AcquisitionCapabilities({
    required this.enabled,
    required this.endpointKinds,
    required this.indexerKinds,
    required this.downloadClientKinds,
    required this.arrKinds,
    required this.arrCommands,
  });

  factory AcquisitionCapabilities.fromJson(Map<String, dynamic> json) {
    return AcquisitionCapabilities(
      enabled: json['enabled'] as bool? ?? true,
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
  final bool enabled;

  const AcquisitionEndpoint({
    required this.id,
    required this.name,
    required this.kind,
    required this.baseUrl,
    required this.enabled,
  });

  factory AcquisitionEndpoint.fromJson(Map<String, dynamic> json) => AcquisitionEndpoint(
    id: json['endpoint_id'] as String,
    name: json['name'] as String,
    kind: AcquisitionEndpointKind.values.byName(json['kind'] as String),
    baseUrl: Uri.parse(json['base_url'] as String),
    enabled: json['enabled'] as bool,
  );
}

class TorrentRelease {
  final String title;
  final String downloadUrl;
  final String protocol;
  final String indexer;
  final int? seeders;
  final int? sizeBytes;

  const TorrentRelease({
    required this.title,
    required this.downloadUrl,
    required this.protocol,
    required this.indexer,
    this.seeders,
    this.sizeBytes,
  });

  bool get isMagnet => downloadUrl.startsWith('magnet:');

  factory TorrentRelease.fromJson(Map<String, dynamic> json) => TorrentRelease(
    title: json['title'] as String,
    downloadUrl: json['download_url'] as String,
    protocol: json['protocol'] as String,
    indexer: json['indexer'] as String,
    seeders: json['seeders'] as int?,
    sizeBytes: json['size_bytes'] as int?,
  );
}

class AcquisitionJob {
  final String id;
  final String? endpointId;
  final String? ruleId;
  final String title;
  final String downloadUrl;
  final String status;
  final String? clientReference;
  final String? error;
  final DateTime? createdAt;

  const AcquisitionJob({
    required this.id,
    required this.endpointId,
    required this.ruleId,
    required this.title,
    required this.downloadUrl,
    required this.status,
    required this.clientReference,
    required this.error,
    required this.createdAt,
  });

  bool get isSubmitted => status == 'submitted';

  factory AcquisitionJob.fromJson(Map<String, dynamic> json) => AcquisitionJob(
    id: json['job_id'] as String,
    endpointId: json['endpoint_id'] as String?,
    ruleId: json['rule_id'] as String?,
    title: json['title'] as String,
    downloadUrl: json['download_url'] as String,
    status: json['status'] as String,
    clientReference: json['client_reference'] as String?,
    error: json['error'] as String?,
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );
}
