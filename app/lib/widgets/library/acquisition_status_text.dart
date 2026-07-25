import 'package:papyrus/acquisition/acquisition_models.dart';

String acquisitionStatusLabel(AcquisitionJob job) => switch (job.status) {
  AcquisitionJobStatus.queued || AcquisitionJobStatus.submitted => 'Queued',
  AcquisitionJobStatus.downloading =>
    job.progress == null ? 'Downloading' : 'Downloading ${(job.progress! * 100).round()}%',
  AcquisitionJobStatus.needsFileSelection => 'Needs attention',
  AcquisitionJobStatus.importing => 'Adding to library',
  AcquisitionJobStatus.completed => 'Finishing import',
  AcquisitionJobStatus.failed => 'Download failed',
  AcquisitionJobStatus.cancelled => 'Cancelled',
  AcquisitionJobStatus.unknown => 'Needs attention',
};

String formatBytes(int? bytes) {
  if (bytes == null) {
    return '—';
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value.abs() >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }

  final precision = value.abs() >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
}

String formatSpeed(int bytesPerSecond) {
  return '${formatBytes(bytesPerSecond)}/s';
}

String formatEta(int seconds) {
  final safeSeconds = seconds < 0 ? 0 : seconds;

  if (safeSeconds < 60) {
    return '$safeSeconds sec remaining';
  }

  if (safeSeconds < 3600) {
    return '${(safeSeconds / 60).round()} min remaining';
  }

  if (safeSeconds < 86400) {
    return '${(safeSeconds / 3600).round()} hr remaining';
  }

  final days = (safeSeconds / 86400).round();
  return '$days ${days == 1 ? 'day' : 'days'} remaining';
}

String? acquisitionTransferDetails(AcquisitionJob job) {
  final details = <String>[
    if (job.downloadSpeedBytesPerSecond case final speed?) formatSpeed(speed),
    if (job.etaSeconds case final eta?) formatEta(eta),
  ];

  return details.isEmpty ? null : details.join(' · ');
}

String? acquisitionJobDetailsLabel(AcquisitionJob job) {
  final error = job.error?.trim();

  if (job.status == AcquisitionJobStatus.failed && error != null && error.isNotEmpty) {
    return error;
  }

  return acquisitionTransferDetails(job);
}
