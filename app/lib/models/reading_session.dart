/// Reading session data model for tracking reading activity.
class ReadingSession {
  final String id;
  final String bookId;
  final DateTime startTime;
  final DateTime? endTime;
  final double startPosition; // 0.0 to 1.0
  final double? endPosition; // 0.0 to 1.0
  final int? pagesRead;
  final String? deviceType;
  final String? deviceName;
  final DateTime createdAt;

  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.startTime,
    this.endTime,
    required this.startPosition,
    this.endPosition,
    this.pagesRead,
    this.deviceType,
    this.deviceName,
    required this.createdAt,
  });

  /// Duration of the session in minutes.
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  /// Duration as a formatted string.
  String get durationLabel {
    final minutes = durationMinutes;
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }

  /// Progress made during this session.
  double get progressMade {
    if (endPosition == null) return 0;
    return (endPosition! - startPosition).clamp(0.0, 1.0);
  }

  /// Whether this session is still active (no end time).
  bool get isActive => endTime == null;

  /// Create a copy with updated fields.
  ReadingSession copyWith({
    String? id,
    String? bookId,
    DateTime? startTime,
    DateTime? endTime,
    double? startPosition,
    double? endPosition,
    int? pagesRead,
    String? deviceType,
    String? deviceName,
    DateTime? createdAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      pagesRead: pagesRead ?? this.pagesRead,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_position': startPosition,
      'end_position': endPosition,
      'pages_read': pagesRead,
      'device_type': deviceType,
      'device_name': deviceName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      startPosition: (json['start_position'] as num).toDouble(),
      endPosition: json['end_position'] != null
          ? (json['end_position'] as num).toDouble()
          : null,
      pagesRead: json['pages_read'] as int?,
      deviceType: json['device_type'] as String?,
      deviceName: json['device_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
